import 'package:flutter/material.dart';

/// Colors of the approved screen designs (docs/design) and the books.
abstract final class Fvi {
  static const navy = Color(0xFF262E62);
  static const navyDark = Color(0xFF1A2048);
  static const navySoft = Color(0xFFE8EAF6);
  static const navyTint = Color(0xFFF2F3FA);
  static const orange = Color(0xFFE4451A);
  static const orangeSoft = Color(0xFFFDEDE7);
  static const green = Color(0xFF14935A);
  static const greenSoft = Color(0xFFE2F4EB);
  static const amber = Color(0xFFA86F06);
  static const amberSoft = Color(0xFFFFF3D6);
  static const teal = Color(0xFF0E7C86);
  static const violet = Color(0xFF5B4BB7);
  static const pink = Color(0xFFB83280);
  static const pinkSoft = Color(0xFFFCEBF4);
  static const red = Color(0xFFC62D2D); // a wrong answer
  static const redSoft = Color(0xFFFBE9E9);
  static const text = Color(0xFF1A1D3B);
  static const muted = Color(0xFF6B6E8C);
  static const line = Color(0xFFE2E4EE);
  static const bg = Color(0xFFF5F6FA);
  static const surface = Color(0xFFFFFFFF);

  /// English uses the font of the books, Lexend: the lessons, and the
  /// interface in English. Arabic uses Cairo. IPA symbols fall back to Noto Sans.
  static const english = 'Lexend';
  static const arabic = 'Cairo';
  static const fallback = ['NotoSansIPA', 'Cairo'];

  /// The color of each kind of lesson, as in the books.
  static Color kind(String kind) => switch (kind) {
        'story' => orange,
        'topic' => navy,
        'science' => teal,
        'news' => violet,
        'podcast' => pink,
        'conversation' || 'speaking' => green,
        _ => orange,
      };

  /// The avatar colors a to e of the cast, as in the books.
  static Color avatar(String key) => switch (key) {
        'a' => navy,
        'b' => orange,
        'c' => green,
        'd' => amber,
        _ => muted,
      };

  static ThemeData theme({bool arabic = false}) {
    final scheme = ColorScheme.fromSeed(
      seedColor: navy,
      primary: navy,
      secondary: orange,
      surface: surface,
    );
    return ThemeData(
      colorScheme: scheme,
      scaffoldBackgroundColor: bg,
      fontFamily: arabic ? Fvi.arabic : english,
      fontFamilyFallback: fallback,
      appBarTheme: const AppBarTheme(
        backgroundColor: surface,
        foregroundColor: text,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: line),
        ),
      ),
      textTheme: const TextTheme().apply(bodyColor: text, displayColor: text),
    );
  }
}
