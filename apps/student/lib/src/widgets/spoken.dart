import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../audio/speaker.dart';
import '../content/model.dart';
import '../theme.dart';

/// Collects, in reading order, every clip a lesson screen shows, so that
/// "Listen to the whole lesson" plays exactly what the student sees, in the
/// order they see it, and the screen can follow the clip being played.
class Playlist {
  final items = <Spoken>[];
  final keys = <String, GlobalKey>{};

  /// Adds clips shown together (a question and its answer) and returns the
  /// key of the widget that shows them.
  GlobalKey add(Spoken item, [Spoken? next]) {
    final key = GlobalKey();
    for (final i in [item, ?next]) {
      if (keys.containsKey(i.id)) throw StateError('clip ${i.id} is shown twice');
      items.add(i);
      keys[i.id] = key;
    }
    return key;
  }
}

/// A small round button that plays [items] (one clip, or a question and its
/// answer) and shows when they are playing.
class ListenButton extends StatelessWidget {
  const ListenButton(this.items, {super.key, this.color = Fvi.orange, this.size = 34});

  final List<Spoken> items;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    final speaker = SpeakerScope.of(context);
    final playing = items.any((i) => i.id == speaker.current);
    return SizedBox.square(
      dimension: size,
      child: IconButton(
        padding: EdgeInsets.zero,
        tooltip: L10n.of(context).play,
        style: IconButton.styleFrom(
          backgroundColor: playing ? color : color.withValues(alpha: .1),
          foregroundColor: playing ? Colors.white : color,
        ),
        iconSize: size * .55,
        icon: Icon(playing ? Icons.graphic_eq_rounded : Icons.volume_up_rounded),
        onPressed: () => playing ? speaker.stop() : speaker.playAll(items),
      ),
    );
  }
}

/// A text with its clip: the play button beside it, and a soft highlight
/// while it is playing.
class SpokenBlock extends StatelessWidget {
  const SpokenBlock({
    super.key,
    required this.items,
    required this.child,
    this.color = Fvi.orange,
    this.padding = const EdgeInsets.symmetric(vertical: 6),
  });

  final List<Spoken> items;
  final Widget child;
  final Color color;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final speaker = SpeakerScope.of(context);
    final playing = items.any((i) => i.id == speaker.current);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: padding,
      decoration: BoxDecoration(
        color: playing ? color.withValues(alpha: .09) : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: child),
          const SizedBox(width: 8),
          ListenButton(items, color: color),
        ],
      ),
    );
  }
}
