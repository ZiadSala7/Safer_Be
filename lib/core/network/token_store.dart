import 'package:shared_preferences/shared_preferences.dart';

class TokenStore {
  static const _tokenKey = 'access_token';
  static const _userNameKey = 'user_name';
  static const _userEmailKey = 'user_email';

  Future<String?> read() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getString(_tokenKey);
  }

  Future<void> write(String token) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_tokenKey, token);
  }

  Future<void> clear() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_tokenKey);
    await preferences.remove(_userNameKey);
    await preferences.remove(_userEmailKey);
  }

  Future<void> writeUser({required String name, required String email}) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_userNameKey, name);
    await preferences.setString(_userEmailKey, email);
  }

  Future<Map<String, String>?> readUser() async {
    final preferences = await SharedPreferences.getInstance();
    final name = preferences.getString(_userNameKey);
    final email = preferences.getString(_userEmailKey);
    if (name == null || email == null) return null;
    return {'name': name, 'email': email};
  }
}
