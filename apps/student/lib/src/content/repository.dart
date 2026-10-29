import 'dart:convert';

import 'package:flutter/services.dart';

import 'model.dart';

/// Reads the exported levels from the app's assets.
///
/// In this first version the files are plain JSON. The content builder
/// will encrypt each level with its own key (docs/REQUIREMENTS.md, 5.4),
/// and only this class will change.
class ContentRepository {
  ContentRepository({AssetBundle? bundle}) : _bundle = bundle ?? rootBundle;

  final AssetBundle _bundle;
  final _levels = <String, Level>{};
  List<LevelSummary>? _index;

  Future<List<LevelSummary>> levels() async => _index ??= [
        for (final l in jsonDecode(await _bundle.loadString('assets/content/index.json')) as List)
          LevelSummary.fromJson(l as Json),
      ];

  Future<Level> level(String slug) async =>
      _levels[slug] ??= Level(jsonDecode(await _bundle.loadString('assets/content/$slug.json')) as Json);
}
