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

  bool get isEmailVerified => emailVerifiedAt != null && emailVerifiedAt!.isNotEmpty;
  bool get isPhoneVerified => phoneVerifiedAt != null && phoneVerifiedAt!.isNotEmpty;

  factory UserProfile.fromJson(dynamic json, {bool isGuest = false}) {
    final data = apiData(json);
    final map = data is Map ? data : (json is Map ? json : const {});
    return UserProfile(
      isGuest: isGuest,
      id: readNumber(map, ['id']).toInt(),
      name: readText(map, ['name', 'full_name']),
      email: readText(map, ['email']),
      phone: readText(map, ['phone']),
      emailVerifiedAt: readText(map, ['email_verified_at']),
      phoneVerifiedAt: readText(map, ['phone_verified_at']),
      preferredLocale: readText(map, ['preferred_locale'], 'en'),
    );
  }
}
