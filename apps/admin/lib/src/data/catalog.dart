import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:fvi_core/fvi_core.dart';

/// A node of the content tree that can be opened: a department, a course or
/// a unit (a level), with what is under it.
class CatalogNode {
  CatalogNode(this.id, this.name, [List<CatalogNode>? children]) : children = children ?? [];

  final NodeId id;
  final String name;
  final List<CatalogNode> children;
}

/// The content tree the admin grants from (docs/REQUIREMENTS.md 2). The units
/// are the student app's levels, from the index tools/content_builder writes
/// (assets/content/index.json: ids and names only, no content); the
/// departments and courses above them are named here.
class Catalog {
  Catalog(this.roots) {
    void index(CatalogNode n) {
      _byId[n.id] = n;
      n.children.forEach(index);
    }

    roots.forEach(index);
  }

  /// The names of the departments and courses, as the institute calls them.
  static const _names = {
    'languages': 'اللغات',
    'languages/english': 'اللغة الإنجليزية',
    'computer': 'الحاسوب',
    'tutoring': 'التقوية',
  };

  final List<CatalogNode> roots;
  final _byId = <NodeId, CatalogNode>{};

  static Future<Catalog> load([AssetBundle? bundle]) async {
    final index = jsonDecode(await (bundle ?? rootBundle).loadString('assets/content/index.json')) as List;
    final roots = <CatalogNode>[];
    CatalogNode at(List<CatalogNode> list, NodeId id) => list.firstWhere((n) => n.id == id, orElse: () {
          final node = CatalogNode(id, _names[id.value] ?? id.segments.last);
          list.add(node);
          return node;
        });
    for (final level in index.cast<Map<String, Object?>>()) {
      final id = NodeId(level['id'] as String);
      final lineage = id.lineage;
      var list = roots;
      for (final step in lineage.take(lineage.length - 1)) {
        list = at(list, step).children;
      }
      list.add(CatalogNode(id, level['name'] as String));
    }
    return Catalog(roots);
  }

  CatalogNode? operator [](NodeId id) => _byId[id];

  /// "الإنجليزية · Starter": the course and the unit, or the node's own name.
  String label(NodeId id) {
    final node = _byId[id];
    if (node == null) return id.value;
    if (id.depth < 3) return node.name;
    final course = _byId[id.lineage[1]]?.name.replaceFirst('اللغة ', '');
    return course == null ? node.name : '$course · ${node.name}';
  }
}
