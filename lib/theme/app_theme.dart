import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Cores da Espiritualidade
  static const Color darkBluePrimary = Color(0xFF0B192C);
  static const Color deepBlue = Color(0xFF1A365D);
  static const Color spiritualGold = Color(0xFFD4AF37);
  static const Color brightGold = Color(0xFFFFD700);
  static const Color offWhite = Color(0xFFF8F9FA);

  // Light Theme
  static ThemeData get lightTheme {
    final baseTextTheme = ThemeData.light().textTheme;

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: const ColorScheme.light(
        primary: deepBlue,
        onPrimary: offWhite,
        primaryContainer: darkBluePrimary,
        onPrimaryContainer: brightGold,
        secondary: spiritualGold,
        onSecondary: darkBluePrimary,
        secondaryContainer: Color(0xFFFFF4D0),
        onSecondaryContainer: darkBluePrimary,
        surface: offWhite,
        onSurface: darkBluePrimary,
        surfaceContainerHighest: Color(0xFFE9ECEF),
        onSurfaceVariant: deepBlue,
        tertiary: brightGold,
        onTertiary: darkBluePrimary,
        error: Color(0xFFBA1A1A),
        onError: Colors.white,
      ),
      scaffoldBackgroundColor: offWhite,
      appBarTheme: AppBarTheme(
        backgroundColor: darkBluePrimary,
        foregroundColor: spiritualGold,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.cinzel(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: spiritualGold,
        ),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 2,
        shadowColor: const Color(0x260B192C),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: spiritualGold, width: 0.5),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: spiritualGold,
        foregroundColor: darkBluePrimary,
        elevation: 4,
      ),
      textTheme: GoogleFonts.poppinsTextTheme(baseTextTheme).copyWith(
        displayLarge: GoogleFonts.cinzel(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: darkBluePrimary,
        ),
        displayMedium: GoogleFonts.cinzel(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: darkBluePrimary,
        ),
        titleLarge: GoogleFonts.cinzel(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: darkBluePrimary,
        ),
        titleMedium: GoogleFonts.poppins(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: deepBlue,
        ),
        bodyLarge: GoogleFonts.poppins(
          fontSize: 16,
          color: darkBluePrimary,
        ),
        bodyMedium: GoogleFonts.poppins(
          fontSize: 14,
          color: deepBlue,
        ),
      ),
      iconTheme: const IconThemeData(
        color: spiritualGold,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: spiritualGold,
          foregroundColor: darkBluePrimary,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  // Dark Theme
  static ThemeData get darkTheme {
    final baseTextTheme = ThemeData.dark().textTheme;

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: spiritualGold,
        onPrimary: darkBluePrimary,
        primaryContainer: deepBlue,
        onPrimaryContainer: brightGold,
        secondary: brightGold,
        onSecondary: darkBluePrimary,
        secondaryContainer: Color(0xFF2A2A3D),
        onSecondaryContainer: spiritualGold,
        surface: darkBluePrimary,
        onSurface: offWhite,
        surfaceContainerHighest: Color(0xFF16253B),
        onSurfaceVariant: offWhite,
        tertiary: spiritualGold,
        onTertiary: darkBluePrimary,
        error: Color(0xFFFFB4AB),
        onError: Color(0xFF690005),
      ),
      scaffoldBackgroundColor: darkBluePrimary,
      appBarTheme: AppBarTheme(
        backgroundColor: darkBluePrimary,
        foregroundColor: brightGold,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.cinzel(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: brightGold,
        ),
      ),
      cardTheme: CardThemeData(
        color: deepBlue,
        elevation: 4,
        shadowColor: const Color(0x4D000000),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: spiritualGold, width: 0.5),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: brightGold,
        foregroundColor: darkBluePrimary,
        elevation: 4,
      ),
      textTheme: GoogleFonts.poppinsTextTheme(baseTextTheme).copyWith(
        displayLarge: GoogleFonts.cinzel(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: brightGold,
        ),
        displayMedium: GoogleFonts.cinzel(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: brightGold,
        ),
        titleLarge: GoogleFonts.cinzel(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: spiritualGold,
        ),
        titleMedium: GoogleFonts.poppins(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: offWhite,
        ),
        bodyLarge: GoogleFonts.poppins(
          fontSize: 16,
          color: offWhite,
        ),
        bodyMedium: GoogleFonts.poppins(
          fontSize: 14,
          color: const Color(0xFFE2E8F0),
        ),
      ),
      iconTheme: const IconThemeData(
        color: brightGold,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: spiritualGold,
          foregroundColor: darkBluePrimary,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}
