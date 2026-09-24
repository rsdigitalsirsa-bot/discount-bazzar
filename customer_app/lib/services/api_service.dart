import 'dart:convert';

import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl =
      'https://cuddly-engine-r76pv47xgv5jhp5v-4000.app.github.dev';

  static Future<Map<String, dynamic>> requestOtp({
    required String mobile,
    String role = 'CUSTOMER',
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/auth/request-otp'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'mobile': mobile, 'role': role}),
    );

    return _decode(response);
  }

  static Future<Map<String, dynamic>> verifyOtp({
    required String mobile,
    required String otp,
    String role = 'CUSTOMER',
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/auth/verify-otp'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'mobile': mobile, 'otp': otp, 'role': role}),
    );

    return _decode(response);
  }

  static Map<String, dynamic> _decode(http.Response response) {
    Map<String, dynamic> data;

    try {
      data = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      throw Exception('Invalid server response');
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(data['message']?.toString() ?? 'Request failed');
    }

    return data;
  }
}
