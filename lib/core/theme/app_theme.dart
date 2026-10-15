import 'package:flutter/cupertino.dart';
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
      tertiary: dark ? AppColors.orangeLight : AppColors.tealLight,
      surface: dark ? const Color(0xFF10243A) : Colors.white,
    );
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: dark ? AppColors.navy : AppColors.canvas,
      fontFamily: fontFamily,
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: ZoomPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.windows: ZoomPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
        },
      ),
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
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.orange,
        foregroundColor: Colors.white,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return dark ? AppColors.orange : AppColors.teal;
          }
          return null;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return dark
                ? AppColors.orange.withValues(alpha: 0.35)
                : AppColors.teal.withValues(alpha: 0.35);
          }
          return null;
        }),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: dark ? AppColors.orange : AppColors.teal,
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return dark
                  ? AppColors.orange.withValues(alpha: 0.22)
                  : AppColors.teal.withValues(alpha: 0.14);
            }
            return null;
          }),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return dark ? AppColors.orangeLight : AppColors.teal;
            }
            return dark ? const Color(0xFF94A3B8) : AppColors.muted;
          }),
          side: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return BorderSide(
                color: dark ? AppColors.orange.withValues(alpha: 0.6) : AppColors.teal,
                width: 1.2,
              );
            }
            return BorderSide(
              color: dark ? Colors.white12 : Colors.black12,
            );
          }),
        ),
      ),
      chipTheme: ChipThemeData(
        selectedColor: dark
            ? AppColors.orange.withValues(alpha: 0.22)
            : AppColors.teal.withValues(alpha: 0.14),
        side: dark
            ? BorderSide(color: AppColors.orange.withValues(alpha: 0.4), width: 1.2)
            : null,
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return dark ? AppColors.orange : AppColors.teal;
          }
          return null;
        }),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return dark ? AppColors.orange : AppColors.teal;
          }
          return null;
        }),
        checkColor: const WidgetStatePropertyAll(Colors.white),
      ),
      tabBarTheme: TabBarThemeData(
        indicatorColor: dark ? AppColors.orange : AppColors.teal,
        labelColor: dark ? AppColors.orangeLight : AppColors.teal,
        unselectedLabelColor: dark ? const Color(0xFF94A3B8) : AppColors.muted,
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 72,
        backgroundColor: scheme.surface.withValues(alpha: .96),
        indicatorColor: dark
            ? AppColors.orange.withValues(alpha: .22)
            : AppColors.teal.withValues(alpha: .14),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(
              color: dark ? AppColors.orange : AppColors.teal,
              size: 24,
            );
          }
          return IconThemeData(
            color: dark ? const Color(0xFF94A3B8) : AppColors.muted,
            size: 24,
          );
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final isSelected = states.contains(WidgetState.selected);
          return TextStyle(
            fontFamily: fontFamily,
            fontFamilyFallback: fontFamilyFallback,
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            color: isSelected
                ? (dark ? AppColors.orangeLight : AppColors.teal)
                : (dark ? const Color(0xFF94A3B8) : AppColors.muted),
          );
        }),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: dark
            ? Colors.white.withValues(alpha: .06)
            : const Color(0xFFF8FAFC),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: dark ? AppColors.orange : AppColors.teal,
            width: 1.6,
          ),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
