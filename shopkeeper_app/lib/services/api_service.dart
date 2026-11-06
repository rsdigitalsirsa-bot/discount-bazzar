import 'dart:convert';

import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl =
      'https://cuddly-engine-r76pv47xgv5jhp5v-4000.app.github.dev';

  static Map<String, dynamic> _decode(http.Response response) {
    final data = jsonDecode(response.body);

    if (data is Map<String, dynamic>) {
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return data;
      }

      return {'success': false, 'message': data['message'] ?? 'Request failed'};
    }

    return {'success': false, 'message': 'Invalid server response'};
  }

  static Future<Map<String, dynamic>> requestOtp({
    required String mobile,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/auth/request-otp'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'mobile': mobile, 'role': 'SHOPKEEPER'}),
    );

    return _decode(response);
  }

  static Future<Map<String, dynamic>> verifyOtp({
    required String mobile,
    required String otp,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/auth/verify-otp'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'mobile': mobile, 'otp': otp, 'role': 'SHOPKEEPER'}),
    );

    return _decode(response);
  }

  static Future<Map<String, dynamic>> getMyBusiness({
    required String token,
  }) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/businesses/my-business'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    return _decode(response);
  }

  static Future<Map<String, dynamic>> getMyBusinessStatus({
    required String token,
  }) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/businesses/my-status'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    return _decode(response);
  }

  static Future<Map<String, dynamic>> updateMyBusiness({
    required String token,
    required Map<String, dynamic> data,
  }) async {
    final response = await http.put(
      Uri.parse('$baseUrl/api/businesses/my-business'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(data),
    );

    return _decode(response);
  }

  static Future<Map<String, dynamic>> getMyCouponCampaigns({
    required String token,
  }) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/coupons/my-campaigns'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    return _decode(response);
  }

  static Future<Map<String, dynamic>> createCouponCampaign({
    required String token,
    required Map<String, dynamic> data,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/coupons/campaigns'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(data),
    );

    return _decode(response);
  }

  static Future<Map<String, dynamic>> calculateTransaction({
    required String token,
    required String couponId,
    required double billAmount,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/transactions/calculate'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'couponId': couponId, 'billAmount': billAmount}),
    );

    return _decode(response);
  }

  static Future<Map<String, dynamic>> confirmTransaction({
    required String token,
    required String couponId,
    required double billAmount,
    String? verificationCode,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/transactions/confirm'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'couponId': couponId,
        'billAmount': billAmount,
        if (verificationCode != null && verificationCode.isNotEmpty)
          'verificationCode': verificationCode,
      }),
    );

    return _decode(response);
  }



  static Future<List<Map<String, dynamic>>> getShopkeeperTransactions({
    required String token,
  }) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/transactions/shopkeeper-history'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    final data = _decode(response);
    final items = data['data'];

    if (items is! List) return [];

    return items
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }


  static Future<Map<String, dynamic>> getDashboardStats({
    required String token,
  }) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/transactions/dashboard-stats'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    return _decode(response);
  }

  static Future<List<Map<String, dynamic>>> getClaimedCoupons({
    required String token,
  }) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/coupons/shopkeeper/claimed'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    final data = _decode(response);
    final items = data['data'];

    if (items is! List) return [];

    return items
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }
  static Future<List<Map<String, dynamic>>> getMyNotifications({
    required String token,
  }) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/notifications/my'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    final data = _decode(response);
    final items = data['data'];

    if (items is! List) return [];

    return items
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  static Future<int> getUnreadNotificationCount({
    required String token,
  }) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/notifications/unread-count'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    final data = _decode(response);

    if (data['success'] != true) return 0;

    final value = data['data']?['unreadCount'];
    return int.tryParse('$value') ?? 0;
  }

  static Future<void> markAllNotificationsRead({
    required String token,
  }) async {
    final response = await http.put(
      Uri.parse('$baseUrl/api/notifications/read-all'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    _decode(response);
  }

}
