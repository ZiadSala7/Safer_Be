import 'package:flutter/material.dart';

import '../entities/app_preferences.dart';

abstract interface class AppPreferencesRepository {
  Future<AppPreferences> load();
  Future<void> saveThemeMode(ThemeMode themeMode);
  Future<void> saveLocale(Locale locale);
}
