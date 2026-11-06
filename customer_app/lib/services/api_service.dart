import 'dart:convert';

import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl =
      'https://cuddly-engine-r76pv47xgv5jhp5v-4000.app.github.dev';


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
    return int.tryParse(
          data['data']?['unreadCount']?.toString() ?? '0',
        ) ??
        0;
  }

  static Future<void> markNotificationRead({
    required String token,
    required String notificationId,
  }) async {
    final response = await http.put(
      Uri.parse('$baseUrl/api/notifications/$notificationId/read'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    _decode(response);
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

  static Future<List<Map<String, dynamic>>> openShopCoupons({
    required String token,
    required String businessId,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/coupons/shop/$businessId/open'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    final data = _decode(response);
    final items = data['data']?['coupons'];

    if (items is! List) return [];

    return items
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  static Future<Map<String, dynamic>> claimCoupon({
    required String token,
    required String couponId,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/coupons/claim'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'couponId': couponId}),
    );

    return _decode(response);
  }

  static Future<List<Map<String, dynamic>>> getPublicBusinesses() async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/businesses/public'),
    );

    final data = _decode(response);
    final items = data['data'];

    if (items is! List) return [];

    return items
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  static Future<Map<String, dynamic>> getBusinessReviews({
    required String businessId,
  }) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/reviews/business/$businessId'),
    );

    return _decode(response);
  }

  static Future<Map<String, dynamic>> saveReview({
    required String token,
    required String businessId,
    required int rating,
    String? reviewText,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/reviews'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'businessId': businessId,
        'rating': rating,
        'reviewText': reviewText?.trim(),
      }),
    );

    return _decode(response);
  }

  static Future<Map<String, dynamic>> deleteReview({
    required String token,
    required String reviewId,
  }) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/api/reviews/$reviewId'),
      headers: {'Authorization': 'Bearer $token'},
    );

    return _decode(response);
  }


  static Future<List<Map<String, dynamic>>> getCustomerTransactions({
    required String token,
  }) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/transactions/customer-history'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
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

  static Future<List<Map<String, dynamic>>> getMyCoupons({
    required String token,
  }) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/coupons/my-coupons'),
      headers: {'Authorization': 'Bearer $token'},
    );

    final data = _decode(response);

    final items = data['data'];

    if (items is! List) {
      return [];
    }

    return items
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  static Future<Map<String, dynamic>> updateProfile({
    required String token,
    required String name,
    required String email,
    required String city,
  }) async {
    final response = await http.put(
      Uri.parse('$baseUrl/api/profile/me'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'name': name, 'email': email, 'city': city}),
    );

    return _decode(response);
  }

  static Future<List<Map<String, dynamic>>> getFavorites({
    required String token,
  }) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/favorites'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
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

  static Future<Map<String, dynamic>> addFavorite({
    required String token,
    required String businessId,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/favorites/$businessId'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );
    return _decode(response);
  }

  static Future<Map<String, dynamic>> removeFavorite({
    required String token,
    required String businessId,
  }) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/api/favorites/$businessId'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );
    return _decode(response);
  }
}
