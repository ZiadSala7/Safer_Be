import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/notification_payload.dart';

class StoredNotification {
  const StoredNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.timestamp,
    this.isRead = false,
    this.payload,
  });

  final String id;
  final String title;
  final String body;
  final String type;
  final DateTime timestamp;
  final bool isRead;
  final NotificationPayload? payload;

  StoredNotification copyWith({
    String? id,
    String? title,
    String? body,
    String? type,
    DateTime? timestamp,
    bool? isRead,
    NotificationPayload? payload,
  }) => StoredNotification(
    id: id ?? this.id,
    title: title ?? this.title,
    body: body ?? this.body,
    type: type ?? this.type,
    timestamp: timestamp ?? this.timestamp,
    isRead: isRead ?? this.isRead,
    payload: payload ?? this.payload,
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'title': title,
    'body': body,
    'type': type,
    'timestamp': timestamp.toIso8601String(),
    'is_read': isRead,
    if (payload != null) 'payload': payload!.toMap(),
  };

  factory StoredNotification.fromMap(Map<String, dynamic> map) {
    NotificationPayload? parsedPayload;
    if (map['payload'] is Map) {
      parsedPayload = NotificationPayload.fromDataMap(
        Map<String, dynamic>.from(map['payload'] as Map),
        title: map['title']?.toString(),
        body: map['body']?.toString(),
      );
    }
    return StoredNotification(
      id: map['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
      title: map['title']?.toString() ?? '',
      body: map['body']?.toString() ?? '',
      type: map['type']?.toString() ?? '',
      timestamp: DateTime.tryParse(map['timestamp']?.toString() ?? '') ?? DateTime.now(),
      isRead: map['is_read'] == true,
      payload: parsedPayload,
    );
  }
}

class NotificationStore {
  static const String _storageKey = 'safer_be_stored_notifications';
  static final ValueNotifier<int> unreadCountNotifier = ValueNotifier<int>(0);

  static Future<List<StoredNotification>> getNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final listJson = prefs.getStringList(_storageKey);
      if (listJson == null || listJson.isEmpty) {
        return const [];
      }
      final items = listJson
          .map((item) => StoredNotification.fromMap(jsonDecode(item) as Map<String, dynamic>))
          .toList();
      items.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return items;
    } catch (e) {
      debugPrint('[NotificationStore] Error reading notifications: $e');
      return const [];
    }
  }

  static Future<void> saveNotification(StoredNotification notification) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = await getNotifications();
      // Remove any existing notification with the same ID to avoid duplicates
      final updated = list.where((n) => n.id != notification.id).toList();
      updated.insert(0, notification);
      final encoded = updated.map((n) => jsonEncode(n.toMap())).toList();
      await prefs.setStringList(_storageKey, encoded);
      await updateUnreadCount();
    } catch (e) {
      debugPrint('[NotificationStore] Error saving notification: $e');
    }
  }

  static Future<void> markAsRead(String id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = await getNotifications();
      final updated = list.map((n) => n.id == id ? n.copyWith(isRead: true) : n).toList();
      final encoded = updated.map((n) => jsonEncode(n.toMap())).toList();
      await prefs.setStringList(_storageKey, encoded);
      await updateUnreadCount();
    } catch (e) {
      debugPrint('[NotificationStore] Error marking notification as read: $e');
    }
  }

  static Future<void> markAllAsRead() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = await getNotifications();
      final updated = list.map((n) => n.copyWith(isRead: true)).toList();
      final encoded = updated.map((n) => jsonEncode(n.toMap())).toList();
      await prefs.setStringList(_storageKey, encoded);
      await updateUnreadCount();
    } catch (e) {
      debugPrint('[NotificationStore] Error marking all notifications as read: $e');
    }
  }

  static Future<void> deleteNotification(String id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = await getNotifications();
      final updated = list.where((n) => n.id != id).toList();
      final encoded = updated.map((n) => jsonEncode(n.toMap())).toList();
      await prefs.setStringList(_storageKey, encoded);
      await updateUnreadCount();
    } catch (e) {
      debugPrint('[NotificationStore] Error deleting notification: $e');
    }
  }

  static Future<void> clearAll() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_storageKey);
      unreadCountNotifier.value = 0;
    } catch (e) {
      debugPrint('[NotificationStore] Error clearing notifications: $e');
    }
  }

  static Future<void> updateUnreadCount() async {
    try {
      final list = await getNotifications();
      unreadCountNotifier.value = list.where((n) => !n.isRead).length;
    } catch (_) {}
  }
}
