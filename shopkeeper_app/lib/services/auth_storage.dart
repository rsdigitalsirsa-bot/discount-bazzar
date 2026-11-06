import 'package:shared_preferences/shared_preferences.dart';

class AuthStorage {
  static const _tokenKey = 'shopkeeper_auth_token';
  static const _mobileKey = 'shopkeeper_mobile';
  static const _nameKey = 'shopkeeper_name';
  static const _roleKey = 'shopkeeper_role';

  static Future<void> saveSession({
    required String token,
    required String mobile,
    String? name,
    String? role,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(_tokenKey, token);
    await prefs.setString(_mobileKey, mobile);

    if (name != null) {
      await prefs.setString(_nameKey, name);
    }

    await prefs.setString(_roleKey, role ?? 'SHOPKEEPER');
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  static Future<String?> getMobile() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_mobileKey);
  }

  static Future<String?> getName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_nameKey);
  }

  static Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_mobileKey);
    await prefs.remove(_nameKey);
    await prefs.remove(_roleKey);
  }
}
