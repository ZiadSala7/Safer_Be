import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:safer_be_project/core/network/api_client.dart';
import 'package:safer_be_project/core/network/token_store.dart';
import 'package:safer_be_project/features/notifications/data/repositories/api_notifications_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({'access_token': 'test_sanctum_pat'});
  });

  group('ApiNotificationsRepository HTTP Contract Tests', () {
    test('updatePushNotificationConsent sends POST to /auth/push-notification-consent', () async {
      late http.Request captured;
      final mockClient = MockClient((request) async {
        captured = request;
        return http.Response(
          jsonEncode({
            'success': true,
            'message': 'Push notification consent updated.',
            'data': {
              'user': {
                'id': 10,
                'push_notification_consent': true,
                'push_notification_consent_at': '2026-09-19T20:30:00Z',
              },
            },
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final apiClient = ApiClient(client: mockClient, tokens: TokenStore());
      final repo = ApiNotificationsRepository(client: apiClient);

      final result = await repo.updatePushNotificationConsent(true);

      expect(result, isTrue);
      expect(captured.method, 'POST');
      expect(captured.url.path, '/api/v1/auth/push-notification-consent');
      expect(jsonDecode(captured.body), {'push_notification_consent': true});
      expect(captured.headers['Authorization'], 'Bearer test_sanctum_pat');
    });

    test('updateMarketingConsent sends POST to /auth/marketing-consent', () async {
      late http.Request captured;
      final mockClient = MockClient((request) async {
        captured = request;
        return http.Response(
          jsonEncode({
            'success': true,
            'message': 'Marketing consent updated.',
            'data': {
              'user': {'id': 10, 'marketing_consent': false},
            },
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final apiClient = ApiClient(client: mockClient, tokens: TokenStore());
      final repo = ApiNotificationsRepository(client: apiClient);

      final result = await repo.updateMarketingConsent(false);

      expect(result, isTrue);
      expect(captured.method, 'POST');
      expect(captured.url.path, '/api/v1/auth/marketing-consent');
      expect(jsonDecode(captured.body), {'marketing_consent': false});
    });

    test('registerDevice sends POST to /customer/devices with upsert response', () async {
      late http.Request captured;
      final mockClient = MockClient((request) async {
        captured = request;
        return http.Response(
          jsonEncode({
            'success': true,
            'data': {
              'id': 105,
              'platform': 'android',
              'device_id': 'unique-device-hardware-uuid',
              'app_version': '1.1.0',
              'token_hint': 'eX7m...98',
              'last_used_at': '2026-09-19T21:00:00Z',
              'created_at': '2026-09-19T20:00:00Z',
            },
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final apiClient = ApiClient(client: mockClient, tokens: TokenStore());
      final repo = ApiNotificationsRepository(client: apiClient);

      final device = await repo.registerDevice(
        token: 'full_raw_fcm_token_string',
        platform: 'android',
        deviceId: 'unique-device-hardware-uuid',
        appVersion: '1.1.0',
      );

      expect(captured.method, 'POST');
      expect(captured.url.path, '/api/v1/customer/devices');
      final body = jsonDecode(captured.body) as Map<String, dynamic>;
      expect(body['token'], 'full_raw_fcm_token_string');
      expect(body['platform'], 'android');
      expect(body['device_id'], 'unique-device-hardware-uuid');
      expect(body['app_version'], '1.1.0');

      expect(device.id, 105);
      expect(device.platform, 'android');
      expect(device.tokenHint, 'eX7m...98');
    });

    test('listDevices sends GET to /customer/devices and returns parsed list', () async {
      late http.Request captured;
      final mockClient = MockClient((request) async {
        captured = request;
        return http.Response(
          jsonEncode({
            'success': true,
            'data': [
              {
                'id': 101,
                'platform': 'android',
                'device_id': 'dev-1',
                'app_version': '1.1.0',
                'token_hint': 'tok1...',
              },
              {
                'id': 102,
                'platform': 'ios',
                'device_id': 'dev-2',
                'app_version': '1.1.0',
                'token_hint': 'tok2...',
              },
            ],
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final apiClient = ApiClient(client: mockClient, tokens: TokenStore());
      final repo = ApiNotificationsRepository(client: apiClient);

      final list = await repo.listDevices();

      expect(captured.method, 'GET');
      expect(captured.url.path, '/api/v1/customer/devices');
      expect(list.length, 2);
      expect(list[0].id, 101);
      expect(list[0].platform, 'android');
      expect(list[1].id, 102);
      expect(list[1].platform, 'ios');
    });

    test('unregisterDevice sends DELETE to /customer/devices/{id}', () async {
      late http.Request captured;
      final mockClient = MockClient((request) async {
        captured = request;
        return http.Response(
          jsonEncode({'success': true, 'message': 'Device removed'}),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final apiClient = ApiClient(client: mockClient, tokens: TokenStore());
      final repo = ApiNotificationsRepository(client: apiClient);

      final success = await repo.unregisterDevice(105);

      expect(success, isTrue);
      expect(captured.method, 'DELETE');
      expect(captured.url.path, '/api/v1/customer/devices/105');
    });

    test('unregisterDevice gracefully treats 404 (already deleted/not found) as success', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'error': 'device_not_found',
            'message': 'No device found for ID 999',
          }),
          404,
          headers: {'content-type': 'application/json'},
        );
      });

      final apiClient = ApiClient(client: mockClient, tokens: TokenStore());
      final repo = ApiNotificationsRepository(client: apiClient);

      // Must succeed according to Section 13 Logout specifications
      final success = await repo.unregisterDevice(999);
      expect(success, isTrue);
    });

    test('respondToApproval sends POST to /customer/approvals/{id}/respond', () async {
      late http.Request captured;
      final mockClient = MockClient((request) async {
        captured = request;
        return http.Response(
          jsonEncode({
            'success': true,
            'message': 'Approval response received.',
            'data': {
              'approval_id': 'appr-77',
              'decision': 'approved',
            },
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final apiClient = ApiClient(client: mockClient, tokens: TokenStore());
      final repo = ApiNotificationsRepository(client: apiClient);

      final ok = await repo.respondToApproval(
        approvalId: 'appr-77',
        approved: true,
        channel: 'mobile',
      );

      expect(ok, isTrue);
      expect(captured.method, 'POST');
      expect(captured.url.path, '/api/v1/customer/approvals/appr-77/respond');
      expect(jsonDecode(captured.body), {
        'approved': true,
        'channel': 'mobile',
      });
    });
  });
}
