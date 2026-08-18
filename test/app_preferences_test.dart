import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:safer_be_project/app/app_controller.dart';
import 'package:safer_be_project/features/settings/domain/entities/app_preferences.dart';
import 'package:safer_be_project/features/settings/domain/repositories/app_preferences_repository.dart';

class FakeAppPreferencesRepository implements AppPreferencesRepository {
  ThemeMode savedTheme = ThemeMode.dark;
  Locale savedLocale = const Locale('en');

  @override
  Future<AppPreferences> load() async =>
      AppPreferences(themeMode: savedTheme, locale: savedLocale);

  @override
  Future<void> saveLocale(Locale locale) async => savedLocale = locale;

  @override
  Future<void> saveThemeMode(ThemeMode themeMode) async =>
      savedTheme = themeMode;
}

void main() {
  test('controller restores and persists theme and language', () async {
    final repository = FakeAppPreferencesRepository();
    final controller = AppController(preferencesRepository: repository);
    addTearDown(controller.dispose);

    await controller.initialize();
    expect(controller.themeMode, ThemeMode.dark);
    expect(controller.locale, const Locale('en'));

    controller.toggleTheme();
    controller.toggleLocale();
    await Future<void>.delayed(Duration.zero);

    expect(repository.savedTheme, ThemeMode.light);
    expect(repository.savedLocale, const Locale('ar'));
  });
}
