import 'package:flutter_test/flutter_test.dart';
import 'package:safer_be_project/app/app_controller.dart';
import 'package:safer_be_project/features/auth/domain/entities/auth_user.dart';
import 'package:safer_be_project/features/auth/domain/repositories/auth_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockAuthRepository implements AuthRepository {
  bool logoutCalled = false;

  @override
  Future<void> logout() async {
    logoutCalled = true;
  }

  @override
  Future<void> deleteAccount() async {
    logoutCalled = true;
  }

  @override
  Future<AuthUser> login(String email, String password) async =>
      const AuthUser(name: 'Test', email: 'test@example.com');

  @override
  Future<AuthUser> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
  }) async => const AuthUser(name: 'Test', email: 'test@example.com');

  @override
  Future<void> forgotPassword(String email) async {}

  @override
  Future<void> resetPassword({
    required String token,
    required String email,
    required String password,
    required String passwordConfirmation,
  }) async {}

  @override
  Future<AuthUser> me() async =>
      const AuthUser(name: 'Test', email: 'test@example.com');

  @override
  Future<bool> hasSession() async => true;

  @override
  Future<AuthUser?> readCachedUser() async => null;

  @override
  Future<void> writeCachedUser(AuthUser user) async {}
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({
      'registered_device_row_id': 88,
      'access_token': 'active_token',
    });
  });

  test('signOut clears device registration and revokes session', () async {
    final authRepo = MockAuthRepository();
    final controller = AppController(authRepository: authRepo);
    controller.signedIn(const AuthUser(name: 'User', email: 'user@test.com'));

    expect(controller.isGuest, isFalse);

    await controller.signOut();

    expect(authRepo.logoutCalled, isTrue);
    expect(controller.isGuest, isTrue);
    expect(controller.user, isNull);

    // Verify stored device id is cleared
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getInt('registered_device_row_id'), isNull);
  });
}
