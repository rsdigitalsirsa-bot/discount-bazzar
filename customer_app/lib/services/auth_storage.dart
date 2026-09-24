import 'package:shared_preferences/shared_preferences.dart';

class AuthStorage {
  static const _tokenKey = 'auth_token';
  static const _mobileKey = 'auth_mobile';
  static const _roleKey = 'auth_role';
  static const _nameKey = 'auth_name';
  static const _emailKey = 'auth_email';
  static const _cityKey = 'auth_city';
  static const _photoKey = 'auth_photo';

  static Future<void> saveSession({
    required String token,
    required String mobile,
    required String role,
    String? name,
    String? email,
    String? city,
    String? photo,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(_tokenKey, token);
    await prefs.setString(_mobileKey, mobile);
    await prefs.setString(_roleKey, role);

    if (name != null) await prefs.setString(_nameKey, name);
    if (email != null) await prefs.setString(_emailKey, email);
    if (city != null) await prefs.setString(_cityKey, city);
    if (photo != null) await prefs.setString(_photoKey, photo);
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  static Future<String?> getMobile() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_mobileKey);
  }

  static Future<String?> getRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_roleKey);
  }

  static Future<String?> getName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_nameKey);
  }

  static Future<String?> getEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_emailKey);
  }

  static Future<String?> getCity() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_cityKey);
  }

  static Future<String?> getPhoto() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_photoKey);
  }

  static Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  static Future<void> updateProfile({
    String? name,
    String? email,
    String? city,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    if (name != null) {
      await prefs.setString(_nameKey, name);
    }

    if (email != null) {
      await prefs.setString(_emailKey, email);
    }

    if (city != null) {
      await prefs.setString(_cityKey, city);
    }
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove(_tokenKey);
    await prefs.remove(_mobileKey);
    await prefs.remove(_roleKey);
    await prefs.remove(_nameKey);
    await prefs.remove(_emailKey);
    await prefs.remove(_cityKey);
    await prefs.remove(_photoKey);
  }
}
