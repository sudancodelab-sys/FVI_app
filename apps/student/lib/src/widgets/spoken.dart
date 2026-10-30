import 'package:flutter/material.dart';

/// A text of a lesson, with the room around it the books give it.
///
/// The texts once had a play button each; the institute chose a text-only
/// app with exercises instead (decision #44), so this is only the spacing.
class TextBlock extends StatelessWidget {
  const TextBlock({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.symmetric(vertical: 6),
  });

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) => Padding(padding: padding, child: child);
}
