import 'package:flutter/material.dart';
import 'package:fvi_core/fvi_core.dart' show instituteDate;
import 'package:intl/intl.dart' show DateFormat;

import '../../l10n/app_localizations.dart';
import '../activation/activation.dart';
import '../content/model.dart';
import '../content/repository.dart';
import '../language.dart';
import '../theme.dart';
import 'level_screen.dart';
import 'onboarding/request.dart';

/// The English course: its ten levels, each with its CEFR circle and its
/// lock until it is activated, and the button that changes the app's language.

String _day(BuildContext context, DateTime date) =>
    DateFormat.yMMMd(Localizations.localeOf(context).toLanguageTag()).format(date);
class CourseScreen extends StatelessWidget {
  const CourseScreen({super.key, required this.content});

  final ContentRepository content;

  @override
  Widget build(BuildContext context) {
    final t = L10n.of(context);
    final language = AppLanguage.of(context);
    return Scaffold(
      appBar: AppBar(
        actions: [
          Padding(
            padding: const EdgeInsetsDirectional.only(end: 8),
            child: Tooltip(
              message: t.appLanguage,
              child: TextButton.icon(
                style: TextButton.styleFrom(foregroundColor: Colors.white),
                onPressed: () => language.choose(language.isArabic ? AppLanguage.english : AppLanguage.arabic),
                icon: const Icon(Icons.translate_rounded, size: 20),
                // The other language, in its own script.
                label: Text(t.otherLanguage, style: TextStyle(
                    fontFamily: language.isArabic ? Fvi.english : Fvi.arabic, fontWeight: FontWeight.w700)),
              ),
            ),
          ),
        ],
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
          final activation = ActivationScope.of(context);
          final ending = [
            for (final l in snap.data!)
              if (activation.endsSoon(l.id) case final day?) (l, day),
          ];
          return ListView(padding: const EdgeInsets.all(16), children: [
            // "Your access ends in a few days" (docs/REQUIREMENTS.md 3.3).
            for (final (level, day) in ending) _Ending(level: level, day: day),
            for (final l in snap.data!) ...[
              _LevelCard(level: l, content: content),
              const SizedBox(height: 10),
            ],
          ]);
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
    final activation = ActivationScope.of(context);
    final until = activation.openUntil(level.id);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () async {
          final key = await activation.keyFor(level.id);
          if (!context.mounted) return;
          if (key == null) {
            await showModalBottomSheet<void>(
                context: context, isScrollControlled: true, builder: (_) => _Locked(level: level));
            return;
          }
          final full = await content.level(level.slug, key);
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
                if (until != null)
                  Text(t.openUntil(_day(context, instituteDate(until))),
                      style: const TextStyle(fontSize: 12.5, color: Fvi.green, fontWeight: FontWeight.w600)),
              ]),
            ),
            until == null
                ? const Icon(Icons.lock_rounded, color: Fvi.muted)
                : const Icon(Icons.chevron_right_rounded, color: Fvi.muted),
          ]),
        ),
      ),
    );
  }
}

/// A level ends soon: its day, and the button to renew it.
class _Ending extends StatelessWidget {
  const _Ending({required this.level, required this.day});

  final LevelSummary level;
  final DateTime day;

  @override
  Widget build(BuildContext context) {
    final t = L10n.of(context);
    final asked = ActivationScope.of(context).profile != null;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Fvi.amberSoft, borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFF1DDA8))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text(t.endsOn(level.name, _day(context, day)),
            style: const TextStyle(fontWeight: FontWeight.w700, color: Fvi.text)),
        if (asked) ...[
          const SizedBox(height: 10),
          FilledButton.icon(
            style: primaryButton(const Color(0xFF1FA855)).copyWith(minimumSize: const WidgetStatePropertyAll(Size.fromHeight(44))),
            onPressed: () => sendRequest(context, levelId: level.id, levelName: level.name),
            icon: const Icon(Icons.chat_rounded),
            label: Text(t.renewOnWhatsapp),
          ),
        ],
      ]),
    );
  }
}

/// A locked (or ended) level: ask for it on WhatsApp, or enter its code.
class _Locked extends StatelessWidget {
  const _Locked({required this.level});

  final LevelSummary level;

  @override
  Widget build(BuildContext context) {
    final t = L10n.of(context);
    final activation = ActivationScope.of(context);
    final ended = activation.expired(level.id);
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.lock_rounded, color: Fvi.orange, size: 40),
          const SizedBox(height: 8),
          Text(ended ? t.expiredTitle : t.lockedTitle, textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: Fvi.text)),
          const SizedBox(height: 6),
          Text(ended ? t.expiredText(level.name) : t.lockedText(level.name), textAlign: TextAlign.center,
              style: const TextStyle(color: Fvi.muted, height: 1.5)),
          if (activation.profile != null) ...[
            const SizedBox(height: 16),
            FilledButton.icon(
              style: primaryButton(const Color(0xFF1FA855)),
              onPressed: () => sendRequest(context, levelId: level.id, levelName: level.name),
              icon: const Icon(Icons.chat_rounded),
              label: Text(ended ? t.renewOnWhatsapp : t.requestOnWhatsapp),
            ),
          ],
          const SizedBox(height: 20),
          Text(t.enterCode, style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          CodeEntry(onActivated: () => Navigator.of(context).pop()),
        ]),
      ),
    );
  }
}
