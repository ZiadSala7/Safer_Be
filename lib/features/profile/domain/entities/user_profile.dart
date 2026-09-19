import '../../../../core/network/json_read.dart';

class UserProfile {
  const UserProfile({
    required this.isGuest,
    this.id,
    this.name,
    this.email,
    this.phone,
    this.emailVerifiedAt,
    this.phoneVerifiedAt,
    this.preferredLocale = 'en',
    this.points = 0,
    this.pushNotificationConsent = false,
    this.pushNotificationConsentAt,
    this.marketingConsent = false,
    this.marketingConsentAt,
  });

  final bool isGuest;
  final int? id;
  final String? name;
  final String? email;
  final String? phone;
  final String? emailVerifiedAt;
  final String? phoneVerifiedAt;
  final String preferredLocale;
  final int points;
  final bool pushNotificationConsent;
  final String? pushNotificationConsentAt;
  final bool marketingConsent;
  final String? marketingConsentAt;

  bool get isEmailVerified => emailVerifiedAt != null && emailVerifiedAt!.isNotEmpty;
  bool get isPhoneVerified => phoneVerifiedAt != null && phoneVerifiedAt!.isNotEmpty;

  UserProfile copyWith({
    bool? isGuest,
    int? id,
    String? name,
    String? email,
    String? phone,
    String? emailVerifiedAt,
    String? phoneVerifiedAt,
    String? preferredLocale,
    int? points,
    bool? pushNotificationConsent,
    String? pushNotificationConsentAt,
    bool? marketingConsent,
    String? marketingConsentAt,
  }) {
    return UserProfile(
      isGuest: isGuest ?? this.isGuest,
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      emailVerifiedAt: emailVerifiedAt ?? this.emailVerifiedAt,
      phoneVerifiedAt: phoneVerifiedAt ?? this.phoneVerifiedAt,
      preferredLocale: preferredLocale ?? this.preferredLocale,
      points: points ?? this.points,
      pushNotificationConsent:
          pushNotificationConsent ?? this.pushNotificationConsent,
      pushNotificationConsentAt:
          pushNotificationConsentAt ?? this.pushNotificationConsentAt,
      marketingConsent: marketingConsent ?? this.marketingConsent,
      marketingConsentAt: marketingConsentAt ?? this.marketingConsentAt,
    );
  }

  factory UserProfile.fromJson(dynamic json, {bool isGuest = false}) {
    final data = apiData(json);
    final map = data is Map ? data : (json is Map ? json : const {});
    final userMap = map['user'] is Map ? map['user'] as Map : map;
    return UserProfile(
      isGuest: isGuest,
      id: readNumber(userMap, ['id']).toInt(),
      name: readText(userMap, ['name', 'full_name']),
      email: readText(userMap, ['email']),
      phone: readText(userMap, ['phone']),
      emailVerifiedAt: readText(userMap, ['email_verified_at']),
      phoneVerifiedAt: readText(userMap, ['phone_verified_at']),
      preferredLocale: readText(userMap, ['preferred_locale'], 'en'),
      pushNotificationConsent: userMap['push_notification_consent'] == true,
      pushNotificationConsentAt:
          readText(userMap, ['push_notification_consent_at']),
      marketingConsent: userMap['marketing_consent'] == true,
      marketingConsentAt: readText(userMap, ['marketing_consent_at']),
    );
  }
}
