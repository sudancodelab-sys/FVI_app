/// The content builder (docs/REQUIREMENTS.md 6.2), run from the repository root:
///
/// ```text
/// python3 curriculum/tools/export_app.py --out build/content
/// dart run content_builder build [--in build/content] [--out apps/student/assets/content] [--keys keys/dev]
/// ```
///
/// Development only, until the admin app exists:
///
/// ```text
/// dart run content_builder dev-keys               # makes keys/dev once
/// dart run content_builder issue --request FILE [--level SLUG ...] [--days 30]
/// ```
///
/// `issue` reads the student's WhatsApp message (or its FVI1-REQ token) and
/// prints an activation code made with the development keys, which only an
/// app built with them accepts. Without --level it opens every level.
library;

import 'dart:convert';
import 'dart:io';

import 'package:content_builder/content_builder.dart';
import 'package:fvi_core/fvi_core.dart';

Future<void> main(List<String> args) async {
  if (args.isEmpty) return _usage();
  final options = _options(args.skip(1).toList());
  String one(String name, String fallback) => options[name]?.last ?? fallback;
  final keysDir = Directory(one('keys', 'keys/dev'));
  switch (args.first) {
    case 'build':
      final built = await buildContent(
        input: Directory(one('in', 'build/content')),
        output: Directory(one('out', 'apps/student/assets/content')),
        rootKey: (await BuildKeys.load(keysDir)).rootKey,
      );
      for (final level in built) {
        stdout.writeln('${level.node}: ${levelPath(level.slug)}, ${level.bytes} bytes');
      }
    case 'dev-keys':
      final keys = await BuildKeys.create(keysDir);
      final issuer = await keys.issuer();
      stdout.writeln('Development keys made in ${keysDir.path}.');
      stdout.writeln('Issuer public key (for the student app): ${hexEncode(issuer.publicKey)}');
    case 'issue':
      final request = options['request']?.last;
      if (request == null) return _usage();
      final text = File(request).existsSync() ? await File(request).readAsString() : request;
      final index = jsonDecode(await File('${one('in', 'build/content')}/index.json').readAsString()) as List<Object?>;
      final levels = options['level'] ?? [for (final l in index.cast<Map<String, Object?>>()) l['slug'] as String];
      final ids = {for (final l in index.cast<Map<String, Object?>>()) l['slug']: l['id'] as String};
      final issued = await issueDevelopmentCode(
        keys: await BuildKeys.load(keysDir),
        requestText: text,
        nodes: [for (final slug in levels) NodeId(ids[slug] ?? (throw ArgumentError('no level $slug')))],
        days: int.parse(one('days', '30')),
        now: DateTime.now(),
        whatsappNumber: one('whatsapp', ''),
      );
      stdout.writeln(issued.token);
    default:
      _usage();
  }
}

/// `--name value` pairs; a name may repeat.
Map<String, List<String>> _options(List<String> args) {
  final out = <String, List<String>>{};
  for (var i = 0; i + 1 < args.length; i += 2) {
    if (!args[i].startsWith('--')) throw ArgumentError('expected --option, got ${args[i]}');
    (out[args[i].substring(2)] ??= []).add(args[i + 1]);
  }
  return out;
}

void _usage() {
  stderr.writeln('usage: content_builder build|dev-keys|issue [--option value ...] (see the top of this file)');
  exitCode = 64;
}
