// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:inventory_app/main.dart';
import 'package:inventory_app/screens/trends_screen.dart';
import 'package:inventory_app/services/api_service.dart';
import 'package:inventory_app/widgets/demand_forecast_card.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('shows the Stockwise sign-in screen', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const MyApp());

    expect(find.text('Stockwise'), findsOneWidget);
    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.text('Sign in'), findsOneWidget);
    expect(
      tester
          .widgetList<TextField>(find.byType(TextField))
          .last
          .controller
          ?.text,
      isEmpty,
    );
    expect(
      tester.widgetList<TextField>(find.byType(TextField)).last.autofillHints,
      isEmpty,
    );
  });

  testWidgets('opens the account creation screen from login', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Create an account'));
    await tester.pumpAndSettle();

    expect(find.text('Create your account'), findsOneWidget);
    expect(find.text('Confirm password'), findsOneWidget);
    expect(find.text('Create account'), findsOneWidget);
  });

  testWidgets('shows historical chart and forecast table', (
    WidgetTester tester,
  ) async {
    final trend = {
      'status': 'OK',
      'product_name': 'Coffee',
      'label': 'RISING',
      'confidence': 80,
      'history': [
        {'year': 2026, 'month': 1, 'demand': 12},
        {'year': 2026, 'month': 2, 'demand': 15},
      ],
      'projections': [
        {
          'year': 2026,
          'month': 3,
          'predicted_demand': 18,
          'confidence': 75,
          'direction': 'UP',
        },
        {
          'year': 2026,
          'month': 4,
          'predicted_demand': 24,
          'confidence': 70,
          'direction': 'UP',
        },
      ],
    };
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: DemandForecastCard(trend: trend)),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Demand Forecast & Trend Analysis'), findsOneWidget);
    expect(find.byType(LineChart), findsOneWidget);
    expect(find.text('Coffee'), findsOneWidget);
    expect(find.text('24 units'), findsOneWidget);
    expect(find.text('70%'), findsOneWidget);
    expect(find.text('UP'), findsNWidgets(2));
  });

  testWidgets('loads the selected product forecast and handles no history', (
    WidgetTester tester,
  ) async {
    final api = _FakeForecastApiService();
    await tester.pumpWidget(
      Provider<ApiService>.value(
        value: api,
        child: const MaterialApp(home: Scaffold(body: TrendsScreen())),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Select a product'), findsOneWidget);
    expect(
      find.text('Need at least 3 months of stock-out history'),
      findsOneWidget,
    );
    expect(
      find.text('Top Products in ${_monthName(DateTime.now().month)}'),
      findsOneWidget,
    );
    expect(find.byType(BarChart), findsOneWidget);
    expect(
      api.lastTopProductsPath,
      '/analytics/top-products?month=${DateTime.now().month}',
    );
    expect(
      find.text(
        'Recommendation: Stock up on Coffee for next month based on current sales velocity.',
      ),
      findsOneWidget,
    );

    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tea').last);
    await tester.pumpAndSettle();

    expect(api.lastForecastPath, '/forecast/product/2');
    expect(find.text('Tea'), findsWidgets);
    expect(
      find.text('Need at least 3 months of stock-out history'),
      findsOneWidget,
    );

    final selectedMonth = DateTime.now().month % 12 + 1;
    await tester.tap(find.byType(DropdownButtonFormField<int>));
    await tester.pumpAndSettle();
    await tester.tap(find.text(_monthName(selectedMonth)).last);
    await tester.pumpAndSettle();

    expect(
      api.lastTopProductsPath,
      '/analytics/top-products?month=$selectedMonth',
    );
    expect(
      find.text('Top Products in ${_monthName(selectedMonth)}'),
      findsOneWidget,
    );
  });
}

String _monthName(int month) => const [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
][month - 1];

class _FakeForecastApiService extends ApiService {
  String? lastForecastPath;
  String? lastTopProductsPath;

  @override
  Future<dynamic> get(String path) async {
    if (path == '/products') {
      return [
        {'id': 1, 'name': 'Coffee'},
        {'id': 2, 'name': 'Tea'},
      ];
    }
    if (path.startsWith('/analytics/top-products')) {
      lastTopProductsPath = path;
      return [
        {'product_id': 1, 'product_name': 'Coffee', 'total_sold': 18},
        {'product_id': 2, 'product_name': 'Tea', 'total_sold': 11},
      ];
    }
    lastForecastPath = path;
    final name = path.endsWith('/2') ? 'Tea' : 'Coffee';
    return {
      'product': {'id': path.endsWith('/2') ? 2 : 1, 'name': name},
      'status': 'INSUFFICIENT_DATA',
      'message': 'Need at least 3 months of stock-out history',
      'data_points': 1,
    };
  }
}
