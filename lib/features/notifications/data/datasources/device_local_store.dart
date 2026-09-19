import 'package:shared_preferences/shared_preferences.dart';

class DeviceLocalStore {
  static const _deviceRowIdKey = 'registered_device_row_id';
  static const _fcmTokenKey = 'cached_fcm_token';

  Future<int?> readDeviceRowId() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getInt(_deviceRowIdKey);
  }

  Future<void> writeDeviceRowId(int id) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setInt(_deviceRowIdKey, id);
  }

  Future<void> clearDeviceRowId() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_deviceRowIdKey);
  }

  Future<String?> readCachedToken() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getString(_fcmTokenKey);
  }

  Future<void> writeCachedToken(String token) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_fcmTokenKey, token);
  }

  Future<void> clearAll() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_deviceRowIdKey);
    await preferences.remove(_fcmTokenKey);
  }
}
