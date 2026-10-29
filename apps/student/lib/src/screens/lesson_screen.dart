import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../audio/speaker.dart';
import '../content/model.dart';
import '../theme.dart';
import '../widgets/spoken.dart';
import 'lesson/sections.dart';

/// One lesson, read by scrolling, with a play button beside every text and
/// "Listen to the whole lesson" at the bottom.
class LessonScreen extends StatefulWidget {
  const LessonScreen({super.key, required this.level, required this.index});

  final Level level;
  final int index;

  @override
  State<LessonScreen> createState() => _LessonScreenState();
}

class _LessonScreenState extends State<LessonScreen> {
  late Speaker _speaker;
  late Playlist _playlist;
  late List<Widget> _sections;
  final _scroll = ScrollController();
  String? _followed;
  var _built = false;

  Lesson get lesson => widget.level.lessons[widget.index];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_built) return;
    _built = true;
    _speaker = SpeakerScope.read(context)
      ..addListener(_follow)
      ..onMissing = _missing;
    _playlist = Playlist();
    _sections = LessonSections(context, widget.level, lesson, _playlist).build();
  }

  @override
  void dispose() {
    _speaker
      ..removeListener(_follow)
      ..onMissing = null
      ..stop();
    _scroll.dispose();
    super.dispose();
  }

  /// While the whole lesson plays, keep the text being read in view.
  void _follow() {
    final current = _speaker.current;
    if (!_speaker.playingAll || current == null || current == _followed) return;
    _followed = current;
    final target = _playlist.keys[current]?.currentContext;
    if (target != null) {
      Scrollable.ensureVisible(target, alignment: .25, duration: const Duration(milliseconds: 350),
          curve: Curves.easeOut);
    }
  }

  void _missing(Spoken item) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(L10n.of(context).audioMissing)));
  }

  void _open(int index) {
    _speaker.stop();
    Navigator.of(context).pushReplacement(MaterialPageRoute<void>(
      builder: (_) => LessonScreen(level: widget.level, index: index),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final t = L10n.of(context);
    final unit = lesson.unit;
    return Scaffold(
      backgroundColor: Fvi.surface,
      appBar: AppBar(
        titleSpacing: 0,
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(t.lessonNofM(lesson.position, lesson.count),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Fvi.navy)),
          Text(unit == null ? widget.level.name : '${widget.level.name} · ${t.unitN(unit)}',
              style: const TextStyle(fontSize: 13, color: Fvi.muted)),
        ]),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(3),
          child: LinearProgressIndicator(
            value: lesson.position / lesson.count,
            minHeight: 3,
            color: Fvi.orange,
            backgroundColor: Fvi.line,
          ),
        ),
      ),
      // English lessons read left to right, inside the Arabic interface too.
      body: Directionality(
        textDirection: TextDirection.ltr,
        child: ListView(
          controller: _scroll,
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 32),
          children: _sections,
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
          decoration: const BoxDecoration(border: Border(top: BorderSide(color: Fvi.line))),
          child: Row(children: [
            IconButton.filledTonal(
              tooltip: t.previousLesson,
              onPressed: widget.index > 0 ? () => _open(widget.index - 1) : null,
              icon: const Icon(Icons.arrow_back_rounded),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ListenableBuilder(
                listenable: _speaker,
                builder: (context, _) {
                  final playing = _speaker.playingAll;
                  return FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: playing ? Fvi.navy : Fvi.orange,
                      minimumSize: const Size.fromHeight(52),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      textStyle: const TextStyle(fontFamily: Fvi.arabic, fontSize: 16.5, fontWeight: FontWeight.w700),
                    ),
                    onPressed: () => playing ? _speaker.stop() : _speaker.playAll(_playlist.items),
                    icon: Icon(playing ? Icons.stop_rounded : Icons.headphones_rounded),
                    label: Text(playing ? t.stopListening : t.listenAll),
                  );
                },
              ),
            ),
            const SizedBox(width: 10),
            IconButton.filledTonal(
              tooltip: t.nextLesson,
              onPressed: widget.index + 1 < widget.level.lessons.length ? () => _open(widget.index + 1) : null,
              icon: const Icon(Icons.arrow_forward_rounded),
            ),
          ]),
        ),
      ),
    );
  }
}
