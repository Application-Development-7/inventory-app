import 'package:flutter_test/flutter_test.dart';
import 'package:inventory_app/services/theme_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('loads and persists the theme preference', () async {
    SharedPreferences.setMockInitialValues({'isDarkMode': true});
    final theme = ThemeProvider();

    expect(theme.isDarkMode, isFalse);
    await theme.loadTheme();
    expect(theme.isDarkMode, isTrue);

    await theme.toggleTheme();
    expect(theme.isDarkMode, isFalse);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('isDarkMode'), isFalse);

    final restoredTheme = ThemeProvider();
    await restoredTheme.loadTheme();
    expect(restoredTheme.isDarkMode, isFalse);
  });
}
