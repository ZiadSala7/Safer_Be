import 'dart:async';
import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../../../core/network/token_store.dart';
import '../data/datasources/device_local_store.dart';
import '../data/datasources/notification_store.dart';
import '../data/repositories/api_notifications_repository.dart';
import '../domain/entities/device_token.dart';
import '../domain/entities/notification_payload.dart';
import '../domain/repositories/notifications_repository.dart';
import 'notification_router.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp();
    }
  } catch (_) {}
  debugPrint('[PushBackground] Handling message id: ${message.messageId} data: ${message.data}');
}

class NotificationService {
  NotificationService._({
    NotificationsRepository? repository,
    DeviceLocalStore? localStore,
    TokenStore? tokenStore,
  }) : _repository = repository ?? ApiNotificationsRepository(),
       _localStore = localStore ?? DeviceLocalStore(),
       _tokenStore = tokenStore ?? TokenStore();

  static final NotificationService instance = NotificationService._();

  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  final NotificationsRepository _repository;
  final DeviceLocalStore _localStore;
  final TokenStore _tokenStore;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;
  static const String _channelId = 'safer_be_notifications';
  static const String _channelName = 'Safer Be Notifications';
  static const String _channelDescription =
      'Travel alerts, booking confirmations, and special offers from Safer Be';

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    try {
      const androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const darwinSettings = DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );
      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: darwinSettings,
      );

      await _localNotifications.initialize(
        settings: initSettings,
        onDidReceiveNotificationResponse: (response) {
          final payloadStr = response.payload;
          if (payloadStr != null && payloadStr.isNotEmpty) {
            try {
              final map = jsonDecode(payloadStr) as Map<String, dynamic>;
              final payload = NotificationPayload.fromDataMap(map);
              NotificationRouter.route(payload, navigatorKey: navigatorKey);
            } catch (e) {
              debugPrint('[NotificationService] Error decoding notification response payload: $e');
            }
          }
        },
      );

      // Create Android Notification Channel
      const androidChannel = AndroidNotificationChannel(
        _channelId,
        _channelName,
        description: _channelDescription,
        importance: Importance.max,
      );

      final androidPlugin = _localNotifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      await androidPlugin?.createNotificationChannel(androidChannel);

      // Set iOS foreground options
      await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      // Foreground FCM Listener
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint('[FCM Foreground] Message received: ${message.messageId}');
        _showForegroundNotification(message);
      });

      // Notification tap when app was in background
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        debugPrint('[FCM onMessageOpenedApp] Message clicked: ${message.messageId}');
        final payload = NotificationPayload.fromRemoteMessage(message);
        unawaited(NotificationStore.saveNotification(
          StoredNotification(
            id: message.messageId ?? DateTime.now().millisecondsSinceEpoch.toString(),
            title: message.notification?.title ?? 'Safer Be',
            body: message.notification?.body ?? '',
            type: message.data['type']?.toString() ?? '',
            timestamp: message.sentTime ?? DateTime.now(),
            isRead: true,
            payload: payload,
          ),
        ));
        NotificationRouter.route(payload, navigatorKey: navigatorKey);
      });

      // Listen for token refresh
      FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
        debugPrint('[FCM TokenRefresh] New token: ${newToken.substring(0, (newToken.length > 10 ? 10 : newToken.length))}...');
        _onTokenRefreshed(newToken);
      });

      // Cold start handling
      final initialMessage =
          await FirebaseMessaging.instance.getInitialMessage();
      if (initialMessage != null) {
        debugPrint('[FCM InitialMessage] Cold start message detected: ${initialMessage.messageId}');
        final payload = NotificationPayload.fromRemoteMessage(initialMessage);
        unawaited(NotificationStore.saveNotification(
          StoredNotification(
            id: initialMessage.messageId ?? DateTime.now().millisecondsSinceEpoch.toString(),
            title: initialMessage.notification?.title ?? 'Safer Be',
            body: initialMessage.notification?.body ?? '',
            type: initialMessage.data['type']?.toString() ?? '',
            timestamp: initialMessage.sentTime ?? DateTime.now(),
            isRead: true,
            payload: payload,
          ),
        ));
        WidgetsBinding.instance.addPostFrameCallback((_) {
          NotificationRouter.route(payload, navigatorKey: navigatorKey);
        });
      }

      unawaited(NotificationStore.updateUnreadCount());
    } catch (e) {
      debugPrint('[NotificationService] Initialization error (may occur in tests/desktop): $e');
    }
  }

  Future<void> _showForegroundNotification(RemoteMessage message) async {
    final notification = message.notification;
    final title = notification?.title ?? 'Safer Be';
    final body = notification?.body ?? '';

    final payload = NotificationPayload.fromRemoteMessage(message);
    unawaited(NotificationStore.saveNotification(
      StoredNotification(
        id: message.messageId ?? DateTime.now().millisecondsSinceEpoch.toString(),
        title: title,
        body: body,
        type: message.data['type']?.toString() ?? '',
        timestamp: message.sentTime ?? DateTime.now(),
        isRead: false,
        payload: payload,
      ),
    ));

    final androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDescription,
      importance: Importance.max,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    final notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    final payloadStr = jsonEncode(message.data);
    await _localNotifications.show(
      id: message.hashCode,
      title: title,
      body: body,
      notificationDetails: notificationDetails,
      payload: payloadStr,
    );
  }

  Future<bool> requestOsPermission() async {
    try {
      final settings = await FirebaseMessaging.instance.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      final granted =
          settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional;
      debugPrint('[NotificationService] OS Permission granted: $granted');
      return granted;
    } catch (e) {
      debugPrint('[NotificationService] Request permission error: $e');
      return false;
    }
  }

  Future<bool> enablePush({bool promptOsPermission = true}) async {
    if (promptOsPermission) {
      final hasOsPermission = await requestOsPermission();
      if (!hasOsPermission) {
        debugPrint('[NotificationService] OS notification permission was denied.');
        return false;
      }
    }

    // 1. Record business consent on API
    final consentUpdated =
        await _repository.updatePushNotificationConsent(true);
    if (!consentUpdated) {
      debugPrint('[NotificationService] Failed to update push notification consent.');
      return false;
    }

    // 2. Fetch FCM registration token
    try {
      final fcmToken = await FirebaseMessaging.instance.getToken();
      if (fcmToken != null && fcmToken.isNotEmpty) {
        await _registerDeviceWithBackend(fcmToken);
      }
    } catch (e) {
      debugPrint('[NotificationService] FCM getToken error: $e');
    }

    return true;
  }

  Future<bool> disablePush() async {
    final consentUpdated =
        await _repository.updatePushNotificationConsent(false);
    return consentUpdated;
  }

  Future<void> unregisterCurrentDevice() async {
    try {
      final rowId = await _localStore.readDeviceRowId();
      if (rowId != null) {
        await _repository.unregisterDevice(rowId);
      }
    } catch (e) {
      debugPrint('[NotificationService] unregisterCurrentDevice error: $e');
    } finally {
      await _localStore.clearAll();
    }
  }

  Future<void> syncDeviceRegistrationOnLogin({
    required bool pushNotificationConsent,
  }) async {
    if (!pushNotificationConsent) return;
    try {
      final fcmToken = await FirebaseMessaging.instance.getToken();
      if (fcmToken != null && fcmToken.isNotEmpty) {
        await _registerDeviceWithBackend(fcmToken);
      }
    } catch (e) {
      debugPrint('[NotificationService] syncDeviceRegistrationOnLogin error: $e');
    }
  }

  Future<DeviceToken?> _registerDeviceWithBackend(String token) async {
    try {
      String appVersion = '1.2.1';
      try {
        final info = await PackageInfo.fromPlatform();
        appVersion = info.version;
      } catch (_) {}

      final platform =
          defaultTargetPlatform == TargetPlatform.iOS ? 'ios' : 'android';

      final deviceToken = await _repository.registerDevice(
        token: token,
        platform: platform,
        appVersion: appVersion,
      );

      await _localStore.writeDeviceRowId(deviceToken.id);
      await _localStore.writeCachedToken(token);
      debugPrint('[NotificationService] Device registered with id: ${deviceToken.id}');
      return deviceToken;
    } catch (e) {
      debugPrint('[NotificationService] Failed to register device: $e');
      return null;
    }
  }

  Future<void> _onTokenRefreshed(String newToken) async {
    final hasSession = (await _tokenStore.read())?.isNotEmpty ?? false;
    if (hasSession) {
      await _registerDeviceWithBackend(newToken);
    }
  }

  Future<List<DeviceToken>> listDevices() => _repository.listDevices();

  Future<bool> deleteDevice(int id) => _repository.unregisterDevice(id);

  Future<bool> updateMarketingConsent(bool consent) =>
      _repository.updateMarketingConsent(consent);
}
