import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'api_service.dart';

class AuthService extends ChangeNotifier {
  final ApiService _api = ApiService();
  bool isLoggedIn = false;
  String? username;

  AuthService() {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    isLoggedIn = prefs.getString('token') != null;
    username = prefs.getString('username');
    notifyListeners();
  }

  Future<void> login(String user, String pass) async {
    final data = await _api.post('/auth/login', {
      'username': user,
      'password': pass,
    }, auth: false);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', data['token']);
    await prefs.setString('username', data['user']['username']);
    isLoggedIn = true;
    username = data['user']['username'];
    notifyListeners();
  }

  Future<void> register(String user, String pass) async {
    await _api.post('/auth/register', {
      'username': user,
      'password': pass,
      'role': 'staff',
    }, auth: false);
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    isLoggedIn = false;
    username = null;
    notifyListeners();
  }
}
