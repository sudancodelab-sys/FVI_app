import 'package:flutter/material.dart';

/// The colors and fonts of the approved designs (docs/design/screens/4-admin-activation.png,
/// 5-admin-records.png), as in the student app.
abstract final class Fvi {
  static const navy = Color(0xFF262E62);
  static const navySoft = Color(0xFFE8EAF6);
  static const navyTint = Color(0xFFF2F3FA);
  static const orange = Color(0xFFE4451A);
  static const orangeSoft = Color(0xFFFDEDE7);
  static const green = Color(0xFF14935A);
  static const greenSoft = Color(0xFFE2F4EB);
  static const whatsapp = Color(0xFF1FA855);
  static const amber = Color(0xFFA86F06);
  static const amberSoft = Color(0xFFFFF3D6);
  static const red = Color(0xFFC62D2D);
  static const redSoft = Color(0xFFFBE9E9);
  static const text = Color(0xFF1A1D3B);
  static const muted = Color(0xFF6B6E8C);
  static const line = Color(0xFFE2E4EE);
  static const bg = Color(0xFFF5F6FA);
  static const surface = Color(0xFFFFFFFF);

  static const arabic = 'Cairo';
  static const english = 'Lexend';

  static ThemeData theme() => ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: navy, primary: navy, secondary: orange, surface: surface),
        scaffoldBackgroundColor: bg,
        fontFamily: arabic,
        fontFamilyFallback: const [english],
        appBarTheme: const AppBarTheme(
          backgroundColor: bg,
          foregroundColor: text,
          elevation: 0,
          scrolledUnderElevation: 0,
          titleTextStyle: TextStyle(fontFamily: arabic, fontSize: 22, fontWeight: FontWeight.w800, color: navy),
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: surface,
          indicatorColor: navySoft,
          labelTextStyle: WidgetStateProperty.resolveWith((s) => TextStyle(
                fontFamily: arabic,
                fontSize: 13,
                fontWeight: s.contains(WidgetState.selected) ? FontWeight.w800 : FontWeight.w600,
                color: s.contains(WidgetState.selected) ? navy : muted,
              )),
        ),
      );
}
