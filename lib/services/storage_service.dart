import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const String _deviceTokenKey = 'device_token';
  static const String _deviceCodeKey = 'device_code';
  static const String _deviceLocationKey = 'device_location';
  static const String _deviceIdKey = 'device_id';
  static const String _deviceIdOnlyKey = 'device_id_only';
  static const String _adminTokenKey = 'admin_token';
  static const String _adminIdKey = 'admin_id';
  static const String _adminEmailKey = 'admin_email';
  static const String _adminRoleKey = 'admin_role';
  static const String _kioskModeKey = 'kiosk_mode_enabled';

  Future<void> saveDeviceToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_deviceTokenKey, token);
  }

  Future<String?> getDeviceToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_deviceTokenKey);
  }

  Future<void> saveDeviceId(int id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_deviceIdOnlyKey, id);
  }

  Future<int?> getDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_deviceIdOnlyKey);
  }

  Future<void> saveDeviceInfo(int id, String code, String location) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_deviceIdKey, id);
    await prefs.setString(_deviceCodeKey, code);
    await prefs.setString(_deviceLocationKey, location);
  }

  Future<Map<String, dynamic>?> getDeviceInfo() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getInt(_deviceIdKey);
    final code = prefs.getString(_deviceCodeKey);
    final location = prefs.getString(_deviceLocationKey);

    if (id != null && code != null && location != null) {
      return {
        'id': id,
        'code': code,
        'location': location,
      };
    }
    return null;
  }

  Future<void> clearDeviceData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_deviceTokenKey);
    await prefs.remove(_deviceCodeKey);
    await prefs.remove(_deviceLocationKey);
    await prefs.remove(_deviceIdKey);
    await prefs.remove(_deviceIdOnlyKey);
    await prefs.remove(_kioskModeKey);
  }

  Future<bool> isDeviceActivated() async {
    final deviceId = await getDeviceId();
    return deviceId != null;
  }

  Future<void> saveAdminToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_adminTokenKey, token);
  }

  Future<String?> getAdminToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_adminTokenKey);
  }

  Future<void> saveAdminInfo(int id, String email, String role) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_adminIdKey, id);
    await prefs.setString(_adminEmailKey, email);
    await prefs.setString(_adminRoleKey, role);
  }

  Future<Map<String, dynamic>?> getAdminInfo() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getInt(_adminIdKey);
    final email = prefs.getString(_adminEmailKey);
    final role = prefs.getString(_adminRoleKey);

    if (id != null && email != null && role != null) {
      return {
        'id': id,
        'email': email,
        'role': role,
      };
    }
    return null;
  }

  Future<void> clearAdminData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_adminTokenKey);
    await prefs.remove(_adminIdKey);
    await prefs.remove(_adminEmailKey);
    await prefs.remove(_adminRoleKey);
  }

  Future<bool> isAdminAuthenticated() async {
    final token = await getAdminToken();
    return token != null && token.isNotEmpty;
  }

  Future<void> setKioskMode(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kioskModeKey, enabled);
  }

  Future<bool> isKioskModeEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kioskModeKey) ?? false;
  }
}
