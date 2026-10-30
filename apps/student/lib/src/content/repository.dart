import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:fvi_core/fvi_core.dart';

import 'model.dart';

/// Reads the levels from the app's assets, as tools/content_builder wrote
/// them: `index.json` in the clear (the names, to show the course and its
/// locks), and each level encrypted with its own key (docs/REQUIREMENTS.md
/// 5.4). A level opens only with the key an activation code gave.
class ContentRepository {
  ContentRepository({AssetBundle? bundle}) : _bundle = bundle ?? rootBundle;

  final AssetBundle _bundle;
  final _levels = <String, Level>{};
  List<LevelSummary>? _index;

  Future<List<LevelSummary>> levels() async => _index ??= [
        for (final l in jsonDecode(await _bundle.loadString('assets/content/index.json')) as List)
          LevelSummary.fromJson(l as Json),
      ];

  /// The level, decrypted with [key]. Throws [ContentDecryptionException]
  /// if the key is not the level's.
  Future<Level> level(String slug, List<int> key) async {
    final cached = _levels[slug];
    if (cached != null) return cached;
    final path = '$slug.fvc';
    final blob = (await _bundle.load('assets/content/$path')).buffer.asUint8List();
    final plain = await ContentCipher.decrypt(key: key, path: path, blob: blob);
    return _levels[slug] = Level(jsonDecode(utf8.decode(plain)) as Json);
  }
}
