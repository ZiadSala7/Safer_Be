import '../entities/user_profile.dart';

abstract interface class ProfileRepository {
  UserProfile guest();
  Future<UserProfile> getProfile();
  Future<UserProfile> updateProfile({
    String? name,
    String? email,
    String? phone,
    String? preferredLocale,
  });
  Future<Map<String, dynamic>> sendOtp({
    required String phone,
    String purpose = 'verify',
  });
  Future<bool> verifyOtp({
    required String phone,
    required String code,
    String purpose = 'verify',
  });
  Future<void> deleteAccount();
}
