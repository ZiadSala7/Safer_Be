import '../../../../core/network/json_read.dart';

class DeviceToken {
  const DeviceToken({
    required this.id,
    required this.platform,
    this.deviceId,
    this.appVersion,
    this.tokenHint,
    this.lastUsedAt,
    this.createdAt,
  });

  final int id;
  final String platform;
  final String? deviceId;
  final String? appVersion;
  final String? tokenHint;
  final String? lastUsedAt;
  final String? createdAt;

  factory DeviceToken.fromJson(Map<String, dynamic> json) {
    String? nullIfEmpty(String s) => s.isEmpty ? null : s;
    return DeviceToken(
      id: readNumber(json, ['id']).toInt(),
      platform: readText(json, ['platform'], 'android'),
      deviceId: nullIfEmpty(readText(json, ['device_id'])),
      appVersion: nullIfEmpty(readText(json, ['app_version'])),
      tokenHint: nullIfEmpty(readText(json, ['token_hint'])),
      lastUsedAt: nullIfEmpty(readText(json, ['last_used_at'])),
      createdAt: nullIfEmpty(readText(json, ['created_at'])),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'platform': platform,
    if (deviceId != null) 'device_id': deviceId,
    if (appVersion != null) 'app_version': appVersion,
    if (tokenHint != null) 'token_hint': tokenHint,
    if (lastUsedAt != null) 'last_used_at': lastUsedAt,
    if (createdAt != null) 'created_at': createdAt,
  };
}
