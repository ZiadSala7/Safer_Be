import 'package:flutter/material.dart';

class AppPreferences {
  const AppPreferences({
    required this.themeMode,
    required this.locale,
    this.currency = 'SAR',
  });

  final ThemeMode themeMode;
  final Locale? locale;
  final String currency;
}
