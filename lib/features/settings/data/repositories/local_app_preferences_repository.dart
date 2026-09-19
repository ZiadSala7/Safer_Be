import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/app_preferences.dart';
import '../../domain/repositories/app_preferences_repository.dart';

class LocalAppPreferencesRepository implements AppPreferencesRepository {
  LocalAppPreferencesRepository({SharedPreferencesAsync? preferences})
    : _preferences = preferences ?? SharedPreferencesAsync();

  static const _themeKey = 'selected_theme_mode';
  static const _localeKey = 'selected_locale';
  static const _currencyKey = 'selected_currency';
  final SharedPreferencesAsync _preferences;

  @override
  Future<AppPreferences> load() async {
    final results = await Future.wait([
      _preferences.getString(_themeKey),
      _preferences.getString(_localeKey),
      _preferences.getString(_currencyKey),
    ]);

    return AppPreferences(
      themeMode: _themeFromName(results[0]),
      locale: switch (results[1]) {
        'ar' => const Locale('ar'),
        'en' => const Locale('en'),
        _ => null,
      },
      currency: (results[2] != null && results[2]!.isNotEmpty)
          ? results[2]!
          : 'SAR',
    );
  }

  @override
  Future<void> saveLocale(Locale locale) =>
      _preferences.setString(_localeKey, locale.languageCode);

  @override
  Future<void> saveThemeMode(ThemeMode themeMode) =>
      _preferences.setString(_themeKey, themeMode.name);

  @override
  Future<void> saveCurrency(String currency) =>
      _preferences.setString(_currencyKey, currency);

  ThemeMode _themeFromName(String? value) => switch (value) {
    'light' => ThemeMode.light,
    'dark' => ThemeMode.dark,
    _ => ThemeMode.system,
  };
}
