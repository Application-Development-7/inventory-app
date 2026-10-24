import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inventory_app/screens/home_screen.dart';
import 'package:inventory_app/services/api_service.dart';
import 'package:inventory_app/services/auth_service.dart';
import 'package:inventory_app/services/theme_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('shows stacked dashboard with stat cards on mobile', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await _pumpDashboard(tester);

    expect(find.text('Products'), findsNWidgets(2));
    expect(find.text('Total stock'), findsOneWidget);
    expect(find.text('Low stock'), findsOneWidget);
    expect(find.byType(ListView), findsNWidgets(3));
    expect(find.text('Stock by Category'), findsOneWidget);
    expect(find.text('Beverages'), findsOneWidget);
    expect(find.text('18'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Recent transactions'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Recent transactions'), findsOneWidget);
    expect(find.text('Coffee'), findsOneWidget);

    final categoryDropdown = find.byType(DropdownButtonFormField<String?>);
    await tester.ensureVisible(categoryDropdown);
    await tester.pumpAndSettle();
    await tester.tap(categoryDropdown);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Beverages').last);
    await tester.pumpAndSettle();
    expect(find.textContaining('Stock In · +4 units'), findsOneWidget);
    expect(find.textContaining('Stock Out · -2 units'), findsNothing);
  });

  testWidgets('keeps a single stacked dashboard on desktop widths', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await _pumpDashboard(tester);

    expect(find.byType(ListView), findsNWidgets(3));
    expect(find.text('Products'), findsNWidgets(2));
    expect(find.text('Total stock'), findsOneWidget);
    expect(find.text('Low stock'), findsOneWidget);
    expect(find.text('Recent transactions'), findsOneWidget);
    expect(find.text('Stock by Category'), findsOneWidget);
    expect(find.text('Beverages'), findsOneWidget);
  });
}

Future<void> _pumpDashboard(WidgetTester tester) async {
  SharedPreferences.setMockInitialValues({});
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        Provider<ApiService>.value(value: _DashboardApiService()),
        ChangeNotifierProvider<AuthService>.value(value: AuthService()),
        ChangeNotifierProvider<ThemeProvider>.value(value: ThemeProvider()),
      ],
      child: const MaterialApp(home: HomeScreen()),
    ),
  );
  await tester.pumpAndSettle();
}

class _DashboardApiService extends ApiService {
  @override
  Future<dynamic> get(String path) async {
    if (path == '/products') {
      return [
        {'name': 'Coffee', 'category_name': 'Beverages', 'quantity': 12},
        {'name': 'Tea', 'category_name': 'Beverages', 'quantity': '6'},
        {'name': 'Chips', 'category_name': 'Snacks', 'quantity': 10},
      ];
    }
    if (path == '/dashboard') {
      return {
        'stats': {
          'total_products': 12,
          'total_stock': 86,
          'low_stock_count': 1,
        },
        'low_stock_products': [
          {'name': 'Tea', 'quantity': 2, 'min_stock': 5},
        ],
        'recent_transactions': [
          {
            'id': 1,
            'product_id': 1,
            'product_name': 'Coffee',
            'category_name': 'Beverages',
            'type': 'IN',
            'quantity': 4,
            'created_at': '2026-10-24 01:30:00',
          },
          {
            'id': 2,
            'product_id': 3,
            'product_name': 'Chips',
            'category_name': 'Snacks',
            'type': 'OUT',
            'quantity': 2,
            'created_at': '2026-10-23 16:00:00',
          },
        ],
      };
    }
    throw StateError('Unexpected API request: $path');
  }
}
