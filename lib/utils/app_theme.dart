import 'package:flutter/material.dart';
import 'style/app_colors.dart';
import 'style/app_fonts.dart';
import 'style/app_radius.dart';

class AppTheme {
  // Create responsive theme based on context
  static ThemeData getTheme(BuildContext context, bool isDark) {
    final screenWidth = MediaQuery.of(context).size.width;
    final scaleFactor = _getScaleFactor(screenWidth);

    return isDark ? _darkTheme(scaleFactor) : _lightTheme(scaleFactor);
  }

  static double _getScaleFactor(double width) {
    if (width < 600) return 1.0; // Mobile
    if (width < 900) return 1.15; // Tablet
    return 1.3; // Desktop
  }

  // ðŸŒž Light Theme
  static ThemeData _lightTheme(double scale) {
    return ThemeData(
      brightness: Brightness.light,
      useMaterial3: true,
      colorScheme: const ColorScheme.light(
        primary: AppColors.lightPrimary,
        onPrimary: AppColors.lightPrimaryForeground,
        secondary: AppColors.lightSecondary,
        onSecondary: AppColors.lightSecondaryForeground,
        surface: AppColors.lightCard,
        onSurface: AppColors.lightForeground,
        error: AppColors.lightDestructive,
      ),
      scaffoldBackgroundColor: AppColors.lightBackground,
      cardColor: AppColors.lightCard,
      textTheme: TextTheme(
        displayLarge: TextStyle(
          fontFamily: AppFonts.heading,
          fontWeight: FontWeight.w700,
          fontSize: 32 * scale,
          color: AppColors.lightForeground,
        ),
        displayMedium: TextStyle(
          fontFamily: AppFonts.heading,
          fontWeight: FontWeight.w700,
          fontSize: 28 * scale,
          color: AppColors.lightForeground,
        ),
        headlineLarge: TextStyle(
          fontFamily: AppFonts.heading,
          fontWeight: FontWeight.w600,
          fontSize: 24 * scale,
          color: AppColors.lightForeground,
        ),
        headlineSmall: TextStyle(
          fontFamily: AppFonts.heading,
          fontWeight: FontWeight.w600,
          fontSize: 20 * scale,
          color: AppColors.lightForeground,
        ),
        titleLarge: TextStyle(
          fontFamily: AppFonts.heading,
          fontWeight: FontWeight.w600,
          fontSize: 18 * scale,
          color: AppColors.lightForeground,
        ),
        bodyLarge: TextStyle(
          fontFamily: AppFonts.body,
          fontSize: 16 * scale,
          color: AppColors.lightForeground,
        ),
        bodyMedium: TextStyle(
          fontFamily: AppFonts.body,
          fontSize: 14 * scale,
          color: AppColors.lightForeground,
        ),
        bodySmall: TextStyle(
          fontFamily: AppFonts.body,
          fontSize: 12 * scale,
          color: AppColors.lightMuted,
        ),
        labelLarge: TextStyle(
          fontFamily: AppFonts.body,
          fontWeight: FontWeight.w600,
          fontSize: 14 * scale,
          color: AppColors.lightForeground,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        contentPadding: EdgeInsets.symmetric(
          horizontal: 16 * scale,
          vertical: 12 * scale,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md * scale),
          borderSide: const BorderSide(color: AppColors.lightBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md * scale),
          borderSide: const BorderSide(color: AppColors.lightBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md * scale),
          borderSide: const BorderSide(color: AppColors.lightPrimary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md * scale),
          borderSide: const BorderSide(color: AppColors.lightDestructive),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          foregroundColor: AppColors.lightPrimaryForeground,
          backgroundColor: AppColors.lightPrimary,
          padding: EdgeInsets.symmetric(
            horizontal: 24 * scale,
            vertical: 14 * scale,
          ),
          minimumSize: Size(64 * scale, 48 * scale),
          textStyle: TextStyle(
            fontFamily: AppFonts.body,
            fontWeight: FontWeight.w600,
            fontSize: 16 * scale,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md * scale),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.lightForeground,
          padding: EdgeInsets.symmetric(
            horizontal: 24 * scale,
            vertical: 14 * scale,
          ),
          minimumSize: Size(64 * scale, 48 * scale),
          textStyle: TextStyle(
            fontFamily: AppFonts.body,
            fontWeight: FontWeight.w600,
            fontSize: 16 * scale,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md * scale),
          ),
          side: const BorderSide(color: AppColors.lightBorder),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.lightPrimary,
          padding: EdgeInsets.symmetric(
            horizontal: 16 * scale,
            vertical: 10 * scale,
          ),
          textStyle: TextStyle(
            fontFamily: AppFonts.body,
            fontWeight: FontWeight.w600,
            fontSize: 16 * scale,
          ),
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.lightCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg * scale),
          side: const BorderSide(color: AppColors.lightBorder),
        ),
        margin: EdgeInsets.all(8 * scale),
      ),
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        backgroundColor: AppColors.lightBackground,
        foregroundColor: AppColors.lightForeground,
        titleTextStyle: TextStyle(
          fontFamily: AppFonts.heading,
          fontWeight: FontWeight.w600,
          fontSize: 20 * scale,
          color: AppColors.lightForeground,
        ),
      ),
    );
  }

  // ðŸŒ™ Dark Theme
  static ThemeData _darkTheme(double scale) {
    return ThemeData(
      brightness: Brightness.dark,
      useMaterial3: true,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.darkPrimary,
        onPrimary: AppColors.darkPrimaryForeground,
        secondary: AppColors.darkSecondary,
        onSecondary: AppColors.darkSecondaryForeground,
        surface: AppColors.darkCard,
        onSurface: AppColors.darkForeground,
        error: AppColors.darkDestructive,
      ),
      scaffoldBackgroundColor: AppColors.darkBackground,
      cardColor: AppColors.darkCard,
      textTheme: TextTheme(
        displayLarge: TextStyle(
          fontFamily: AppFonts.heading,
          fontWeight: FontWeight.w700,
          fontSize: 32 * scale,
          color: AppColors.darkForeground,
        ),
        displayMedium: TextStyle(
          fontFamily: AppFonts.heading,
          fontWeight: FontWeight.w700,
          fontSize: 28 * scale,
          color: AppColors.darkForeground,
        ),
        headlineLarge: TextStyle(
          fontFamily: AppFonts.heading,
          fontWeight: FontWeight.w600,
          fontSize: 24 * scale,
          color: AppColors.darkForeground,
        ),
        headlineSmall: TextStyle(
          fontFamily: AppFonts.heading,
          fontWeight: FontWeight.w600,
          fontSize: 20 * scale,
          color: AppColors.darkForeground,
        ),
        titleLarge: TextStyle(
          fontFamily: AppFonts.heading,
          fontWeight: FontWeight.w600,
          fontSize: 18 * scale,
          color: AppColors.darkForeground,
        ),
        bodyLarge: TextStyle(
          fontFamily: AppFonts.body,
          fontSize: 16 * scale,
          color: AppColors.darkForeground,
        ),
        bodyMedium: TextStyle(
          fontFamily: AppFonts.body,
          fontSize: 14 * scale,
          color: AppColors.darkForeground,
        ),
        bodySmall: TextStyle(
          fontFamily: AppFonts.body,
          fontSize: 12 * scale,
          color: AppColors.darkMuted,
        ),
        labelLarge: TextStyle(
          fontFamily: AppFonts.body,
          fontWeight: FontWeight.w600,
          fontSize: 14 * scale,
          color: AppColors.darkForeground,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        contentPadding: EdgeInsets.symmetric(
          horizontal: 16 * scale,
          vertical: 12 * scale,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md * scale),
          borderSide: const BorderSide(color: AppColors.darkBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md * scale),
          borderSide: const BorderSide(color: AppColors.darkBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md * scale),
          borderSide: const BorderSide(color: AppColors.darkPrimary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md * scale),
          borderSide: const BorderSide(color: AppColors.darkDestructive),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          foregroundColor: AppColors.darkPrimaryForeground,
          backgroundColor: AppColors.darkPrimary,
          padding: EdgeInsets.symmetric(
            horizontal: 24 * scale,
            vertical: 14 * scale,
          ),
          minimumSize: Size(64 * scale, 48 * scale),
          textStyle: TextStyle(
            fontFamily: AppFonts.body,
            fontWeight: FontWeight.w600,
            fontSize: 16 * scale,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md * scale),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.darkForeground,
          padding: EdgeInsets.symmetric(
            horizontal: 24 * scale,
            vertical: 14 * scale,
          ),
          minimumSize: Size(64 * scale, 48 * scale),
          textStyle: TextStyle(
            fontFamily: AppFonts.body,
            fontWeight: FontWeight.w600,
            fontSize: 16 * scale,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md * scale),
          ),
          side: const BorderSide(color: AppColors.darkBorder),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.darkPrimary,
          padding: EdgeInsets.symmetric(
            horizontal: 16 * scale,
            vertical: 10 * scale,
          ),
          textStyle: TextStyle(
            fontFamily: AppFonts.body,
            fontWeight: FontWeight.w600,
            fontSize: 16 * scale,
          ),
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.darkCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg * scale),
          side: const BorderSide(color: AppColors.darkBorder),
        ),
        margin: EdgeInsets.all(8 * scale),
      ),
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        backgroundColor: AppColors.darkBackground,
        foregroundColor: AppColors.darkForeground,
        titleTextStyle: TextStyle(
          fontFamily: AppFonts.heading,
          fontWeight: FontWeight.w600,
          fontSize: 20 * scale,
          color: AppColors.darkForeground,
        ),
      ),
    );
  }

  // Static themes for backward compatibility
  static final ThemeData light = _lightTheme(1.0);
  static final ThemeData dark = _darkTheme(1.0);
}