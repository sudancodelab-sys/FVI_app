import 'dart:typed_data';

import 'activation_code.dart';
import 'keys.dart';
import 'node_id.dart';

/// Everything the student's device has been granted, merged across all the
/// codes it received. Codes add up: a later code never removes access, and a
/// renewal of the same node extends its expiry.
class GrantBook {
  GrantBook([Iterable<UnlockedGrant> grants = const []]) {
    addAll(grants);
  }

  final Map<NodeId, UnlockedGrant> _byNode = {};

  /// One grant per node, sorted by node id.
  List<UnlockedGrant> get grants =>
      _byNode.values.toList()..sort((a, b) => a.node.compareTo(b.node));

  bool get isEmpty => _byNode.isEmpty;

  void addAll(Iterable<UnlockedGrant> grants) {
    for (final grant in grants) {
      final existing = _byNode[grant.node];
      if (existing == null || grant.expiresAt.isAfter(existing.expiresAt)) {
        _byNode[grant.node] = grant;
      }
    }
  }

  /// The grant that gives access to [node] at [now]: an unexpired grant on the
  /// node itself or on one of its ancestors. When several apply, the one that
  /// lasts longest wins.
  UnlockedGrant? activeGrantFor(NodeId node, DateTime now) {
    UnlockedGrant? best;
    for (final step in node.lineage) {
      final grant = _byNode[step];
      if (grant != null &&
          now.isBefore(grant.expiresAt) &&
          (best == null || grant.expiresAt.isAfter(best.expiresAt))) {
        best = grant;
      }
    }
    return best;
  }

  bool canOpen(NodeId node, DateTime now) => activeGrantFor(node, now) != null;

  /// Whether anything inside [node] is open — used to show a department or a
  /// course as active when only one of its units is granted.
  bool hasActiveWithin(NodeId node, DateTime now) => _byNode.values.any(
    (g) =>
        now.isBefore(g.expiresAt) &&
        (node.isAncestorOrSelfOf(g.node) || g.node.isAncestorOrSelfOf(node)),
  );

  /// Whether [node] was open at some point but is not any more, to tell
  /// "expired — renew" apart from "never activated".
  bool hasExpired(NodeId node, DateTime now) =>
      !canOpen(node, now) &&
      node.lineage.any((step) => _byNode.containsKey(step));

  /// The key that decrypts [node]'s content, or null if it is not open now.
  Future<Uint8List?> keyFor(NodeId node, DateTime now) async {
    final grant = activeGrantFor(node, now);
    if (grant == null) return null;
    return ContentKeys.descend(
      ancestorKey: grant.key,
      ancestor: grant.node,
      node: node,
    );
  }

  /// Active grants that end within [window] of [now], soonest first — for the
  /// "your access ends in N days" banner.
  List<UnlockedGrant> expiringWithin(Duration window, DateTime now) {
    final limit = now.add(window);
    return _byNode.values
        .where((g) => now.isBefore(g.expiresAt) && g.expiresAt.isBefore(limit))
        .toList()
      ..sort((a, b) => a.expiresAt.compareTo(b.expiresAt));
  }
}
