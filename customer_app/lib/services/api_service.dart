import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:4000',
  );

  static Future<Map<String, dynamic>> requestOtp(String mobile) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/auth/request-otp'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'mobile': mobile,
        'role': 'CUSTOMER',
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(data['message'] ?? 'Unable to send OTP');
    }

    return Map<String, dynamic>.from(data);
  }

  static Future<Map<String, dynamic>> verifyOtp(
    String mobile,
    String otp,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/auth/verify-otp'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'mobile': mobile,
        'otp': otp,
        'role': 'CUSTOMER',
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(data['message'] ?? 'Invalid OTP');
    }

    final token = data['token'];

    if (token != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', token);
      await prefs.setString('mobile', mobile);
    }

    return Map<String, dynamic>.from(data);
  }

  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token') != null;
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('mobile');
  }
}
