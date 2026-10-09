import 'package:flutter/material.dart';

/// Centralised colours for Overload.ai
///
class AppColors {
  static const Color background = Color(0xFF0B0E14); // near-black navy
  static const Color surface = Color(0xFF141823); // card background
  static const Color surfaceLight = Color(0xFF1C2230); // input fields, etc.
  static const Color primary = Color(0xFF3D5CFF); // main blue accent
  static const Color primaryDark = Color(0xFF2A3FD6);
  static const Color success = Color(0xFF2ECC71); // green for "up" stats
  static const Color danger = Color(0xFFE74C3C); // red for End/Missed/Delete
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF8A8FA3);
  static const Color divider = Color(0xFF252B3B);
}

class AppTheme {
  static TextTheme _montserratTextTheme(TextTheme base) {
    return base.copyWith(
      displayLarge: base.displayLarge?.copyWith(fontFamily: 'Montserrat'),
      displayMedium: base.displayMedium?.copyWith(fontFamily: 'Montserrat'),
      displaySmall: base.displaySmall?.copyWith(fontFamily: 'Montserrat'),
      headlineLarge: base.headlineLarge?.copyWith(fontFamily: 'Montserrat'),
      headlineMedium: base.headlineMedium?.copyWith(fontFamily: 'Montserrat'),
      headlineSmall: base.headlineSmall?.copyWith(fontFamily: 'Montserrat'),
      titleLarge: base.titleLarge?.copyWith(fontFamily: 'Montserrat'),
      titleMedium: base.titleMedium?.copyWith(fontFamily: 'Montserrat'),
      titleSmall: base.titleSmall?.copyWith(fontFamily: 'Montserrat'),
      bodyLarge: base.bodyLarge?.copyWith(fontFamily: 'Montserrat'),
      bodyMedium: base.bodyMedium?.copyWith(fontFamily: 'Montserrat'),
      bodySmall: base.bodySmall?.copyWith(fontFamily: 'Montserrat'),
      labelLarge: base.labelLarge?.copyWith(fontFamily: 'Montserrat'),
      labelMedium: base.labelMedium?.copyWith(fontFamily: 'Montserrat'),
      labelSmall: base.labelSmall?.copyWith(fontFamily: 'Montserrat'),
    );
  }

  /// Derives a near-black background/surface tinted with [accent]'s hue, so
  /// picking a theme colour visibly re-tints the whole screen instead of
  /// just button/border accents. Returns the original hardcoded colour
  /// unchanged when [accent] is still the default blue, so nothing looks
  /// different for anyone who never opens the colour picker.
  static Color _tint(Color accent, Color original, double lightness) {
    if (accent.toARGB32() == AppColors.primary.toARGB32()) return original;
    return HSLColor.fromColor(
      accent,
    ).withLightness(lightness).withSaturation(0.45).toColor();
  }

  /// [accent] drives every theme-level use of the app's accent colour:
  /// button backgrounds, focused input borders, bottom nav selection,
  /// ColorScheme.primary/secondary, AND (via _tint above) the scaffold
  /// background, app bar, bottom nav bar, card backgrounds (AppCard reads
  /// Theme.of(context).cardTheme.color) and input fill colour. See
  /// providers/theme_provider.dart for where it comes from (Profile
  /// screen's 5 swatches, persisted across restarts). Defaults to
  /// AppColors.primary so callers that don't care about personalisation
  /// still get the original look.
  static ThemeData darkTheme([Color accent = AppColors.primary]) {
    final background = _tint(accent, AppColors.background, 0.06);
    final surface = _tint(accent, AppColors.surface, 0.11);
    final surfaceLight = _tint(accent, AppColors.surfaceLight, 0.16);

    final base = ThemeData.dark(useMaterial3: true);
    final montserratTextTheme = _montserratTextTheme(base.textTheme);
    final montserratPrimaryTextTheme = _montserratTextTheme(
      base.primaryTextTheme,
    );

    return ThemeData(
      useMaterial3: true,
      fontFamily: 'Montserrat',
      scaffoldBackgroundColor: background,
      brightness: Brightness.dark,
      textTheme: montserratTextTheme,
      primaryTextTheme: montserratPrimaryTextTheme,
      colorScheme: ColorScheme.dark(
        primary: accent,
        secondary: accent,
        surface: surface,
        error: AppColors.danger,
      ),

      appBarTheme: AppBarTheme(
        backgroundColor: background,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        titleTextStyle: const TextStyle(
          fontFamily: 'Montserrat',
          color: AppColors.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),

      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: surface,
        selectedItemColor: accent,
        unselectedItemColor: AppColors.textSecondary,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: AppColors.textPrimary,
          minimumSize: const Size.fromHeight(50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontFamily: 'Montserrat',
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textPrimary,
          side: const BorderSide(color: AppColors.divider),
          minimumSize: const Size.fromHeight(50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontFamily: 'Montserrat',
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: accent,
          textStyle: const TextStyle(
            fontFamily: 'Montserrat',
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceLight,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: accent, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.danger, width: 1.2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.danger, width: 1.5),
        ),
        hintStyle: const TextStyle(color: AppColors.textSecondary),
        labelStyle: const TextStyle(color: AppColors.textSecondary),
      ),

      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),

      dividerTheme: const DividerThemeData(
        color: AppColors.divider,
        thickness: 1,
      ),
    );
  }
}
