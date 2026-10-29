import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:fvi_core/fvi_core.dart';
import 'package:test/test.dart';

void main() {
  final now = DateTime.utc(2026, 10, 29, 9);
  final rootKey = Uint8List.fromList(List.generate(32, (i) => i));
  final english1 = NodeId('languages/english/level-1');
  final languages = NodeId('languages');

  late IssuerKeyPair issuer;
  late DeviceKeyPair device;

  setUp(() async {
    issuer = await IssuerKeyPair.generate();
    device = await DeviceKeyPair.generate();
  });

  Future<IssuedActivation> issue({
    List<Grant>? grants,
    DeviceKeyPair? to,
    IssuerKeyPair? by,
    String whatsapp = '+249912000000',
  }) => ActivationCode.issue(
    issuer: by ?? issuer,
    rootKey: rootKey,
    devicePublicKey: (to ?? device).publicKey,
    grants: grants ?? [Grant(english1, now.add(const Duration(days: 30)))],
    now: now,
    whatsappNumber: whatsapp,
  );

  Future<OpenedActivation> open(String text, {DeviceKeyPair? on}) =>
      ActivationCode.open(
        text,
        issuerPublicKey: issuer.publicKey,
        device: on ?? device,
      );

  Matcher rejectedWith(ActivationFailure reason) => throwsA(
    isA<ActivationException>().having((e) => e.reason, 'reason', reason),
  );

  group('round trip', () {
    test('the device receives the grants and the right keys', () async {
      final expires = now.add(const Duration(days: 30));
      final issued = await issue(
        grants: [Grant(english1, expires), Grant(NodeId('computer'), expires)],
      );

      final opened = await open(issued.token);

      expect(opened.issuedAt, now);
      expect(opened.whatsappNumber, '+249912000000');
      expect(opened.codeId, issued.codeId);
      expect(opened.grants.map((g) => g.node.value), [
        'languages/english/level-1',
        'computer',
      ]);
      expect(opened.grants.first.expiresAt, expires);
      expect(
        opened.grants.first.key,
        await ContentKeys.forNode(rootKey, english1),
      );
      expect(
        opened.grants.last.key,
        await ContentKeys.forNode(rootKey, NodeId('computer')),
      );
    });

    test('the code is found inside a whole copied WhatsApp message', () async {
      final issued = await issue();
      final message =
          'كود تفعيل تطبيق FVI\n'
          'انسخ هذه الرسالة كاملة ثم افتح التطبيق.\n\n'
          '${issued.token}\n\nمعهد الرؤية المستقبلية';

      final opened = await open(message);

      expect(opened.grants.single.node, english1);
    });

    test('expiry is stored with whole-second precision', () async {
      final expires = now.add(const Duration(days: 1, milliseconds: 750));
      final opened = await open(
        (await issue(grants: [Grant(english1, expires)])).token,
      );
      expect(opened.grants.single.expiresAt, now.add(const Duration(days: 1)));
    });

    test('a code for many units stays short enough to paste', () async {
      final grants = [
        for (var i = 1; i <= 20; i++)
          Grant(
            NodeId('languages/english/level-$i'),
            now.add(const Duration(days: 60)),
          ),
      ];
      final issued = await issue(grants: grants);
      expect(issued.token.length, lessThan(2500));
      expect((await open(issued.token)).grants, hasLength(20));
    });
  });

  group('rejection', () {
    test('a code issued for another device', () async {
      final other = await DeviceKeyPair.generate();
      final issued = await issue(to: other);
      await expectLater(
        open(issued.token),
        rejectedWith(ActivationFailure.wrongDevice),
      );
    });

    test('a code from another issuer (e.g. a development build)', () async {
      final otherIssuer = await IssuerKeyPair.generate();
      final issued = await issue(by: otherIssuer);
      await expectLater(
        open(issued.token),
        rejectedWith(ActivationFailure.unknownIssuer),
      );
    });

    test('any altered byte of the body breaks the signature', () async {
      final issued = await issue();
      final parts = issued.token
          .substring(ActivationCode.prefix.length)
          .split('.');
      final body = base64Url.decode(base64Url.normalize(parts[0]));
      // Skip the version and issuer id so the failure is the signature, not
      // the format or issuer checks. Stop before the sealed part's length
      // field so parsing still succeeds.
      for (final index in [5, 21, 29, 33, 40, body.length - 1]) {
        final tampered = Uint8List.fromList(body)..[index] ^= 0x01;
        final token =
            '${ActivationCode.prefix}'
            '${base64Url.encode(tampered).replaceAll('=', '')}.${parts[1]}';
        await expectLater(
          open(token),
          throwsA(
            isA<ActivationException>().having(
              (e) => e.reason,
              'reason',
              anyOf(
                ActivationFailure.badSignature,
                ActivationFailure.malformed,
              ),
            ),
          ),
          reason: 'byte $index',
        );
      }
    });

    test('an extended expiry date is detected', () async {
      // Re-encode the header with a later expiry and keep the old signature.
      final issued = await issue();
      final parts = issued.token
          .substring(ActivationCode.prefix.length)
          .split('.');
      final body = base64Url.decode(base64Url.normalize(parts[0]));
      final nodeBytes = utf8.encode(english1.value);
      final expiryOffset = _indexOf(body, nodeBytes) + nodeBytes.length;
      final tampered = Uint8List.fromList(body)..[expiryOffset] += 1;
      final token =
          '${ActivationCode.prefix}'
          '${base64Url.encode(tampered).replaceAll('=', '')}.${parts[1]}';
      await expectLater(
        open(token),
        rejectedWith(ActivationFailure.badSignature),
      );
    });

    test('text without a code', () async {
      await expectLater(
        open('مرحباً، هذا ليس كوداً'),
        rejectedWith(ActivationFailure.malformed),
      );
    });

    test('a truncated code', () async {
      final issued = await issue();
      final cut = issued.token.substring(0, issued.token.length ~/ 2);
      await expectLater(
        open('$cut.AAAA'),
        rejectedWith(ActivationFailure.malformed),
      );
    });

    test('a forged signature', () async {
      final issued = await issue();
      final body = issued.token.split('.')[1];
      final fakeSignature = base64Url
          .encode(List.filled(64, 7))
          .replaceAll('=', '');
      await expectLater(
        open('${ActivationCode.prefix}$body.$fakeSignature'),
        rejectedWith(ActivationFailure.badSignature),
      );
    });
  });

  group('issuing rules', () {
    test('rejects an expired grant', () async {
      await expectLater(
        issue(grants: [Grant(english1, now.subtract(const Duration(days: 1)))]),
        throwsArgumentError,
      );
    });

    test('rejects duplicate nodes', () async {
      final expires = now.add(const Duration(days: 30));
      await expectLater(
        issue(grants: [Grant(languages, expires), Grant(languages, expires)]),
        throwsArgumentError,
      );
    });

    test('rejects an empty grant list', () async {
      await expectLater(issue(grants: []), throwsArgumentError);
    });

    test('rejects a low-order device key from a crafted request', () async {
      // An all-zero X25519 public key makes the shared secret all zeros.
      await expectLater(
        ActivationCode.issue(
          issuer: issuer,
          rootKey: rootKey,
          devicePublicKey: Uint8List(32),
          grants: [Grant(english1, now.add(const Duration(days: 1)))],
          now: now,
        ),
        throwsA(isA<FviFormatException>()),
      );
    });

    test('deterministic with an injected random source', () async {
      final fixedIssuer = await IssuerKeyPair.fromSeed(List.filled(32, 1));
      final fixedDevice = await DeviceKeyPair.fromPrivateKey(
        List.filled(32, 2),
      );
      Future<String> make() async => (await ActivationCode.issue(
        issuer: fixedIssuer,
        rootKey: rootKey,
        devicePublicKey: fixedDevice.publicKey,
        grants: [Grant(english1, now.add(const Duration(days: 30)))],
        now: now,
        random: Random(42),
      )).token;
      expect(await make(), await make());
    });
  });
}

int _indexOf(List<int> haystack, List<int> needle) {
  for (var i = 0; i <= haystack.length - needle.length; i++) {
    var match = true;
    for (var j = 0; j < needle.length; j++) {
      if (haystack[i + j] != needle[j]) {
        match = false;
        break;
      }
    }
    if (match) return i;
  }
  throw StateError('not found');
}
