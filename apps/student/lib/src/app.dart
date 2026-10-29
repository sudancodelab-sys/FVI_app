import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../l10n/app_localizations.dart';
import 'audio/speaker.dart';
import 'content/repository.dart';
import 'screens/course_screen.dart';
import 'theme.dart';

class FviApp extends StatefulWidget {
  const FviApp({super.key, this.content, this.speaker});

  final ContentRepository? content;
  final Speaker? speaker;

  @override
  State<FviApp> createState() => _FviAppState();
}

class _FviAppState extends State<FviApp> {
  late final content = widget.content ?? ContentRepository();
  late final speaker = widget.speaker ?? Speaker();

  @override
  void dispose() {
    if (widget.speaker == null) speaker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SpeakerScope(
        speaker: speaker,
        child: MaterialApp(
          onGenerateTitle: (context) => L10n.of(context).appTitle,
          debugShowCheckedModeBanner: false,
          theme: Fvi.theme(),
          locale: const Locale('ar'),
          supportedLocales: L10n.supportedLocales,
          localizationsDelegates: const [
            L10n.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: CourseScreen(content: content),
        ),
      );
}
