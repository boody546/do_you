import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Google Family Link Color Palette
  static const Color googleBlue = Color(0xFF1A73E8);
  static const Color googleBlueLight = Color(0xFFE8F0FE);
  static const Color googleBlueDark = Color(0xFF1557B0);
  static const Color googleBackground = Color(0xFFF8F9FA);
  static const Color googleSurface = Color(0xFFFFFFFF);
  static const Color googleCardBorder = Color(0xFFE0E0E0);
  
  // Status & Action Colors
  static const Color accentGreen = Color(0xFF1E8E3E);
  static const Color accentGreenLight = Color(0xFFE6F4EA);
  static const Color warningAmber = Color(0xFFF9AB00);
  static const Color alertRed = Color(0xFFD93025);
  static const Color alertRedLight = Color(0xFFFCE8E6);

  // -------------------------------------------------------------
  // 🔗 Legacy Aliases (عشان التوافق مع الشاشات القديمة ومنع أخطاء الـ Build)
  // -------------------------------------------------------------
  static const Color primaryBlue = googleBlue;
  static const Color primaryCyan = googleBlue;
  static const Color darkCard = googleSurface;
  static const Color accentEmerald = accentGreen;
  static const Color alertRose = alertRed;
  static const LinearGradient primaryGradient = familyLinkGradient;
  // -------------------------------------------------------------

  // Linear Gradients
  static const LinearGradient familyLinkGradient = LinearGradient(
    colors: [googleBlue, Color(0xFF4285F4)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient alertGradient = LinearGradient(
    colors: [alertRed, Color(0xFFEA4335)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Light Theme (Default for Google Family Link Style)
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: googleBackground,
      colorScheme: const ColorScheme.light(
        primary: googleBlue,
        secondary: Color(0xFF4285F4),
        tertiary: accentGreen,
        surface: googleSurface,
        background: googleBackground,
        error: alertRed,
      ),
      textTheme: GoogleFonts.plusJakartaSansTextTheme(
        ThemeData.light().textTheme,
      ).copyWith(
        displayLarge: GoogleFonts.plusJakartaSans(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: const Color(0xFF202124),
        ),
        titleLarge: GoogleFonts.plusJakartaSans(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: const Color(0xFF202124),
        ),
        bodyLarge: GoogleFonts.plusJakartaSans(
          fontSize: 16,
          color: const Color(0xFF5F6368),
        ),
      ),
      cardTheme: CardTheme(
        color: googleSurface,
        elevation: 1.5,
        shadowColor: Colors.black.withOpacity(0.08),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: googleCardBorder, width: 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 2,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          backgroundColor: googleBlue,
          foregroundColor: Colors.white,
          textStyle: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: googleSurface,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.plusJakartaSans(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: const Color(0xFF202124),
        ),
        iconTheme: const IconThemeData(color: Color(0xFF5F6368)),
      ),
    );
  }

  // Dark Theme Alternative
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF121212),
      colorScheme: const ColorScheme.dark(
        primary: googleBlue,
        secondary: Color(0xFF4285F4),
        surface: Color(0xFF1E1E1E),
        background: Color(0xFF121212),
        error: alertRed,
      ),
      textTheme: GoogleFonts.plusJakartaSansTextTheme(
        ThemeData.dark().textTheme,
      ),
      cardTheme: CardTheme(
        color: const Color(0xFF1E1E1E),
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Color(0xFF2C2C2C), width: 1),
        ),
      ),
    );
  }
}