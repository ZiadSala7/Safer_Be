import '../entities/system_settings.dart';

abstract interface class SettingsRepository {
  /// Fetches system settings from `/api/v1/settings`.
  ///
  /// Uses cached value when available unless [forceRefresh] is true.
  Future<SystemSettings> getSettings({bool forceRefresh = false});

  /// Updates system settings on the admin endpoint `/api/v1/admin/settings`.
  ///
  /// Requires admin authentication (or [adminToken]).
  Future<SystemSettings> updateSettings({
    required bool showPaymentGatewayMobile,
    String? adminToken,
  });
}
