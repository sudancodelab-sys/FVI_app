import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../content/model.dart';
import '../content/repository.dart';
import '../theme.dart';
import 'level_screen.dart';

/// The English course: its ten levels, each with its CEFR circle.
class CourseScreen extends StatelessWidget {
  const CourseScreen({super.key, required this.content});

  final ContentRepository content;

  @override
  Widget build(BuildContext context) {
    final t = L10n.of(context);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Fvi.navy,
        foregroundColor: Colors.white,
        toolbarHeight: 72,
        title: FutureBuilder(
          future: content.levels(),
          builder: (context, snap) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(t.courseEnglish, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 21)),
            Text(t.courseEnglishSub(snap.data?.length ?? 10),
                style: const TextStyle(fontSize: 13, color: Color(0xFFC9CEF2))),
          ]),
        ),
      ),
      body: FutureBuilder(
        future: content.levels(),
        builder: (context, snap) {
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: snap.data!.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, i) => _LevelCard(level: snap.data![i], content: content),
          );
        },
      ),
    );
  }
}

class _LevelCard extends StatelessWidget {
  const _LevelCard({required this.level, required this.content});

  final LevelSummary level;
  final ContentRepository content;

  @override
  Widget build(BuildContext context) {
    final t = L10n.of(context);
    final (color, stage) = switch (level.stage) {
      'Intermediate' => (Fvi.green, t.stageIntermediate),
      'Advanced' => (Fvi.navy, t.stageAdvanced),
      _ => (Fvi.orange, t.stagePreIntermediate),
    };
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () async {
          final full = await content.level(level.slug);
          if (!context.mounted) return;
          Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => LevelScreen(level: full)));
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(children: [
            Container(
              width: 58,
              height: 58,
              alignment: Alignment.center,
              decoration: BoxDecoration(shape: BoxShape.circle, color: color),
              child: Text(level.cefr, textDirection: TextDirection.ltr,
                  style: const TextStyle(fontFamily: Fvi.english, color: Colors.white, fontWeight: FontWeight.w800,
                      fontSize: 13)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(level.name, style: const TextStyle(fontFamily: Fvi.english, fontSize: 17,
                    fontWeight: FontWeight.w700, color: Fvi.navy)),
                Text('$stage · ${t.lessonsCount(level.lessonCount)}',
                    style: const TextStyle(fontSize: 13.5, color: Fvi.muted)),
              ]),
            ),
            const Icon(Icons.chevron_right_rounded, color: Fvi.muted),
          ]),
        ),
      ),
    );
  }
}
