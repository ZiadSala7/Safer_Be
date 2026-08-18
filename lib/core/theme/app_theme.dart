import 'package:flutter/material.dart';

import 'app_colors.dart';

abstract final class AppTheme {
  static const arabicFontFamily = 'Cairo';
  static const englishFontFamily = 'Montserrat';

  static ThemeData light(Locale locale) => _theme(Brightness.light, locale);
  static ThemeData dark(Locale locale) => _theme(Brightness.dark, locale);

  static ThemeData _theme(Brightness brightness, Locale locale) {
    final dark = brightness == Brightness.dark;
    final isArabic = locale.languageCode == 'ar';
    final fontFamily = isArabic ? arabicFontFamily : englishFontFamily;
    final fontFamilyFallback = [
      isArabic ? englishFontFamily : arabicFontFamily,
    ];
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.teal,
      brightness: brightness,
      primary: AppColors.teal,
      secondary: AppColors.orange,
      surface: dark ? const Color(0xFF10243A) : Colors.white,
    );
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: dark ? AppColors.navy : AppColors.canvas,
      fontFamily: fontFamily,
      textTheme: ThemeData(brightness: brightness).textTheme.apply(
        fontFamily: fontFamily,
        fontFamilyFallback: fontFamilyFallback,
        bodyColor: dark ? const Color(0xFFF0F6FC) : AppColors.ink,
        displayColor: dark ? Colors.white : AppColors.ink,
      ),
      primaryTextTheme: ThemeData(brightness: brightness).primaryTextTheme
          .apply(
            fontFamily: fontFamily,
            fontFamilyFallback: fontFamilyFallback,
          ),
      cardTheme: CardThemeData(
        color: scheme.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 72,
        backgroundColor: scheme.surface.withValues(alpha: .96),
        indicatorColor: AppColors.teal.withValues(alpha: .14),
        labelTextStyle: WidgetStateProperty.all(
          TextStyle(
            fontFamily: fontFamily,
            fontFamilyFallback: fontFamilyFallback,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: dark
            ? Colors.white.withValues(alpha: .06)
            : const Color(0xFFF8FAFC),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
