import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class QuantumRescueTheme {
  static const Color background = Color(0xFF080A12);
  static const Color surface = Color(0xFF101422);
  static const Color card = Color(0xFF161C30);
  static const Color cardBorder = Color(0xFF222B48);

  static const Color primaryCyan = Color(0xFF00F5FF);
  static const Color accentNeon = Color(0xFF00FFCC);
  static const Color accentPurple = Color(0xFFA855F7);
  static const Color successGreen = Color(0xFF10B981);
  static const Color warningOrange = Color(0xFFF59E0B);
  static const Color dangerRed = Color(0xFFEF4444);
  static const Color textMuted = Color(0xFF8892B0);

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background,
      primaryColor: primaryCyan,
      colorScheme: const ColorScheme.dark(
        primary: primaryCyan,
        secondary: accentNeon,
        surface: surface,
        error: dangerRed,
      ),
      textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          letterSpacing: 0.5,
        ),
      ),
      cardTheme: CardThemeData(
        color: card,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: cardBorder, width: 1),
        ),
      ),
    );
  }
}
