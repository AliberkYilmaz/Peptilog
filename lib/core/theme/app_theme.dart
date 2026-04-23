import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Warm Ink + Serif design system
/// Dark editorial palette, amber accent #E8A84C
class AppTheme {
  static const Color amber = Color(0xFFE8A84C);
  static const Color background = Color(0xFF1A1714);
  static const Color surface = Color(0xFF252118);
  static const Color onBackground = Color(0xFFF2EDE6);
  static const Color onSurface = Color(0xFFD6CEC3);
  static const Color divider = Color(0xFF3A342C);
  static const Color error = Color(0xFFCF6679);

  static ThemeData get dark {
    final base = ThemeData.dark(useMaterial3: true);
    return base.copyWith(
      colorScheme: const ColorScheme.dark(
        primary: amber,
        onPrimary: Color(0xFF1A1714),
        secondary: amber,
        onSecondary: Color(0xFF1A1714),
        surface: surface,
        onSurface: onSurface,
        error: error,
      ),
      scaffoldBackgroundColor: background,
      textTheme: GoogleFonts.playfairDisplayTextTheme(base.textTheme).copyWith(
        bodyMedium: GoogleFonts.inter(color: onSurface),
        bodySmall: GoogleFonts.inter(color: onSurface),
        labelLarge: GoogleFonts.inter(color: onBackground),
      ),
      dividerColor: divider,
      cardTheme: CardThemeData(
        color: surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        foregroundColor: onBackground,
        titleTextStyle: GoogleFonts.playfairDisplay(
          color: onBackground,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        elevation: 0,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: amber,
          foregroundColor: const Color(0xFF1A1714),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }
}
