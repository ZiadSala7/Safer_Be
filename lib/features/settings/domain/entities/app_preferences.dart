import 'package:flutter/material.dart';

class AppPreferences {
  const AppPreferences({required this.themeMode, required this.locale});

  final ThemeMode themeMode;
  final Locale? locale;
}
