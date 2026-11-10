import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inventory_app/screens/home_screen.dart';
import 'package:inventory_app/services/api_service.dart';
import 'package:inventory_app/services/auth_service.dart';
import 'package:inventory_app/services/theme_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:inventory_app/widgets/skeleton_loader.dart';

void main() {
  testWidgets('shows dashboard skeleton while initial data loads', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final api = _DelayedDashboardApiService();
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<ApiService>.value(value: api),
          ChangeNotifierProvider<AuthService>.value(value: AuthService()),
          ChangeNotifierProvider<ThemeProvider>.value(value: ThemeProvider()),
        ],
        child: const MaterialApp(home: HomeScreen()),
      ),
    );
    await tester.pump();

    expect(find.byType(SkeletonLoader), findsOneWidget);
    expect(tester.takeException(), isNull);

    api.dashboard.complete({
      'stats': <String, dynamic>{},
      'low_stock_products': <Map<String, dynamic>>[],
      'recent_transactions': <Map<String, dynamic>>[],
    });
    api.products.complete(<Map<String, dynamic>>[]);
    await tester.pumpAndSettle();
    expect(find.byType(SkeletonLoader), findsNothing);
  });

  testWidgets('renders an empty dashboard for a new account', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<ApiService>.value(value: _EmptyDashboardApiService()),
          ChangeNotifierProvider<AuthService>.value(value: AuthService()),
          ChangeNotifierProvider<ThemeProvider>.value(value: ThemeProvider()),
        ],
        child: const MaterialApp(home: HomeScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('All stocked up.'), findsOneWidget);
    expect(find.text('Recent Activity'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('shows stacked dashboard with stat cards on mobile', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await _pumpDashboard(tester);

    expect(find.text('Products'), findsOneWidget);
    expect(find.text('Units in Stock'), findsOneWidget);
    expect(find.text('Low Stock'), findsNWidgets(2));
    expect(find.byType(ListView), findsAtLeastNWidgets(1));
    await _scrollUntilFound(tester, find.text('Recent Activity'), -500);
    expect(find.text('Recent Activity'), findsOneWidget);
    expect(find.text('Coffee'), findsOneWidget);
    await _scrollUntilFound(tester, find.text('Stock by Category'), -500);
    expect(find.text('Stock by Category'), findsOneWidget);
    expect(find.text('Beverages'), findsAtLeastNWidgets(1));
    await _scrollUntilFound(tester, find.text('Recent Activity'), 500);

    final categoryFilter = find.byTooltip('Filter by category');
    await tester.ensureVisible(categoryFilter);
    await tester.pumpAndSettle();
    await tester.tap(categoryFilter);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Beverages').last);
    await tester.pumpAndSettle();
    expect(find.textContaining('Stock in · 4 units'), findsNWidgets(2));
    expect(find.textContaining('Stock out · 2 units'), findsNothing);
  });

  testWidgets('shows activity and chart above the attention cards on desktop', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await _pumpDashboard(tester);

    expect(find.byType(ListView), findsAtLeastNWidgets(1));
    expect(find.text('Products'), findsOneWidget);
    expect(find.text('Units in Stock'), findsOneWidget);
    expect(find.text('Low Stock'), findsNWidgets(2));
    expect(find.text('Recent Activity'), findsOneWidget);
    expect(find.text('Stock by Category'), findsOneWidget);
    expect(find.text('Beverages'), findsAtLeastNWidgets(1));
    expect(find.text('Top Categories'), findsOneWidget);
    final activityPosition = tester.getTopLeft(find.text('Recent Activity'));
    final chartPosition = tester.getTopLeft(find.text('Stock by Category'));
    final attentionPosition = tester.getTopLeft(
      find.text('Items require your attention'),
    );
    final topCategoriesPosition = tester.getTopLeft(
      find.text('Top Categories'),
    );
    expect(activityPosition.dx, lessThan(chartPosition.dx));
    expect((activityPosition.dy - chartPosition.dy).abs(), lessThan(40));
    expect(attentionPosition.dy, greaterThan(activityPosition.dy));
    expect(topCategoriesPosition.dy, greaterThan(attentionPosition.dy));
  });

  testWidgets(
    'shows display name in the desktop sidebar with username fallback',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      SharedPreferences.setMockInitialValues({
        'username': 'admin1',
        'displayName': 'Store Manager',
      });
      final auth = AuthService();
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 10)),
      );
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider<ApiService>.value(value: _DashboardApiService()),
            ChangeNotifierProvider<AuthService>.value(value: auth),
            ChangeNotifierProvider<ThemeProvider>.value(value: ThemeProvider()),
          ],
          child: const MaterialApp(home: HomeScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Store Manager'), findsOneWidget);
      expect(find.text('admin1'), findsNothing);
      expect(find.text('S'), findsNWidgets(2));

      auth.displayName = '  ';
      auth.notifyListeners();
      await tester.pumpAndSettle();

      expect(find.text('admin1'), findsOneWidget);
      expect(find.text('Store Manager'), findsNothing);
      expect(find.text('A'), findsNWidgets(2));
    },
  );

  testWidgets('stacks dashboard cards vertically on mobile', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await _pumpDashboard(tester);

    await _scrollUntilFound(
      tester,
      find.text('Items require your attention'),
      -500,
    );
    await _scrollUntilFound(tester, find.text('Top Categories'), -500);
    final attentionPosition = tester.getTopLeft(
      find.text('Items require your attention'),
    );
    final topCategoriesPosition = tester.getTopLeft(
      find.text('Top Categories'),
    );
    expect(attentionPosition.dy, lessThan(topCategoriesPosition.dy));
  });

  testWidgets('shows activity records beyond the first five', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await _pumpDashboard(tester);

    await tester.scrollUntilVisible(
      find.text('Historical item 7'),
      120,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('Historical item 7'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('loads and appends the next activity page', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final api = _DashboardApiService(fillInitialPage: true);
    await _pumpDashboard(tester, api: api);
    await tester.ensureVisible(find.text('Recent Activity'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Load More'));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Loaded older entry'),
      120,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('Loaded older entry'), findsOneWidget);
    expect(api.requestedCursorId, 20);
    expect(tester.takeException(), isNull);
  });

  testWidgets('shows product audit actions in recent activity', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await _pumpDashboard(tester, api: _DashboardApiService(includeAudit: true));

    expect(
      find.text('Admin edited product Sparkling Apple Cider'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('shows and hides the API inventory value', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await _pumpDashboard(tester);

    expect(
      tester
          .widget<Text>(find.byKey(const ValueKey('kpi-value-Total Products')))
          .data,
      '12',
    );
    expect(
      tester
          .widget<Text>(find.byKey(const ValueKey('kpi-value-Units in Stock')))
          .data,
      '86',
    );
    expect(
      tester
          .widget<Text>(find.byKey(const ValueKey('kpi-value-Low Stock')))
          .data,
      '1',
    );
    expect(
      tester
          .widget<Text>(find.byKey(const ValueKey('kpi-value-Inventory Value')))
          .data,
      '₱1,240.50',
    );

    await tester.ensureVisible(find.byTooltip('Hide inventory value'));
    await tester.tap(find.byTooltip('Hide inventory value'));
    await tester.pumpAndSettle();
    expect(find.text('******'), findsOneWidget);
    expect(find.byTooltip('Show inventory value'), findsOneWidget);

    await tester.ensureVisible(find.byTooltip('Show inventory value'));
    await tester.tap(find.byTooltip('Show inventory value'));
    await tester.pumpAndSettle();
    expect(find.text('₱1,240.50'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('confirms before logging out', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    SharedPreferences.setMockInitialValues({'token': 'test-token'});
    final auth = AuthService()..isLoggedIn = true;
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<ApiService>.value(value: _DashboardApiService()),
          ChangeNotifierProvider<AuthService>.value(value: auth),
          ChangeNotifierProvider<ThemeProvider>.value(value: ThemeProvider()),
        ],
        child: const MaterialApp(home: HomeScreen()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Log out'));
    await tester.pumpAndSettle();
    expect(find.text('Log out?'), findsOneWidget);
    expect(auth.isLoggedIn, isTrue);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(find.text('Log out?'), findsNothing);
    expect(auth.isLoggedIn, isTrue);

    await tester.tap(find.byTooltip('Log out'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Log out').last);
    await tester.pumpAndSettle();
    expect(auth.isLoggedIn, isFalse);
    expect(tester.takeException(), isNull);
  });
}

class _DelayedDashboardApiService extends ApiService {
  final dashboard = Completer<Map<String, dynamic>>();
  final products = Completer<List<Map<String, dynamic>>>();

  @override
  Future<dynamic> get(String path) {
    if (path == '/dashboard') return dashboard.future;
    if (path == '/products') return products.future;
    throw StateError('Unexpected API request: $path');
  }
}

Future<void> _pumpDashboard(
  WidgetTester tester, {
  _DashboardApiService? api,
}) async {
  SharedPreferences.setMockInitialValues({});
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        Provider<ApiService>.value(value: api ?? _DashboardApiService()),
        ChangeNotifierProvider<AuthService>.value(value: AuthService()),
        ChangeNotifierProvider<ThemeProvider>.value(value: ThemeProvider()),
      ],
      child: const MaterialApp(home: HomeScreen()),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _scrollUntilFound(
  WidgetTester tester,
  Finder target,
  double offset,
) async {
  for (var attempt = 0; attempt < 8; attempt++) {
    if (target.evaluate().isNotEmpty) {
      await tester.ensureVisible(target);
      await tester.pumpAndSettle();
      return;
    }
    await tester.dragFrom(const Offset(195, 700), Offset(0, offset));
    await tester.pumpAndSettle();
  }
  expect(target, findsOneWidget);
}

class _EmptyDashboardApiService extends ApiService {
  @override
  Future<dynamic> get(String path) async {
    if (path == '/dashboard') {
      return {
        'stats': {
          'total_products': 0,
          'total_stock': 0,
          'low_stock_count': 0,
          'inventory_value': 0,
        },
        'low_stock_products': {'message': 'No products'},
        'recent_transactions': null,
      };
    }
    if (path == '/products') return [];
    throw StateError('Unexpected API request: $path');
  }
}

class _DashboardApiService extends ApiService {
  _DashboardApiService({
    this.fillInitialPage = false,
    this.includeAudit = false,
  });

  final bool fillInitialPage;
  final bool includeAudit;
  int? requestedCursorId;

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
          'inventory_value': '1240.50',
        },
        'low_stock_products': [
          {'name': 'Tea', 'quantity': 2, 'min_stock': 5},
        ],
        'recent_transactions': [
          if (includeAudit)
            {
              'id': -3,
              'product_id': null,
              'product_name': 'Sparkling Apple Cider',
              'category_name': null,
              'type': 'AUDIT_EDIT',
              'quantity': 0,
              'action': 'Admin edited product Sparkling Apple Cider',
              'details': '{"productId":3}',
              'created_at': '2026-10-25 01:30:00',
            },
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
          for (var id = 3; id <= (fillInitialPage ? 20 : 7); id++)
            {
              'id': id,
              'product_id': 1,
              'product_name': 'Historical item $id',
              'category_name': 'Beverages',
              'type': 'IN',
              'quantity': id,
              'created_at': DateTime(
                2026,
                10,
                22,
              ).subtract(Duration(days: id - 3)).toString(),
            },
        ],
      };
    }
    throw StateError('Unexpected API request: $path');
  }

  @override
  Future<List<Map<String, dynamic>>> getDashboardTransactions({
    String? beforeCreatedAt,
    int? beforeId,
  }) async {
    requestedCursorId = beforeId;
    return [
      {
        'id': 21,
        'product_id': 1,
        'product_name': 'Loaded older entry',
        'category_name': 'Beverages',
        'type': 'OUT',
        'quantity': 1,
        'created_at': '2026-10-01 01:30:00',
      },
    ];
  }
}
