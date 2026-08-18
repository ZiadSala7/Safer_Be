import '../../../../core/network/api_client.dart';
import '../../../../core/network/json_read.dart';
import '../../../../core/network/token_store.dart';
import '../../domain/entities/auth_user.dart';
import '../../domain/repositories/auth_repository.dart';

class ApiAuthRepository implements AuthRepository {
  ApiAuthRepository({ApiClient? client, TokenStore? tokens})
    : _client = client ?? ApiClient(),
      _tokens = tokens ?? TokenStore();

  final ApiClient _client;
  final TokenStore _tokens;

  @override
  Future<AuthUser> login(String email, String password) async {
    final response = await _client.post(
      '/auth/login',
      body: {'email': email, 'password': password},
    );
    final data = Map<String, dynamic>.from(apiData(response) as Map);
    final token = readText(data, ['access_token', 'token']);
    if (token.isEmpty) throw const FormatException('Login token is missing.');
    await _tokens.write(token);
    final user = data['user'] is Map
        ? Map<String, dynamic>.from(data['user'])
        : data;
    final authUser = _user(user, email);
    await _tokens.writeUser(name: authUser.name, email: authUser.email);
    return authUser;
  }

  @override
  Future<AuthUser> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
  }) async {
    final response = await _client.post(
      '/auth/register',
      body: {
        'name': name,
        'email': email,
        'password': password,
        'password_confirmation': passwordConfirmation,
      },
    );
    final data = Map<String, dynamic>.from(apiData(response) as Map);
    final token = readText(data, ['access_token', 'token']);
    if (token.isNotEmpty) {
      await _tokens.write(token);
    }
    final user = data['user'] is Map
        ? Map<String, dynamic>.from(data['user'])
        : data;
    return _user(user, email);
  }

  @override
  Future<void> forgotPassword(String email) async {
    await _client.post('/auth/forgot-password', body: {'email': email});
  }

  @override
  Future<void> resetPassword({
    required String token,
    required String email,
    required String password,
    required String passwordConfirmation,
  }) async {
    await _client.post(
      '/auth/reset-password',
      body: {
        'token': token,
        'email': email,
        'password': password,
        'password_confirmation': passwordConfirmation,
      },
    );
  }

  @override
  Future<AuthUser> me() async {
    final data = Map<String, dynamic>.from(
      apiData(await _client.get('/auth/user')) as Map,
    );
    return _user(data);
  }

  @override
  Future<AuthUser?> readCachedUser() async {
    final cached = await _tokens.readUser();
    if (cached == null) return null;
    return AuthUser(name: cached['name']!, email: cached['email']!);
  }

  @override
  Future<void> writeCachedUser(AuthUser user) async {
    await _tokens.writeUser(name: user.name, email: user.email);
  }

  AuthUser _user(Map data, [String email = '']) => AuthUser(
    name: readText(data, ['name', 'full_name'], 'Safer Be traveler'),
    email: readText(data, ['email'], email),
  );

  @override
  Future<bool> hasSession() async =>
      (await _tokens.read())?.isNotEmpty ?? false;

  @override
  Future<void> logout() async {
    try {
      await _client.post('/auth/logout');
    } catch (_) {
      // A local logout must still succeed if the session already expired.
    } finally {
      await _tokens.clear();
    }
  }
}
