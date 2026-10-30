import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../l10n/app_localizations.dart';
import 'content/repository.dart';
import 'language.dart';
import 'screens/course_screen.dart';
import 'theme.dart';

class FviApp extends StatefulWidget {
  const FviApp({super.key, this.content, this.language});

  final ContentRepository? content;
  final AppLanguage? language;

  @override
  State<FviApp> createState() => _FviAppState();
}

class _FviAppState extends State<FviApp> {
  late final content = widget.content ?? ContentRepository();
  late final language = widget.language ?? (AppLanguage()..load());

  @override
  void dispose() {
    if (widget.language == null) language.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => LanguageScope(
        language: language,
        child: ListenableBuilder(
          listenable: language,
          builder: (context, _) => MaterialApp(
            onGenerateTitle: (context) => L10n.of(context).appTitle,
            debugShowCheckedModeBanner: false,
            theme: Fvi.theme(arabic: language.isArabic),
            locale: language.locale,
            supportedLocales: L10n.supportedLocales,
            localizationsDelegates: const [
              L10n.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            home: CourseScreen(content: content),
          ),
        ),
      );
}
