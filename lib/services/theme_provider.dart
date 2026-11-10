import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  bool _isDarkMode = false;

  bool get isDarkMode => _isDarkMode;

  Future<void> loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final isDarkMode = prefs.getBool('isDarkMode') ?? false;
    if (_isDarkMode != isDarkMode) {
      _isDarkMode = isDarkMode;
      notifyListeners();
    }
  }

  Future<void> setDarkMode(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', enabled);
    _updateTheme(enabled);
  }

  Future<void> toggleTheme() => setDarkMode(!_isDarkMode);

  void _updateTheme(bool isDarkMode) {
    if (_isDarkMode == isDarkMode) return;
    _isDarkMode = isDarkMode;
    notifyListeners();
  }
}
