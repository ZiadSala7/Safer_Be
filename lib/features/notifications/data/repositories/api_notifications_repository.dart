import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/network/json_read.dart';
import '../../domain/entities/device_token.dart';
import '../../domain/repositories/notifications_repository.dart';

class ApiNotificationsRepository implements NotificationsRepository {
  ApiNotificationsRepository({ApiClient? client})
    : _client = client ?? ApiClient();

  final ApiClient _client;

  @override
  Future<bool> updatePushNotificationConsent(bool consent) async {
    final response = await _client.post(
      '/auth/push-notification-consent',
      body: {'push_notification_consent': consent},
    );
    if (response is Map && response['success'] == false) {
      return false;
    }
    return true;
  }

  @override
  Future<bool> updateMarketingConsent(bool consent) async {
    final response = await _client.post(
      '/auth/marketing-consent',
      body: {'marketing_consent': consent},
    );
    if (response is Map && response['success'] == false) {
      return false;
    }
    return true;
  }

  @override
  Future<DeviceToken> registerDevice({
    required String token,
    required String platform,
    String? deviceId,
    String? appVersion,
  }) async {
    final validPlatform = (platform.toLowerCase() == 'ios') ? 'ios' : 'android';
    final body = <String, dynamic>{
      'token': token,
      'platform': validPlatform,
    };
    if (deviceId != null && deviceId.trim().isNotEmpty) {
      body['device_id'] = deviceId.trim();
    }
    if (appVersion != null && appVersion.trim().isNotEmpty) {
      body['app_version'] = appVersion.trim();
    }

    final response = await _client.post('/customer/devices', body: body);
    final data = apiData(response);
    final map = data is Map ? Map<String, dynamic>.from(data) : (response is Map ? Map<String, dynamic>.from(response) : <String, dynamic>{});
    return DeviceToken.fromJson(map);
  }

  @override
  Future<List<DeviceToken>> listDevices() async {
    final response = await _client.get('/customer/devices');
    final data = apiData(response);
    final list = data is List
        ? data
        : (response is Map && response['data'] is List ? response['data'] as List : []);

    return list
        .whereType<Map>()
        .map((item) => DeviceToken.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  @override
  Future<bool> unregisterDevice(int deviceId) async {
    try {
      await _client.delete('/customer/devices/$deviceId');
      return true;
    } on ApiException catch (e) {
      // If 404, the device row is already gone or owned by another, which satisfies unregistering
      if (e.statusCode == 404) {
        return true;
      }
      rethrow;
    }
  }

  @override
  Future<bool> respondToApproval({
    required String approvalId,
    required bool approved,
    String? channel,
  }) async {
    final body = <String, dynamic>{
      'approved': approved,
      if (channel != null && channel.isNotEmpty) 'channel': channel,
    };
    final response = await _client.post(
      '/customer/approvals/$approvalId/respond',
      body: body,
    );
    if (response is Map && response['success'] == false) {
      return false;
    }
    return true;
  }
}
