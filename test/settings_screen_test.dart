import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inventory_app/screens/settings_screen.dart';
import 'package:inventory_app/services/api_service.dart';
import 'package:inventory_app/services/auth_service.dart';
import 'package:inventory_app/services/theme_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('persists the returned display name when logging in', () async {
    SharedPreferences.setMockInitialValues({
      'token': 'old-token',
      'username': 'old-user',
      'displayName': 'Old User',
      'oldSessionData': 'must be removed',
    });
    final api = _SettingsApiService()
      ..loginResponse = {
        'token': 'new-token',
        'user': {'username': 'neil', 'display_name': 'Neil'},
      };
    final auth = AuthService(api: api);

    await Future<void>.delayed(const Duration(milliseconds: 10));
    await auth.login('neil', 'password');

    final prefs = await SharedPreferences.getInstance();
    expect(auth.displayName, 'Neil');
    expect(prefs.getString('displayName'), 'Neil');
    expect(await api.getToken(), 'new-token');
    expect(prefs.getString('oldSessionData'), isNull);

    await auth.logout();

    expect(await api.getToken(), isNull);
    expect(prefs.getKeys(), isEmpty);
  });

  testWidgets('shows display name above username in profile settings', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'username': 'neil',
      'displayName': 'Neil',
    });
    final auth = AuthService();
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 10)),
    );

    await tester.pumpWidget(_settingsApp(auth));
    await tester.pumpAndSettle();

    final formFields = tester
        .widgetList<TextFormField>(find.byType(TextFormField))
        .toList();
    final profileFields = formFields
        .map((field) => field.controller)
        .take(2)
        .toList();
    final profileTextFields = tester
        .widgetList<TextField>(find.byType(TextField))
        .take(2)
        .toList();
    expect(profileTextFields[0].decoration!.labelText, 'Display Name');
    expect(
      profileTextFields[0].decoration!.hintText,
      'What should we call you?',
    );
    expect(profileFields[0]!.text, 'Neil');
    expect(profileTextFields[1].decoration!.labelText, 'Username');
    expect(profileFields[1]!.text, 'neil');
    expect(find.byType(Form), findsNWidgets(3));
    expect(formFields, hasLength(6));
    for (final field in formFields) {
      expect(field.controller, isA<TextEditingController>());
      expect(field.validator, isNotNull);
    }
    expect(formFields[2].validator!(null), 'Enter your current password');
    formFields[3].controller!.text = 'new-password';
    expect(
      formFields[4].validator!('different-password'),
      'Passwords do not match',
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('asks for current password before a username change', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'username': 'neil',
      'displayName': 'Neil',
    });
    final auth = AuthService();
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 10)),
    );

    await tester.pumpWidget(_settingsApp(auth));
    await tester.pumpAndSettle();

    final usernameField = tester
        .widgetList<TextField>(find.byType(TextField))
        .firstWhere((field) => field.decoration?.labelText == 'Username');
    usernameField.controller!.text = 'new-username';

    await tester.tap(find.text('Save profile'));
    await tester.pumpAndSettle();

    expect(find.text('Confirm username change'), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is TextField &&
            widget.decoration?.labelText == 'Current Password',
      ),
      findsNWidgets(2),
    );

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(find.text('Confirm username change'), findsNothing);
  });

  testWidgets('shows a neutral message when the profile has no changes', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'username': 'neil',
      'displayName': 'Neil',
    });
    final auth = AuthService();
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 10)),
    );

    await tester.pumpWidget(_settingsApp(auth));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Save profile'));
    await tester.pumpAndSettle();

    expect(find.text('No changes to save'), findsOneWidget);
    expect(find.text('Profile updated successfully!'), findsNothing);
  });

  testWidgets('refreshes profile fields from the API', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'username': 'neil',
      'displayName': 'Neil',
      'token': 'test-token',
    });
    final api = _SettingsApiService()
      ..profile = {'username': 'new-user', 'display_name': 'New Display'};
    final auth = AuthService(api: api);
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 10)),
    );

    await tester.pumpWidget(_settingsApp(auth));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Refresh profile'));
    await tester.pumpAndSettle();

    expect(api.lastGetPath, '/users/me');
    expect(find.text('new-user'), findsOneWidget);
    expect(find.text('New Display'), findsOneWidget);
    expect(auth.username, 'new-user');
    expect(auth.displayName, 'New Display');
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('username'), 'new-user');
    expect(prefs.getString('displayName'), 'New Display');
  });

  testWidgets('confirms before signing out from Settings', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'username': 'neil',
      'displayName': 'Neil',
      'token': 'test-token',
    });
    final auth = AuthService(api: _SettingsApiService());
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 10)),
    );

    await tester.pumpWidget(_settingsApp(auth));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Sign Out'));
    await tester.tap(find.text('Sign Out'));
    await tester.pumpAndSettle();

    expect(find.text('Are you sure you want to log out?'), findsOneWidget);
    expect(auth.isLoggedIn, isTrue);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(auth.isLoggedIn, isTrue);

    await tester.ensureVisible(find.text('Sign Out'));
    await tester.tap(find.text('Sign Out'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sign Out').last);
    await tester.pumpAndSettle();

    expect(auth.isLoggedIn, isFalse);
    expect(auth.username, isNull);
    expect(auth.displayName, isNull);
  });

  testWidgets('saves store and notification preferences', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final api = _SettingsApiService();
    final auth = AuthService(api: api);
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 10)),
    );

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthService>.value(value: auth),
          ChangeNotifierProvider<ThemeProvider>.value(value: ThemeProvider()),
        ],
        child: const MaterialApp(home: Scaffold(body: SettingsScreen())),
      ),
    );
    await tester.pumpAndSettle();

    final thresholdField = find.byWidgetPredicate(
      (widget) =>
          widget is TextField &&
          widget.decoration?.labelText == 'Global Low Stock Threshold',
    );
    await tester.ensureVisible(thresholdField);
    await tester.enterText(thresholdField, '12');
    final lowStockSwitch = find.ancestor(
      of: find.text('Low Stock Alerts'),
      matching: find.byType(SwitchListTile),
    );
    await tester.ensureVisible(lowStockSwitch);
    await tester.tap(lowStockSwitch);
    await tester.ensureVisible(find.text('Save preferences'));
    await tester.tap(find.text('Save preferences'));
    await tester.pumpAndSettle();

    expect(api.lastPutPath, '/users/preferences');
    expect(api.lastPutBody?['lowStockThreshold'], 12);
    expect(api.lastPutBody?['notifyLowStock'], isFalse);
    expect(auth.lowStockThreshold, 12);
    expect(auth.notifyLowStock, isFalse);
  });

  testWidgets('requires typing DELETE before clearing inventory', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final api = _SettingsApiService();
    final auth = AuthService(api: api);
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 10)),
    );

    await tester.pumpWidget(_settingsApp(auth));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Clear Inventory Data'));
    await tester.tap(find.text('Clear Inventory Data'));
    await tester.pumpAndSettle();

    expect(
      find.text(
        'Are you sure? This will delete all products. Type DELETE to confirm',
      ),
      findsOneWidget,
    );
    final confirmButton = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Clear Inventory'),
    );
    expect(confirmButton.onPressed, isNull);

    await tester.enterText(
      find.byWidgetPredicate(
        (widget) =>
            widget is TextField &&
            widget.decoration?.labelText == 'Type DELETE to confirm',
      ),
      'DELETE',
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Clear Inventory'));
    await tester.pumpAndSettle();

    expect(api.deletedPaths, contains('/inventory/clear'));
    expect(auth.inventoryRevision, 1);
  });

  testWidgets('requires typing DELETE before deleting the account', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({'token': 'test-token'});
    final api = _SettingsApiService();
    final auth = AuthService(api: api)..isLoggedIn = true;
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 10)),
    );

    await tester.pumpWidget(_settingsApp(auth));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Delete Account'));
    await tester.tap(find.text('Delete Account'));
    await tester.pumpAndSettle();

    final deleteButton = find.widgetWithText(FilledButton, 'Delete Account');
    expect(tester.widget<FilledButton>(deleteButton).onPressed, isNull);
    await tester.enterText(
      find.byWidgetPredicate(
        (widget) =>
            widget is TextField &&
            widget.decoration?.labelText == 'Type DELETE to confirm',
      ),
      'DELETE',
    );
    await tester.pumpAndSettle();
    await tester.tap(deleteButton);
    await tester.pumpAndSettle();

    expect(api.deletedPaths, contains('/users/account'));
    expect(auth.isLoggedIn, isFalse);
  });
}

Widget _settingsApp(AuthService auth) => MultiProvider(
  providers: [
    ChangeNotifierProvider<AuthService>.value(value: auth),
    ChangeNotifierProvider<ThemeProvider>.value(value: ThemeProvider()),
  ],
  child: const MaterialApp(home: Scaffold(body: SettingsScreen())),
);

class _SettingsApiService extends ApiService {
  Map<String, dynamic> profile = {'username': 'neil', 'display_name': 'Neil'};
  String? lastGetPath;
  Map<String, dynamic>? loginResponse;
  String? lastPutPath;
  Map? lastPutBody;
  final List<String> deletedPaths = [];

  @override
  Future<dynamic> get(String path) async {
    lastGetPath = path;
    if (path == '/users/me') return profile;
    throw StateError('Unexpected GET request: $path');
  }

  @override
  Future<dynamic> post(String path, Map body, {bool auth = true}) async {
    if (path == '/auth/login') return loginResponse;
    throw StateError('Unexpected POST request: $path');
  }

  @override
  Future<dynamic> put(String path, Map body) async {
    lastPutPath = path;
    lastPutBody = Map.of(body);
    return <String, dynamic>{};
  }

  @override
  Future<dynamic> delete(String path) async {
    deletedPaths.add(path);
    return <String, dynamic>{};
  }
}
