/// Identifies a grantable node in the content tree:
/// `department`, `department/course` or `department/course/unit`.
///
/// Content keys are derived from these strings, so an ID must never change
/// after a build has been given to students.
class NodeId implements Comparable<NodeId> {
  factory NodeId(String value) {
    final segments = value.split('/');
    if (segments.isEmpty || segments.length > maxDepth) {
      throw FormatException('node id must have 1 to $maxDepth segments', value);
    }
    if (value.length > maxLength) {
      throw FormatException('node id is longer than $maxLength chars', value);
    }
    for (final segment in segments) {
      if (!_segment.hasMatch(segment)) {
        throw FormatException(
          'each segment must be lowercase letters, digits and single dashes',
          value,
        );
      }
    }
    return NodeId._(value, List.unmodifiable(segments));
  }

  const NodeId._(this.value, this.segments);

  /// Department, course, unit.
  static const maxDepth = 3;
  static const maxLength = 120;
  static final _segment = RegExp(r'^[a-z0-9]+(-[a-z0-9]+)*$');

  final String value;
  final List<String> segments;

  int get depth => segments.length;

  NodeId? get parent => depth == 1
      ? null
      : NodeId._(
          segments.take(depth - 1).join('/'),
          segments.sublist(0, depth - 1),
        );

  /// This node and every node above it, from the department down.
  List<NodeId> get lineage => [
    for (var d = 1; d <= depth; d++)
      NodeId._(segments.take(d).join('/'), segments.sublist(0, d)),
  ];

  bool isAncestorOrSelfOf(NodeId other) =>
      other.value == value || other.value.startsWith('$value/');

  @override
  bool operator ==(Object other) => other is NodeId && other.value == value;

  @override
  int get hashCode => value.hashCode;

  @override
  int compareTo(NodeId other) => value.compareTo(other.value);

  @override
  String toString() => value;
}
