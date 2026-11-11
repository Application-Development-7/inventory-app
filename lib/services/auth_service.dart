import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'api_service.dart';

class AuthService extends ChangeNotifier {
  final ApiService _api;
  bool isLoggedIn = false;
  String? username;
  String? displayName;
  String currency = '₱';
  int lowStockThreshold = 5;
  bool notifyLowStock = true;
  bool notifyWeeklySummary = true;
  int inventoryRevision = 0;
  int _sessionRevision = 0;
  Future<void>? _logoutInProgress;

  int get sessionRevision => _sessionRevision;

  AuthService({ApiService? api}) : _api = api ?? ApiService() {
    _api.setUnauthorizedHandler(logout);
    _load();
  }

  Future<void> _load() async {
    final sessionRevision = _sessionRevision;
    final prefs = await SharedPreferences.getInstance();
    if (sessionRevision != _sessionRevision) return;
    final token = prefs.getString('token');
    _api.setToken(token);
    isLoggedIn = token != null && token.trim().isNotEmpty;
    username = prefs.getString('username');
    displayName = prefs.getString('displayName');
    currency = prefs.getString('currency') ?? '₱';
    lowStockThreshold = prefs.getInt('lowStockThreshold') ?? 5;
    notifyLowStock = prefs.getBool('notifyLowStock') ?? true;
    notifyWeeklySummary = prefs.getBool('notifyWeeklySummary') ?? true;
    notifyListeners();
  }

  Future<void> login(
    String user,
    String pass, {
    bool rememberMe = false,
  }) async {
    final sessionRevision = _sessionRevision;
    final data = await _api.post('/auth/login', {
      'username': user,
      'password': pass,
    }, auth: false);
    if (sessionRevision != _sessionRevision) return;
    final token = data['token'];
    final responseUser = data['user'];
    if (token is! String || token.trim().isEmpty || responseUser is! Map) {
      throw const FormatException(
        'Login response did not contain valid credentials',
      );
    }

    final loggedInUsername = responseUser['username'];
    if (loggedInUsername is! String || loggedInUsername.isEmpty) {
      throw const FormatException('Login response did not contain a username');
    }
    final responseDisplayName = responseUser['display_name'];
    final loggedInDisplayName =
        responseDisplayName is String && responseDisplayName.trim().isNotEmpty
        ? responseDisplayName.trim()
        : null;
    final loggedInCurrency = _currencyValue(responseUser['currency']);
    final loggedInThreshold = _thresholdValue(
      responseUser['low_stock_threshold'],
    );
    final loggedInNotifyLowStock = _boolValue(
      responseUser['notify_low_stock'],
      fallback: true,
    );
    final loggedInNotifyWeeklySummary = _boolValue(
      responseUser['notify_weekly_summary'],
      fallback: true,
    );

    final prefs = await SharedPreferences.getInstance();
    if (sessionRevision != _sessionRevision) return;
    await prefs.clear();
    final normalizedToken = token.trim();
    _api.setToken(normalizedToken);
    if (rememberMe) {
      await prefs.setString('token', normalizedToken);
      await prefs.setString('username', loggedInUsername);
    } else {
      await prefs.remove('token');
      await prefs.remove('username');
    }
    if (loggedInDisplayName == null) {
      await prefs.remove('displayName');
    } else {
      await prefs.setString('displayName', loggedInDisplayName);
    }
    currency = loggedInCurrency;
    lowStockThreshold = loggedInThreshold;
    notifyLowStock = loggedInNotifyLowStock;
    notifyWeeklySummary = loggedInNotifyWeeklySummary;
    await _savePreferences(prefs);
    if (sessionRevision != _sessionRevision) return;
    isLoggedIn = true;
    username = loggedInUsername;
    displayName = loggedInDisplayName;
    notifyListeners();
  }

  Future<void> register(String user, String pass) async {
    await _api.post('/auth/register', {
      'username': user,
      'password': pass,
      'role': 'staff',
    }, auth: false);
  }

  Future<void> updateProfile({
    required String username,
    required String displayName,
    String? currentPassword,
  }) async {
    final sessionRevision = _sessionRevision;
    final normalizedUsername = username.trim();
    final normalizedDisplayName = displayName.trim();
    final request = <String, String>{
      'username': normalizedUsername,
      'displayName': normalizedDisplayName,
    };
    if (currentPassword != null) {
      request['currentPassword'] = currentPassword;
    }
    await _api.put('/users/profile', request);
    if (sessionRevision != _sessionRevision) return;

    this.username = normalizedUsername;
    this.displayName = normalizedDisplayName.isEmpty
        ? null
        : normalizedDisplayName;
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getString('token') != null) {
      await prefs.setString('username', normalizedUsername);
    }
    await _saveDisplayName(prefs);
    if (sessionRevision != _sessionRevision) return;
    notifyListeners();
  }

  Future<void> refreshProfile() async {
    final sessionRevision = _sessionRevision;
    final data = await _api.get('/users/me');
    if (sessionRevision != _sessionRevision) return;
    if (data is! Map ||
        data['username'] is! String ||
        (data['display_name'] != null && data['display_name'] is! String)) {
      throw const FormatException(
        'Profile response did not contain valid user data',
      );
    }

    username = (data['username'] as String).trim();
    final responseDisplayName = data['display_name'] as String?;
    displayName =
        responseDisplayName != null && responseDisplayName.trim().isNotEmpty
        ? responseDisplayName.trim()
        : null;
    currency = _currencyValue(data['currency']);
    lowStockThreshold = _thresholdValue(data['low_stock_threshold']);
    notifyLowStock = _boolValue(data['notify_low_stock'], fallback: true);
    notifyWeeklySummary = _boolValue(
      data['notify_weekly_summary'],
      fallback: true,
    );

    final prefs = await SharedPreferences.getInstance();
    if (prefs.getString('token') != null) {
      await prefs.setString('username', username!);
    }
    await _saveDisplayName(prefs);
    await _savePreferences(prefs);
    if (sessionRevision != _sessionRevision) return;
    notifyListeners();
  }

  Future<void> updatePreferences({
    required String currency,
    required int lowStockThreshold,
    required bool notifyLowStock,
    required bool notifyWeeklySummary,
  }) async {
    final sessionRevision = _sessionRevision;
    await _api.put('/users/preferences', {
      'currency': currency,
      'lowStockThreshold': lowStockThreshold,
      'notifyLowStock': notifyLowStock,
      'notifyWeeklySummary': notifyWeeklySummary,
    });
    if (sessionRevision != _sessionRevision) return;

    this.currency = currency;
    this.lowStockThreshold = lowStockThreshold;
    this.notifyLowStock = notifyLowStock;
    this.notifyWeeklySummary = notifyWeeklySummary;
    final prefs = await SharedPreferences.getInstance();
    await _savePreferences(prefs);
    if (sessionRevision != _sessionRevision) return;
    notifyListeners();
  }

  Future<void> clearInventory() async {
    final sessionRevision = _sessionRevision;
    await _api.delete('/inventory/clear');
    if (sessionRevision != _sessionRevision) return;
    inventoryRevision++;
    notifyListeners();
  }

  Future<void> deleteAccount() async {
    await _api.delete('/users/account');
    await logout();
  }

  Future<void> _saveDisplayName(SharedPreferences prefs) async {
    if (displayName == null) {
      await prefs.remove('displayName');
    } else {
      await prefs.setString('displayName', displayName!);
    }
  }

  Future<void> _savePreferences(SharedPreferences prefs) async {
    await prefs.setString('currency', currency);
    await prefs.setInt('lowStockThreshold', lowStockThreshold);
    await prefs.setBool('notifyLowStock', notifyLowStock);
    await prefs.setBool('notifyWeeklySummary', notifyWeeklySummary);
  }

  String _currencyValue(dynamic value) =>
      value is String && const ['₱', r'$', '€'].contains(value) ? value : '₱';

  int _thresholdValue(dynamic value) =>
      value is num && value >= 0 ? value.toInt() : 5;

  bool _boolValue(dynamic value, {required bool fallback}) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    return fallback;
  }

  Future<void> updatePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    await _api.put('/users/password', {
      'currentPassword': currentPassword,
      'newPassword': newPassword,
    });
  }

  Future<void> logout() {
    final logoutInProgress = _logoutInProgress;
    if (logoutInProgress != null) return logoutInProgress;

    _sessionRevision++;
    final logout = _clearSession();
    _logoutInProgress = logout;
    return logout.whenComplete(() {
      if (identical(_logoutInProgress, logout)) {
        _logoutInProgress = null;
      }
    });
  }

  Future<void> _clearSession() async {
    final wasLoggedIn = isLoggedIn;
    _api.setToken(null);
    isLoggedIn = false;
    username = null;
    displayName = null;
    currency = '₱';
    lowStockThreshold = 5;
    notifyLowStock = true;
    notifyWeeklySummary = true;
    if (wasLoggedIn) notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
