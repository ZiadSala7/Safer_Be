import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:safer_be_project/app/app_controller.dart';
import 'package:safer_be_project/core/network/api_client.dart';
import 'package:safer_be_project/features/settings/data/repositories/api_settings_repository.dart';
import 'package:safer_be_project/features/settings/domain/entities/app_preferences.dart';
import 'package:safer_be_project/features/settings/domain/entities/system_settings.dart';
import 'package:safer_be_project/features/settings/domain/repositories/app_preferences_repository.dart';
import 'package:safer_be_project/features/settings/domain/repositories/settings_repository.dart';
import 'package:safer_be_project/features/settings/presentation/controllers/free_purchases_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FakeAppPreferencesRepository implements AppPreferencesRepository {
  ThemeMode savedTheme = ThemeMode.light;
  Locale savedLocale = const Locale('en');
  String savedCurrency = 'SAR';

  @override
  Future<AppPreferences> load() async =>
      AppPreferences(themeMode: savedTheme, locale: savedLocale, currency: savedCurrency);

  @override
  Future<void> saveLocale(Locale locale) async => savedLocale = locale;

  @override
  Future<void> saveThemeMode(ThemeMode themeMode) async =>
      savedTheme = themeMode;

  @override
  Future<void> saveCurrency(String currency) async =>
      savedCurrency = currency;
}

class FakeSettingsRepository implements SettingsRepository {
  FakeSettingsRepository({bool initialShowGateway = true})
      : currentSettings = SystemSettings(showPaymentGatewayMobile: initialShowGateway);

  SystemSettings currentSettings;
  int getCalls = 0;
  int updateCalls = 0;

  @override
  Future<SystemSettings> getSettings({bool forceRefresh = false}) async {
    getCalls++;
    return currentSettings;
  }

  @override
  Future<SystemSettings> updateSettings({
    required bool showPaymentGatewayMobile,
    String? adminToken,
  }) async {
    updateCalls++;
    currentSettings = SystemSettings(showPaymentGatewayMobile: showPaymentGatewayMobile);
    return currentSettings;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('SystemSettings Entity & JSON parsing', () {
    test('parses public GET /api/v1/settings response correctly', () {
      final json = {
        'success': true,
        'data': {
          'show_payment_gateway_mobile': true,
        },
      };

      final settings = SystemSettings.fromJson(json);
      expect(settings.showPaymentGatewayMobile, isTrue);
      expect(settings.isFreePurchase, isFalse);
      expect(settings.freePurchases, isFalse);
    });

    test('parses public GET /api/v1/settings with show_payment_gateway_mobile=false (Free Purchases mode)', () {
      final json = {
        'success': true,
        'data': {
          'show_payment_gateway_mobile': false,
        },
      };

      final settings = SystemSettings.fromJson(json);
      expect(settings.showPaymentGatewayMobile, isFalse);
      expect(settings.isFreePurchase, isTrue);
      expect(settings.freePurchases, isTrue);
    });

    test('parses Admin key-value list format from GET /api/v1/admin/settings', () {
      final adminJson = {
        'success': true,
        'data': [
          {
            'id': 1,
            'key': 'show_payment_gateway_mobile',
            'value': '0',
            'created_at': '2026-09-07T11:00:00.000000Z',
            'updated_at': '2026-09-07T11:08:00.000000Z',
          }
        ],
      };

      final settings = SystemSettings.fromJson(adminJson);
      expect(settings.showPaymentGatewayMobile, isFalse);
      expect(settings.isFreePurchase, isTrue);
    });

    test('handles various truthy and falsy values robustly', () {
      expect(SystemSettings.fromJson({'show_payment_gateway_mobile': '1'}).showPaymentGatewayMobile, isTrue);
      expect(SystemSettings.fromJson({'show_payment_gateway_mobile': 1}).showPaymentGatewayMobile, isTrue);
      expect(SystemSettings.fromJson({'show_payment_gateway_mobile': 'true'}).showPaymentGatewayMobile, isTrue);
      expect(SystemSettings.fromJson({'show_payment_gateway_mobile': '0'}).showPaymentGatewayMobile, isFalse);
      expect(SystemSettings.fromJson({'show_payment_gateway_mobile': 0}).showPaymentGatewayMobile, isFalse);
      expect(SystemSettings.fromJson({'show_payment_gateway_mobile': 'false'}).showPaymentGatewayMobile, isFalse);
    });

    test('serializes to JSON format matching API requirements', () {
      const settings = SystemSettings(showPaymentGatewayMobile: false);
      final json = settings.toJson();
      expect(json['show_payment_gateway_mobile'], isFalse);
    });
  });

  group('ApiSettingsRepository Contracts & Network Tests', () {
    test('fetches settings from public GET /settings with X-Request-Id', () async {
      String? recordedMethod;
      String? recordedPath;
      String? recordedAuth;
      String? recordedRequestId;

      final mockClient = MockClient((request) async {
        recordedMethod = request.method;
        recordedPath = request.url.path;
        recordedAuth = request.headers['Authorization'];
        recordedRequestId = request.headers['X-Request-Id'];

        return http.Response(
          jsonEncode({
            'success': true,
            'data': {'show_payment_gateway_mobile': false},
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final apiClient = ApiClient(client: mockClient, logTraffic: false);
      final repo = ApiSettingsRepository(client: apiClient);

      final settings = await repo.getSettings(forceRefresh: true);
      expect(settings.showPaymentGatewayMobile, isFalse);
      expect(settings.isFreePurchase, isTrue);
      expect(recordedMethod, 'GET');
      expect(recordedPath, '/api/v1/settings');
      expect(recordedAuth, isNull); // Public, no auth
      expect(recordedRequestId, isNotNull);
    });

    test('updates settings via POST /admin/settings with payload', () async {
      String? recordedMethod;
      String? recordedPath;
      String? recordedBody;

      final mockClient = MockClient((request) async {
        recordedMethod = request.method;
        recordedPath = request.url.path;
        recordedBody = request.body;

        return http.Response(
          jsonEncode({
            'success': true,
            'message': 'Settings updated successfully.',
            'data': [
              {
                'id': 1,
                'key': 'show_payment_gateway_mobile',
                'value': '0',
              }
            ],
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final apiClient = ApiClient(client: mockClient, logTraffic: false);
      final repo = ApiSettingsRepository(client: apiClient);

      final updated = await repo.updateSettings(
        showPaymentGatewayMobile: false,
        adminToken: 'test_admin_token',
      );

      expect(updated.showPaymentGatewayMobile, isFalse);
      expect(updated.isFreePurchase, isTrue);
      expect(recordedMethod, 'POST');
      expect(recordedPath, '/api/v1/admin/settings');
      expect(recordedBody, contains('"show_payment_gateway_mobile":false'));
    });

    test('falls back gracefully to default on network failure', () async {
      final mockClient = MockClient((request) async {
        return http.Response('Internal error', 500);
      });

      final apiClient = ApiClient(client: mockClient, logTraffic: false);
      final repo = ApiSettingsRepository(client: apiClient);

      final settings = await repo.getSettings(forceRefresh: true);
      expect(settings.showPaymentGatewayMobile, isTrue);
    });
  });

  group('FreePurchasesController Unit Tests', () {
    test('initializes with default payment gateway enabled', () {
      final repo = FakeSettingsRepository();
      final controller = FreePurchasesController(repository: repo);
      addTearDown(controller.dispose);

      expect(controller.showPaymentGatewayMobile, isTrue);
      expect(controller.isFreePurchase, isFalse);
      expect(controller.freePurchases, isFalse);
      expect(controller.isLoading, isFalse);
    });

    test('loads settings and notifies listeners', () async {
      final repo = FakeSettingsRepository(initialShowGateway: false);
      final controller = FreePurchasesController(repository: repo);
      addTearDown(controller.dispose);

      var notified = false;
      controller.addListener(() => notified = true);

      await controller.load();

      expect(notified, isTrue);
      expect(controller.showPaymentGatewayMobile, isFalse);
      expect(controller.isFreePurchase, isTrue);
      expect(controller.freePurchases, isTrue);
    });

    test('setFreePurchases(true) updates gateway to false', () async {
      final repo = FakeSettingsRepository(initialShowGateway: true);
      final controller = FreePurchasesController(repository: repo);
      addTearDown(controller.dispose);

      final success = await controller.setFreePurchases(true);
      expect(success, isTrue);
      expect(controller.showPaymentGatewayMobile, isFalse);
      expect(controller.isFreePurchase, isTrue);
      expect(repo.updateCalls, 1);
    });

    test('toggleFreePurchases toggles mode correctly', () async {
      final repo = FakeSettingsRepository(initialShowGateway: true);
      final controller = FreePurchasesController(repository: repo);
      addTearDown(controller.dispose);

      expect(controller.isFreePurchase, isFalse);
      await controller.toggleFreePurchases();
      expect(controller.isFreePurchase, isTrue);
      expect(controller.showPaymentGatewayMobile, isFalse);

      await controller.toggleFreePurchases();
      expect(controller.isFreePurchase, isFalse);
      expect(controller.showPaymentGatewayMobile, isTrue);
    });

    test('setLocalFreePurchase alters in-memory state without repository call', () {
      final repo = FakeSettingsRepository(initialShowGateway: true);
      final controller = FreePurchasesController(repository: repo);
      addTearDown(controller.dispose);

      var notified = false;
      controller.addListener(() => notified = true);

      controller.setLocalFreePurchase(true);
      expect(notified, isTrue);
      expect(controller.isFreePurchase, isTrue);
      expect(controller.showPaymentGatewayMobile, isFalse);
      expect(repo.updateCalls, 0);
    });
  });

  group('AppController Settings & Free Purchases Integration', () {
    test('AppController initializes and loads settings correctly', () async {
      final settingsRepo = FakeSettingsRepository(initialShowGateway: false);
      final prefRepo = FakeAppPreferencesRepository();
      final controller = AppController(
        preferencesRepository: prefRepo,
        settingsRepository: settingsRepo,
      );
      addTearDown(controller.dispose);

      await controller.initialize();

      expect(controller.showPaymentGatewayMobile, isFalse);
      expect(controller.isFreePurchase, isTrue);
      expect(controller.freePurchases, isTrue);
      expect(settingsRepo.getCalls, greaterThanOrEqualTo(1));
    });

    test('AppController toggleFreePurchases updates state and notifies', () async {
      final settingsRepo = FakeSettingsRepository(initialShowGateway: true);
      final prefRepo = FakeAppPreferencesRepository();
      final controller = AppController(
        preferencesRepository: prefRepo,
        settingsRepository: settingsRepo,
      );
      addTearDown(controller.dispose);

      await controller.initialize();
      expect(controller.isFreePurchase, isFalse);

      var notified = false;
      controller.addListener(() => notified = true);

      await controller.toggleFreePurchases();
      expect(notified, isTrue);
      expect(controller.isFreePurchase, isTrue);
      expect(controller.showPaymentGatewayMobile, isFalse);
    });

    test('AppController setFreePurchasesLocal updates locally', () async {
      final settingsRepo = FakeSettingsRepository(initialShowGateway: true);
      final prefRepo = FakeAppPreferencesRepository();
      final controller = AppController(
        preferencesRepository: prefRepo,
        settingsRepository: settingsRepo,
      );
      addTearDown(controller.dispose);

      var notified = false;
      controller.addListener(() => notified = true);

      controller.setFreePurchasesLocal(true);
      expect(notified, isTrue);
      expect(controller.isFreePurchase, isTrue);
      expect(controller.showPaymentGatewayMobile, isFalse);
    });
  });
}
