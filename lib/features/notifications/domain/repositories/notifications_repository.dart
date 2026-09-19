import '../entities/device_token.dart';

abstract interface class NotificationsRepository {
  Future<bool> updatePushNotificationConsent(bool consent);
  Future<bool> updateMarketingConsent(bool consent);
  Future<DeviceToken> registerDevice({
    required String token,
    required String platform,
    String? deviceId,
    String? appVersion,
  });
  Future<List<DeviceToken>> listDevices();
  Future<bool> unregisterDevice(int deviceId);
  Future<bool> respondToApproval({
    required String approvalId,
    required bool approved,
    String? channel,
  });
}
