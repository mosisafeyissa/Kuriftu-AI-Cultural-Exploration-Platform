import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AfrilensColors {
  AfrilensColors._();

  static const Color gold = Color(0xFFD4AF37);
  static const Color goldLight = Color(0xFFF4D03F);
  static const Color goldDark = Color(0xFFB8960C);
  static const Color goldAmber = Color(0xFFB8860B);

  static const Color background = Color(0xFF0A0A0A);
  static const Color surface = Color(0xFF141414);
  static const Color surfaceLight = Color(0xFF1E1E1E);
  static const Color card = Color(0xFF1A1A1A);

  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFB0B0B0);
  static const Color textMuted = Color(0xFF707070);

  static const Color glassFill = Color(0x14FFFFFF);
  static const Color glassBorder = Color(0x33FFFFFF);
  static const Color glassHighlight = Color(0x0DFFFFFF);
}

class AfrilensTheme {
  AfrilensTheme._();

  static TextStyle get headlineSerif => GoogleFonts.playfairDisplay(
        color: AfrilensColors.textPrimary,
        fontWeight: FontWeight.w700,
      );

  static TextStyle get bodyText => GoogleFonts.inter(
        color: AfrilensColors.textSecondary,
        fontSize: 14,
        height: 1.6,
      );

  static TextStyle get labelText => GoogleFonts.inter(
        color: AfrilensColors.textMuted,
        fontSize: 12,
        fontWeight: FontWeight.w500,
        letterSpacing: 1.2,
      );

  static TextStyle get goldAccent => GoogleFonts.inter(
        color: AfrilensColors.gold,
        fontSize: 13,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.8,
      );

  static BoxDecoration get glassDecoration => BoxDecoration(
        color: AfrilensColors.glassFill,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AfrilensColors.glassBorder, width: 0.5),
      );

  static BoxDecoration glassDecorationWithRadius(double radius) => BoxDecoration(
        color: AfrilensColors.glassFill,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: AfrilensColors.glassBorder, width: 0.5),
      );

  static List<BoxShadow> get softShadow => [
        BoxShadow(
          color: Colors.black.withOpacity(0.4),
          blurRadius: 24,
          offset: const Offset(0, 8),
        ),
      ];

  static ThemeData get darkTheme => ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AfrilensColors.background,
        primaryColor: AfrilensColors.gold,
        colorScheme: const ColorScheme.dark(
          primary: AfrilensColors.gold,
          secondary: AfrilensColors.goldLight,
          surface: AfrilensColors.surface,
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: GoogleFonts.playfairDisplay(
            color: AfrilensColors.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
          iconTheme: const IconThemeData(color: AfrilensColors.textPrimary),
        ),
        textTheme: TextTheme(
          headlineLarge: headlineSerif.copyWith(fontSize: 32),
          headlineMedium: headlineSerif.copyWith(fontSize: 24),
          headlineSmall: headlineSerif.copyWith(fontSize: 20),
          bodyLarge: bodyText.copyWith(fontSize: 16),
          bodyMedium: bodyText,
          bodySmall: bodyText.copyWith(fontSize: 12),
          labelLarge: labelText.copyWith(fontSize: 14),
          labelMedium: labelText,
          labelSmall: labelText.copyWith(fontSize: 10),
        ),
        useMaterial3: true,
      );
}

