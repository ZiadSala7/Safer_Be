import '../../../../core/network/api_client.dart';
import '../../../../core/network/json_read.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/repositories/profile_repository.dart';

class ApiProfileRepository implements ProfileRepository {
  ApiProfileRepository({ApiClient? client}) : _client = client ?? ApiClient();

  final ApiClient _client;

  @override
  UserProfile guest() => const UserProfile(isGuest: true);

  @override
  Future<UserProfile> getProfile() async {
    final response = await _client.get('/auth/user');
    return UserProfile.fromJson(response);
  }

  @override
  Future<UserProfile> updateProfile({
    String? name,
    String? email,
    String? phone,
    String? preferredLocale,
  }) async {
    final body = <String, dynamic>{};
    if (name != null && name.isNotEmpty) body['name'] = name;
    if (email != null && email.isNotEmpty) body['email'] = email;
    if (phone != null && phone.isNotEmpty) body['phone'] = phone;
    if (preferredLocale != null && preferredLocale.isNotEmpty) {
      body['preferred_locale'] = preferredLocale;
    }

    final response = await _client.put('/auth/profile', body: body);
    final data = apiData(response);
    final userMap = data is Map && data['user'] is Map
        ? data['user']
        : (data is Map ? data : response);
    return UserProfile.fromJson(userMap);
  }

  @override
  Future<Map<String, dynamic>> sendOtp({
    required String phone,
    String purpose = 'verify',
  }) async {
    final response = await _client.post(
      '/auth/phone/send-otp',
      body: {'phone': phone, 'purpose': purpose},
    );
    final data = apiData(response);
    return data is Map ? Map<String, dynamic>.from(data) : (response is Map ? Map<String, dynamic>.from(response) : {});
  }

  @override
  Future<bool> verifyOtp({
    required String phone,
    required String code,
    String purpose = 'verify',
  }) async {
    final response = await _client.post(
      '/auth/phone/verify-otp',
      body: {'phone': phone, 'code': code, 'purpose': purpose},
    );
    final data = apiData(response);
    if (data is Map) {
      return data['verified'] == true || readText(data, ['status']) == 'verified';
    }
    return response is Map && (response['success'] == true);
  }

  @override
  Future<void> deleteAccount() async {
    try {
      await _client.delete('/auth/user');
    } catch (_) {
      try {
        await _client.delete('/auth/profile');
      } catch (_) {
        // Fallback
      }
    }
  }
}
