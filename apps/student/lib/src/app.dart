import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../l10n/app_localizations.dart';
import 'activation/activation.dart';
import 'content/repository.dart';
import 'language.dart';
import 'screens/gate.dart';
import 'theme.dart';

class FviApp extends StatefulWidget {
  const FviApp({super.key, this.content, this.language, this.activation});

  final ContentRepository? content;
  final AppLanguage? language;
  final Activation? activation;

  @override
  State<FviApp> createState() => _FviAppState();
}

class _FviAppState extends State<FviApp> {
  late final content = widget.content ?? ContentRepository();
  late final language = widget.language ?? (AppLanguage()..load());
  late final activation = widget.activation ?? (Activation()..load());

  @override
  void dispose() {
    if (widget.language == null) language.dispose();
    if (widget.activation == null) activation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => LanguageScope(
        language: language,
        child: ActivationScope(
          activation: activation,
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
              home: Gate(content: content),
            ),
          ),
        ),
      );
}
