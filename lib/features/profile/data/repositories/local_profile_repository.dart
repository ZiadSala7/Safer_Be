import '../../domain/entities/user_profile.dart';
import '../../domain/repositories/profile_repository.dart';

class LocalProfileRepository implements ProfileRepository {
  @override
  UserProfile guest() => const UserProfile(isGuest: true);

  @override
  Future<UserProfile> getProfile() async => guest();

  @override
  Future<UserProfile> updateProfile({
    String? name,
    String? email,
    String? phone,
    String? preferredLocale,
  }) async => guest();

  @override
  Future<Map<String, dynamic>> sendOtp({
    required String phone,
    String purpose = 'verify',
  }) async => {'success': true, 'message': 'OTP sent.'};

  @override
  Future<bool> verifyOtp({
    required String phone,
    required String code,
    String purpose = 'verify',
  }) async => true;

  @override
  Future<void> deleteAccount() async {}
}
