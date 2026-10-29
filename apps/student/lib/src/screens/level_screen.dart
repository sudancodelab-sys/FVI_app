import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../content/model.dart';
import '../theme.dart';
import 'lesson/icons.dart';
import 'lesson_screen.dart';

/// The lessons of one level, unit by unit (Starter: phonics, then speaking).
class LevelScreen extends StatelessWidget {
  const LevelScreen({super.key, required this.level});

  final Level level;

  @override
  Widget build(BuildContext context) {
    final t = L10n.of(context);
    final groups = <(String, List<int>)>[];
    if (level.isStarter) {
      final lessons = level.lessons;
      groups
        ..add((t.phonicsPart, [for (var i = 0; i < lessons.length; i++) if (lessons[i].kind != 'speaking') i]))
        ..add((t.speakingPart, [for (var i = 0; i < lessons.length; i++) if (lessons[i].kind == 'speaking') i]));
    } else {
      for (final u in level.units) {
        groups.add(('${t.unitN(u.number)} · ${u.title}',
            [for (var i = 0; i < level.lessons.length; i++) if (level.lessons[i].unit == u.number) i]));
      }
    }
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Fvi.navy,
        foregroundColor: Colors.white,
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(level.name, style: const TextStyle(fontFamily: Fvi.english, fontWeight: FontWeight.w800, fontSize: 19)),
          // The CEFR code is isolated so it keeps its order in Arabic text.
          Text('\u2066${level.cefr}\u2069 · ${t.lessonsCount(level.lessons.length)}',
              style: const TextStyle(fontSize: 13, color: Color(0xFFC9CEF2))),
        ]),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          for (final (title, indexes) in groups) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 12, 4, 8),
              child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Fvi.navy)),
            ),
            Card(
              child: Column(children: [
                for (final i in indexes) _LessonTile(level: level, index: i),
              ]),
            ),
          ],
        ],
      ),
    );
  }
}

class _LessonTile extends StatelessWidget {
  const _LessonTile({required this.level, required this.index});

  final Level level;
  final int index;

  @override
  Widget build(BuildContext context) {
    final lesson = level.lessons[index];
    final color = Fvi.kind(lesson.kind);
    final kind = switch (lesson.kind) {
      'phonics' || 'intro' => 'PHONICS',
      final k => k.toUpperCase(),
    };
    return ListTile(
      onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(
        builder: (_) => LessonScreen(level: level, index: index),
      )),
      leading: CircleAvatar(
        backgroundColor: color.withValues(alpha: .12),
        foregroundColor: color,
        child: Icon(lessonIcon(lesson.icon), size: 20),
      ),
      title: Text(lesson.title, textDirection: TextDirection.ltr,
          style: const TextStyle(fontFamily: Fvi.english, fontWeight: FontWeight.w600, fontSize: 15)),
      subtitle: Text('$kind · ${lesson.number}', textDirection: TextDirection.ltr,
          style: TextStyle(fontFamily: Fvi.english, fontSize: 11, letterSpacing: .8, color: color,
              fontWeight: FontWeight.w700)),
      trailing: const Icon(Icons.chevron_right_rounded, color: Fvi.muted),
    );
  }
}
