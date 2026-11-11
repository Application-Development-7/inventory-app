import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  Future<void> Function()? _onUnauthorized;
  String? _sessionToken;

  void setUnauthorizedHandler(Future<void> Function() handler) {
    _onUnauthorized = handler;
  }

  void setToken(String? token) {
    _sessionToken = token;
  }

  // USE THIS FOR CHROME/WEB OR WINDOWS:
  static const String baseUrl = 'http://localhost:3000/api';

  // USE THIS INSTEAD IF YOU RUN ON ANDROID EMULATOR:
  // static const String baseUrl = 'http://10.0.2.2:3000/api';
  // static const String baseUrl = 'http://localhost:3000/api';
  // static const String baseUrl = '192.168.1.58:3000/api';

  Future<String?> getToken() async {
    if (_sessionToken != null) return _sessionToken;
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<Map<String, String>> _headers({bool auth = true}) async {
    final headers = {'Content-Type': 'application/json'};
    if (auth) {
      final token = await getToken();
      if (token != null && token.trim().isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    }
    return headers;
  }

  Future<dynamic> get(String path) async {
    final res = await http.get(
      Uri.parse('$baseUrl$path'),
      headers: await _headers(),
    );
    return _handle(res);
  }

  Future<List<Map<String, dynamic>>> getDashboardTransactions({
    String? beforeCreatedAt,
    int? beforeId,
  }) async {
    if ((beforeCreatedAt == null) != (beforeId == null)) {
      throw ArgumentError(
        'beforeCreatedAt and beforeId must be provided together',
      );
    }

    final queryParameters = beforeCreatedAt == null
        ? null
        : {'beforeCreatedAt': beforeCreatedAt, 'beforeId': beforeId.toString()};
    final path = Uri(
      path: '/dashboard/transactions',
      queryParameters: queryParameters,
    ).toString();
    final response = await get(path);
    return parseListResponse(response, endpoint: 'Dashboard activity');
  }

  Future<dynamic> getProductForecast(
    String productId, {
    String view = 'monthly',
  }) {
    if (view != 'monthly' && view != 'yearly') {
      throw ArgumentError.value(view, 'view', 'Must be monthly or yearly');
    }
    return get('/forecast/product/$productId?view=$view');
  }

  Future<dynamic> getForecastTrends({String view = 'monthly'}) async {
    if (view != 'monthly' && view != 'yearly') {
      throw ArgumentError.value(view, 'view', 'Must be monthly or yearly');
    }
    return get('/forecast/trends?view=$view');
  }

  Future<List<Map<String, dynamic>>> getTopProductsThisMonth({
    int? month,
    String view = 'monthly',
  }) async {
    final normalizedView = view == 'yearly' ? 'yearly' : 'monthly';
    final selectedMonth = month ?? DateTime.now().month;
    if (selectedMonth < 1 || selectedMonth > 12) {
      throw ArgumentError.value(month, 'month', 'Must be between 1 and 12');
    }

    final query = normalizedView == 'yearly'
        ? '?view=$normalizedView'
        : '?month=$selectedMonth&view=$normalizedView';

    final response = await get('/analytics/top-products$query');
    return parseListResponse(response, endpoint: 'Top products');
  }

  static List<Map<String, dynamic>> parseListResponse(
    dynamic response, {
    required String endpoint,
  }) {
    if (response is! List) {
      final message = response is Map ? response['message'] : null;
      final detail = message is String && message.trim().isNotEmpty
          ? ' Server message: ${message.trim()}'
          : '';
      throw FormatException(
        '$endpoint response must be a JSON array, but received '
        '${response.runtimeType}.$detail',
      );
    }

    return response.map<Map<String, dynamic>>((item) {
      if (item is! Map || item.keys.any((key) => key is! String)) {
        throw FormatException(
          '$endpoint response contains an item that is not a JSON object.',
        );
      }
      return item.cast<String, dynamic>();
    }).toList();
  }

  static List<Map<String, dynamic>> parseListResponseOrEmpty(dynamic response) {
    if (response is! List) return [];

    return response.whereType<Map>().map((item) {
      return item.map<String, dynamic>(
        (key, value) => MapEntry(key.toString(), value),
      );
    }).toList();
  }

  static Map<String, dynamic> parseObjectResponse(
    dynamic response, {
    required String endpoint,
  }) {
    if (response is! Map || response.keys.any((key) => key is! String)) {
      final message = response is Map ? response['message'] : null;
      final detail = message is String && message.trim().isNotEmpty
          ? ' Server message: ${message.trim()}'
          : '';
      throw FormatException(
        '$endpoint response must be a JSON object, but received '
        '${response.runtimeType}.$detail',
      );
    }
    return response.cast<String, dynamic>();
  }

  Future<dynamic> post(String path, Map body, {bool auth = true}) async {
    final res = await http.post(
      Uri.parse('$baseUrl$path'),
      headers: await _headers(auth: auth),
      body: jsonEncode(body),
    );
    return _handle(res);
  }

  Future<dynamic> put(String path, Map body) async {
    final res = await http.put(
      Uri.parse('$baseUrl$path'),
      headers: await _headers(),
      body: jsonEncode(body),
    );
    return _handle(res);
  }

  Future<dynamic> delete(String path) async {
    final res = await http.delete(
      Uri.parse('$baseUrl$path'),
      headers: await _headers(),
    );
    return _handle(res);
  }

  Future<dynamic> _handle(http.Response res) async {
    if (res.statusCode == 401) {
      await _onUnauthorized?.call();
    }

    dynamic data;
    if (res.body.isNotEmpty) {
      try {
        data = jsonDecode(res.body);
      } on FormatException {
        if (res.statusCode >= 200 && res.statusCode < 300) rethrow;
        throw Exception(
          'API request failed with HTTP ${res.statusCode}: '
          'the server returned an invalid JSON response.',
        );
      }
    }
    if (res.statusCode >= 200 && res.statusCode < 300) return data;
    final message = data is Map ? data['message'] : null;
    if (message is String && message.trim().isNotEmpty) {
      throw Exception(message.trim());
    }
    throw Exception('API request failed with HTTP ${res.statusCode}.');
  }
}
