import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/repositories/onboarding_repository.dart';

class LocalOnboardingRepository implements OnboardingRepository {
  LocalOnboardingRepository({SharedPreferencesAsync? preferences})
    : _preferences = preferences ?? SharedPreferencesAsync();

  static const _completedKey = 'onboarding_completed_v1';
  final SharedPreferencesAsync _preferences;

  @override
  Future<bool> hasCompletedOnboarding() async =>
      await _preferences.getBool(_completedKey) ?? false;

  @override
  Future<void> completeOnboarding() =>
      _preferences.setBool(_completedKey, true);
}
