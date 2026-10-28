import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // USE THIS FOR CHROME/WEB OR WINDOWS:
  static const String baseUrl = 'http://localhost:3000/api';

  // USE THIS INSTEAD IF YOU RUN ON ANDROID EMULATOR:
  // static const String baseUrl = 'http://10.0.2.2:3000/api';
  //static const String baseUrl = '192.168.1.58:3000/api';

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<Map<String, String>> _headers({bool auth = true}) async {
    final headers = {'Content-Type': 'application/json'};
    if (auth) {
      final token = await getToken();
      if (token != null) headers['Authorization'] = 'Bearer $token';
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

  Future<dynamic> getProductForecast(
    String productId, {
    String view = 'monthly',
  }) {
    if (view != 'monthly' && view != 'yearly') {
      throw ArgumentError.value(view, 'view', 'Must be monthly or yearly');
    }
    return get('/forecast/product/$productId?view=$view');
  }

  Future<Map<String, dynamic>> getForecastTrends({
    String view = 'monthly',
  }) async {
    if (view != 'monthly' && view != 'yearly') {
      throw ArgumentError.value(view, 'view', 'Must be monthly or yearly');
    }
    final response = await get('/forecast/trends?view=$view');
    return (response as Map).cast<String, dynamic>();
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
    return (response as List).cast<Map<String, dynamic>>();
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

  dynamic _handle(http.Response res) {
    final data = res.body.isNotEmpty ? jsonDecode(res.body) : null;
    if (res.statusCode >= 200 && res.statusCode < 300) return data;
    throw Exception(data?['message'] ?? 'API error ${res.statusCode}');
  }
}
