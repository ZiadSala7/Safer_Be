import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../features/settings/data/repositories/api_settings_repository.dart';
import '../features/settings/data/repositories/local_app_preferences_repository.dart';
import '../features/settings/domain/repositories/app_preferences_repository.dart';
import '../features/settings/domain/repositories/settings_repository.dart';
import '../features/auth/data/repositories/api_auth_repository.dart';
import '../features/auth/domain/entities/auth_user.dart';
import '../features/auth/domain/repositories/auth_repository.dart';
import '../features/notifications/services/notification_service.dart';

class AppController extends ChangeNotifier {
  AppController({
    AppPreferencesRepository? preferencesRepository,
    AuthRepository? authRepository,
    SettingsRepository? settingsRepository,
  }) : _preferencesRepository = preferencesRepository,
       _authRepository = authRepository,
       _settingsRepository = settingsRepository;

  AppPreferencesRepository? _preferencesRepository;
  AuthRepository? _authRepository;
  SettingsRepository? _settingsRepository;
  ThemeMode themeMode = ThemeMode.system;
  Locale locale = const Locale('en');
  String currency = 'SAR';
  bool isGuest = true;
  AuthUser? user;

  /// Whether external payment gateway (e.g., MyFatoorah) should be displayed.
  /// When false, the app operates in "Free Purchases" mode.
  bool showPaymentGatewayMobile = true;

  /// Convenience boolean indicating whether free purchases mode is active.
  bool get isFreePurchase => !showPaymentGatewayMobile;

  /// Alias for [isFreePurchase].
  bool get freePurchases => !showPaymentGatewayMobile;

  AppPreferencesRepository get _repository =>
      _preferencesRepository ??= LocalAppPreferencesRepository();
  AuthRepository get authRepository => _authRepository ??= ApiAuthRepository();
  SettingsRepository get settingsRepository =>
      _settingsRepository ??= ApiSettingsRepository();

  Future<void> initialize() async {
    final preferences = await _repository.load();
    themeMode = preferences.themeMode;
    locale = preferences.locale ?? _deviceLocale();
    currency = preferences.currency;
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

    try {
      final settings = await settingsRepository.getSettings();
      showPaymentGatewayMobile = settings.showPaymentGatewayMobile;
    } catch (_) {
      // Non-fatal, keeps default
    }

    unawaited(_syncAppIcon());
  }

  Locale _deviceLocale() {
    final languageCode =
        WidgetsBinding.instance.platformDispatcher.locale.languageCode;
    return Locale(languageCode == 'ar' ? 'ar' : 'en');
  }

  Future<void> refreshSettings({bool forceRefresh = true}) async {
    final settings =
        await settingsRepository.getSettings(forceRefresh: forceRefresh);
    if (showPaymentGatewayMobile != settings.showPaymentGatewayMobile) {
      showPaymentGatewayMobile = settings.showPaymentGatewayMobile;
      notifyListeners();
    }
  }

  Future<bool> updatePaymentGatewaySetting(
    bool show, {
    String? adminToken,
  }) async {
    final updated = await settingsRepository.updateSettings(
      showPaymentGatewayMobile: show,
      adminToken: adminToken,
    );
    showPaymentGatewayMobile = updated.showPaymentGatewayMobile;
    notifyListeners();
    return true;
  }

  Future<bool> toggleFreePurchases({String? adminToken}) =>
      updatePaymentGatewaySetting(
        !showPaymentGatewayMobile,
        adminToken: adminToken,
      );

  void setFreePurchasesLocal(bool isFree) {
    showPaymentGatewayMobile = !isFree;
    notifyListeners();
  }

  void toggleTheme() {
    themeMode = themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    notifyListeners();
    unawaited(_repository.saveThemeMode(themeMode));
    unawaited(_syncAppIcon());
  }

  Future<void> _syncAppIcon() async {
    try {
      final isDark = themeMode == ThemeMode.dark ||
          (themeMode == ThemeMode.system &&
              WidgetsBinding.instance.platformDispatcher.platformBrightness ==
                  Brightness.dark);
      await const MethodChannel('com.safer_be.safer_be_project/app_icon')
          .invokeMethod('setDarkIcon', {'isDark': isDark});
    } catch (_) {}
  }

  void toggleLocale() {
    locale = locale.languageCode == 'ar'
        ? const Locale('en')
        : const Locale('ar');
    notifyListeners();
    unawaited(_repository.saveLocale(locale));
  }

  void setCurrency(String newCurrency) {
    final normalized = newCurrency.trim().toUpperCase();
    if (normalized.isEmpty || currency == normalized) return;
    currency = normalized;
    notifyListeners();
    unawaited(_repository.saveCurrency(normalized));
  }

  void signedIn(AuthUser value) {
    user = value;
    isGuest = false;
    notifyListeners();
    if (value.pushNotificationConsent) {
      unawaited(NotificationService.instance.syncDeviceRegistrationOnLogin(
        pushNotificationConsent: true,
      ));
    }
  }

  Future<void> signOut() async {
    try {
      await NotificationService.instance.unregisterCurrentDevice();
    } catch (_) {}
    await authRepository.logout();
    user = null;
    isGuest = true;
    notifyListeners();
  }

  Future<void> deleteAccount() async {
    try {
      await NotificationService.instance.unregisterCurrentDevice();
    } catch (_) {}
    await authRepository.deleteAccount();
    user = null;
    isGuest = true;
    notifyListeners();
  }

  Future<bool> setPushNotificationConsent(bool enable) async {
    final success = enable
        ? await NotificationService.instance.enablePush()
        : await NotificationService.instance.disablePush();

    if (success && user != null) {
      user = user!.copyWith(pushNotificationConsent: enable);
      notifyListeners();
    }
    return success;
  }

  Future<bool> setMarketingConsent(bool enable) async {
    final success =
        await NotificationService.instance.updateMarketingConsent(enable);
    if (success && user != null) {
      user = user!.copyWith(marketingConsent: enable);
      notifyListeners();
    }
    return success;
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
