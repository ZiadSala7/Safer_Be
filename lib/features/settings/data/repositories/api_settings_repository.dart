import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/utils/guid_generator.dart';
import '../../domain/entities/system_settings.dart';
import '../../domain/repositories/settings_repository.dart';

/// Implementation of [SettingsRepository] that fetches and updates system settings
/// according to the System Settings API specification.
///
/// Features:
/// - Public `GET /api/v1/settings` (No Bearer token required).
/// - Protected `POST /api/v1/admin/settings` with Bearer token authentication.
/// - In-memory and asynchronous persistent caching via [SharedPreferences]
///   ensuring instant startup availability and graceful offline resilience.
/// - Request correlation tracing using RFC 4122 v4 GUID.
class ApiSettingsRepository implements SettingsRepository {
  ApiSettingsRepository({
    ApiClient? client,
  }) : _client = client ?? ApiClient();

  final ApiClient _client;

  static const String _cacheKey = 'safer_be_setting_show_payment_gateway_mobile';

  SystemSettings? _memoryCache;

  @override
  Future<SystemSettings> getSettings({bool forceRefresh = false}) async {
    // 1. Return in-memory cache if available and forceRefresh is false
    if (!forceRefresh && _memoryCache != null) {
      return _memoryCache!;
    }

    // 2. Hydrate from local persistent cache if memory cache is not yet set
    if (_memoryCache == null) {
      final cachedBool = await _readCachedBool();
      if (cachedBool != null) {
        _memoryCache = SystemSettings(showPaymentGatewayMobile: cachedBool);
        if (!forceRefresh) {
          return _memoryCache!;
        }
      }
    }

    // 3. Request fresh settings from API
    try {
      final json = await _client.get(
        '/settings',
        authenticated: false,
        headers: {'X-Request-Id': generateGuid()},
      );

      final settings = SystemSettings.fromJson(json);
      _memoryCache = settings;
      await _writeCachedBool(settings.showPaymentGatewayMobile);
      return settings;
    } catch (error) {
      debugPrint('[ApiSettingsRepository] Failed to fetch settings: $error');

      // Graceful fallback to cached value or default
      if (_memoryCache != null) {
        return _memoryCache!;
      }

      final cachedBool = await _readCachedBool();
      if (cachedBool != null) {
        final fallback = SystemSettings(showPaymentGatewayMobile: cachedBool);
        _memoryCache = fallback;
        return fallback;
      }

      return SystemSettings.defaults;
    }
  }

  @override
  Future<SystemSettings> updateSettings({
    required bool showPaymentGatewayMobile,
    String? adminToken,
  }) async {
    final body = {
      'show_payment_gateway_mobile': showPaymentGatewayMobile,
    };

    final json = await _client.post(
      '/admin/settings',
      body: body,
      authenticated: adminToken == null,
      customToken: adminToken,
      headers: {'X-Request-Id': generateGuid()},
    );

    var updated = SystemSettings.fromJson(json);
    // If response does not mirror the exact boolean, guarantee state reflects requested value
    if (updated.showPaymentGatewayMobile != showPaymentGatewayMobile) {
      updated = SystemSettings(showPaymentGatewayMobile: showPaymentGatewayMobile);
    }

    _memoryCache = updated;
    await _writeCachedBool(updated.showPaymentGatewayMobile);
    return updated;
  }

  Future<bool?> _readCachedBool() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_cacheKey);
    } catch (_) {
      return null;
    }
  }

  Future<void> _writeCachedBool(bool value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_cacheKey, value);
    } catch (_) {
      // Non-fatal cache failure
    }
  }
}
