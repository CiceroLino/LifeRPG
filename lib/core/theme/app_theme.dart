import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color background = Color(0xFF212121); // Dark base
  static const Color surface = Color(0xFF303030); // Slightly lighter for cards
  static const Color primary = Color(0xFF03A9F4); // Accent blue
  static const Color accentRed = Color(0xFFF44336); // HP/Urgency
  static const Color accentAmber = Color(0xFFFFC107); // Level/XP
  static const Color textPrimary = Color(0xFFF5F5F5);
  static const Color textSecondary = Color(0xFFBDBDBD);
  static const Color border = Color(0xFF424242);

  static const Color primaryPurple = primary;
  static const Color secondaryGold = accentAmber;
  static const Color successGreen = Color(0xFF4CAF50);
  static const Color xpBlue = primary;

  static ThemeData get darkTheme {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background,
      colorScheme: ColorScheme.dark(
        primary: primary,
        secondary: accentAmber,
        surface: surface,
        error: accentRed,
      ),
      textTheme: GoogleFonts.robotoTextTheme(
        ThemeData.dark().textTheme.apply(
          bodyColor: textPrimary,
          displayColor: textPrimary,
        ),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: border),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      ),
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        backgroundColor: background,
        foregroundColor: textPrimary,
        titleTextStyle: GoogleFonts.roboto(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: textPrimary,
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: background,
        elevation: 4,
      ),
      iconTheme: const IconThemeData(color: textPrimary),
      chipTheme: const ChipThemeData(
        backgroundColor: surface,
        labelStyle: TextStyle(color: textPrimary),
        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      ),
      visualDensity: VisualDensity.compact,
      dividerColor: border,
    );
    return base.copyWith(
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: primary, width: 1.2),
        ),
        labelStyle: const TextStyle(color: textSecondary),
        hintStyle: const TextStyle(color: textSecondary),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: primary,
        linearTrackColor: border,
      ),
    );
  }

  static ThemeData get lightTheme => darkTheme;
}
