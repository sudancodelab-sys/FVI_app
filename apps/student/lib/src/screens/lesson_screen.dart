import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../content/model.dart';
import '../theme.dart';
import 'exercise_screen.dart';
import 'lesson/sections.dart';

/// One lesson, read by scrolling, with its exercises at the bottom.
class LessonScreen extends StatefulWidget {
  const LessonScreen({super.key, required this.level, required this.index});

  final Level level;
  final int index;

  @override
  State<LessonScreen> createState() => _LessonScreenState();
}

class _LessonScreenState extends State<LessonScreen> {
  late List<Widget> _sections;
  late int _exercises;
  Locale? _locale;

  Lesson get lesson => widget.level.lessons[widget.index];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Built again when the app's language changes: the Arabic notes show only in Arabic.
    final locale = Localizations.localeOf(context);
    if (locale == _locale) return;
    _locale = locale;
    _sections = LessonSections(context, widget.level, lesson).build();
    _exercises = lesson.exercises.length;
  }

  void _open(int index) {
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
              child: _exercises == 0
                  ? const SizedBox.shrink()
                  : FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: Fvi.orange,
                        minimumSize: const Size.fromHeight(52),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        textStyle: const TextStyle(fontSize: 16.5, fontWeight: FontWeight.w700),
                      ),
                      onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(
                        builder: (_) => ExerciseScreen(lesson: lesson),
                      )),
                      icon: const Icon(Icons.edit_note_rounded),
                      label: Text(t.exercisesN(_exercises)),
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
