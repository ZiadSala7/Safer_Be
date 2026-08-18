import 'dart:async';

import 'package:flutter/material.dart';

import '../features/settings/data/repositories/local_app_preferences_repository.dart';
import '../features/settings/domain/repositories/app_preferences_repository.dart';
import '../features/auth/data/repositories/api_auth_repository.dart';
import '../features/auth/domain/entities/auth_user.dart';
import '../features/auth/domain/repositories/auth_repository.dart';

class AppController extends ChangeNotifier {
  AppController({
    AppPreferencesRepository? preferencesRepository,
    AuthRepository? authRepository,
  }) : _preferencesRepository = preferencesRepository,
       _authRepository = authRepository;

  AppPreferencesRepository? _preferencesRepository;
  AuthRepository? _authRepository;
  ThemeMode themeMode = ThemeMode.system;
  Locale locale = const Locale('en');
  bool isGuest = true;
  AuthUser? user;

  AppPreferencesRepository get _repository =>
      _preferencesRepository ??= LocalAppPreferencesRepository();
  AuthRepository get authRepository => _authRepository ??= ApiAuthRepository();

  Future<void> initialize() async {
    final preferences = await _repository.load();
    themeMode = preferences.themeMode;
    locale = preferences.locale ?? _deviceLocale();
    var hadSession = false;
    try {
      hadSession = await authRepository.hasSession();
      isGuest = !hadSession;
      if (!isGuest) {
        final cached = await authRepository.readCachedUser();
        if (cached != null) user = cached;
        try {
          final fresh = await authRepository.me();
          final hasRealName =
              fresh.name.isNotEmpty && fresh.name != 'Safer Be traveler';
          if (hasRealName) {
            user = fresh;
            await authRepository.writeCachedUser(fresh);
          }
        } catch (_) {
          if (user == null) {
            await authRepository.logout();
            isGuest = true;
          }
        }
      }
    } catch (_) {
      if (hadSession) await authRepository.logout();
      user = null;
      isGuest = true;
    }
  }

  Locale _deviceLocale() {
    final languageCode =
        WidgetsBinding.instance.platformDispatcher.locale.languageCode;
    return Locale(languageCode == 'ar' ? 'ar' : 'en');
  }

  void toggleTheme() {
    themeMode = themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    notifyListeners();
    unawaited(_repository.saveThemeMode(themeMode));
  }

  void toggleLocale() {
    locale = locale.languageCode == 'ar'
        ? const Locale('en')
        : const Locale('ar');
    notifyListeners();
    unawaited(_repository.saveLocale(locale));
  }

  void signedIn(AuthUser value) {
    user = value;
    isGuest = false;
    notifyListeners();
  }

  Future<void> signOut() async {
    await authRepository.logout();
    user = null;
    isGuest = true;
    notifyListeners();
  }
}

class AppControllerScope extends InheritedNotifier<AppController> {
  const AppControllerScope({
    required super.notifier,
    required super.child,
    super.key,
  });

  static AppController of(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<AppControllerScope>()!
        .notifier!;
  }
}
