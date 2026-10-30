/// Encrypts the levels exported by curriculum/tools/export_app.py for the
/// student app (docs/REQUIREMENTS.md 5.4), and, for development only, makes
/// test keys and activation codes until the admin app exists.
library;

import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:fvi_core/fvi_core.dart';

/// The keys a build uses: the content root key, and the issuer seed whose
/// public half the student app checks codes with. Each is a file of 64 hex
/// digits. Development keys are in the repository (keys/dev); production
/// keys never are.
class BuildKeys {
  BuildKeys(this.rootKey, this.issuerSeed);

  final Uint8List rootKey;
  final Uint8List issuerSeed;

  static const rootFile = 'content-root.hex';
  static const issuerFile = 'issuer-seed.hex';

  static Future<BuildKeys> load(Directory dir) async => BuildKeys(
        hexDecode(await File('${dir.path}/$rootFile').readAsString()),
        hexDecode(await File('${dir.path}/$issuerFile').readAsString()),
      );

  /// Makes a new pair of keys in [dir]; refuses to replace existing ones,
  /// since every build and code made with them would stop working.
  static Future<BuildKeys> create(Directory dir) async {
    for (final name in [rootFile, issuerFile]) {
      if (File('${dir.path}/$name').existsSync()) {
        throw StateError('${dir.path}/$name exists; keys are never replaced');
      }
    }
    await dir.create(recursive: true);
    final random = Random.secure();
    Uint8List fresh() => Uint8List.fromList([for (var i = 0; i < keyLength; i++) random.nextInt(256)]);
    final keys = BuildKeys(fresh(), fresh());
    await File('${dir.path}/$rootFile').writeAsString('${hexEncode(keys.rootKey)}\n');
    await File('${dir.path}/$issuerFile').writeAsString('${hexEncode(keys.issuerSeed)}\n');
    return keys;
  }

  Future<IssuerKeyPair> issuer() => IssuerKeyPair.fromSeed(issuerSeed);
}

/// What a build wrote: the levels and their sizes.
class BuiltLevel {
  BuiltLevel(this.slug, this.node, this.bytes);

  final String slug;
  final NodeId node;
  final int bytes;
}

/// Encrypts every level listed in [input]/index.json with its own key, into
/// [output]: `index.json` (names and lesson counts, to show the course with
/// its locks) and `<slug>.fvc` for each level. The plain level files are
/// never written to [output], and old ones there are removed.
Future<List<BuiltLevel>> buildContent({
  required Directory input,
  required Directory output,
  required List<int> rootKey,
}) async {
  final index = jsonDecode(await File('${input.path}/index.json').readAsString()) as List<Object?>;
  await output.create(recursive: true);
  final built = <BuiltLevel>[];
  for (final entry in index.cast<Map<String, Object?>>()) {
    final slug = entry['slug'] as String;
    final node = NodeId(entry['id'] as String);
    final plain = await File('${input.path}/$slug.json').readAsBytes();
    final blob = await ContentCipher.encrypt(
      key: await ContentKeys.forNode(rootKey, node),
      path: levelPath(slug),
      plain: plain,
    );
    await File('${output.path}/${levelPath(slug)}').writeAsBytes(blob);
    built.add(BuiltLevel(slug, node, blob.length));
  }
  await File('${output.path}/index.json').writeAsString(jsonEncode(index));
  final keep = {'index.json', ...built.map((b) => levelPath(b.slug))};
  for (final file in output.listSync().whereType<File>()) {
    if (!keep.contains(file.uri.pathSegments.last)) await file.delete();
  }
  return built;
}

/// Where a level's encrypted file is, in the app's content folder. It is
/// also the path bound into the file's encryption.
String levelPath(String slug) => '$slug.fvc';

/// Development only: a code for the device of [requestText] (the WhatsApp
/// message of the student app, or just its FVI1-REQ token), opening [nodes]
/// until the end of the institute's day [days] from [now].
Future<IssuedActivation> issueDevelopmentCode({
  required BuildKeys keys,
  required String requestText,
  required List<NodeId> nodes,
  required int days,
  required DateTime now,
  String whatsappNumber = '',
}) async {
  final request = ActivationRequest.findIn(requestText);
  if (request == null) throw const FormatException('no FVI1-REQ request in the text');
  final until = endOfInstituteDay(instituteDate(now).add(Duration(days: days)));
  return ActivationCode.issue(
    issuer: await keys.issuer(),
    rootKey: keys.rootKey,
    devicePublicKey: request.devicePublicKey,
    grants: [for (final node in nodes) Grant(node, until)],
    now: now,
    whatsappNumber: whatsappNumber,
  );
}

String hexEncode(List<int> bytes) => bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();

Uint8List hexDecode(String text) {
  final hex = text.trim();
  if (hex.length.isOdd || !RegExp(r'^[0-9a-fA-F]*$').hasMatch(hex)) {
    throw FormatException('not hex', hex);
  }
  return Uint8List.fromList([
    for (var i = 0; i < hex.length; i += 2) int.parse(hex.substring(i, i + 2), radix: 16),
  ]);
}
