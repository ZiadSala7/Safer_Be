import '../entities/auth_user.dart';

abstract interface class AuthRepository {
  Future<AuthUser> login(String email, String password);
  Future<AuthUser> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
  });
  Future<void> forgotPassword(String email);
  Future<void> resetPassword({
    required String token,
    required String email,
    required String password,
    required String passwordConfirmation,
  });
  Future<AuthUser> me();
  Future<void> logout();
  Future<bool> hasSession();
  Future<AuthUser?> readCachedUser();
  Future<void> writeCachedUser(AuthUser user);
}
