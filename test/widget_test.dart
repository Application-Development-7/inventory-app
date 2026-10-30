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
import 'package:inventory_app/screens/home_screen.dart';
import 'package:inventory_app/screens/login_screen.dart';
import 'package:inventory_app/screens/register_screen.dart';
import 'package:inventory_app/screens/trends_screen.dart';
import 'package:inventory_app/services/api_service.dart';
import 'package:inventory_app/services/auth_service.dart';
import 'package:inventory_app/services/theme_provider.dart';
import 'package:inventory_app/widgets/demand_forecast_card.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('applies soft page transitions across requested platforms', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    const platforms = {
      TargetPlatform.android,
      TargetPlatform.iOS,
      TargetPlatform.windows,
      TargetPlatform.macOS,
      TargetPlatform.linux,
    };

    for (final theme in [app.theme!, app.darkTheme!]) {
      final builders = theme.pageTransitionsTheme.builders;
      expect(builders.keys, containsAll(platforms));
      expect(
        builders.values.map((builder) => builder.runtimeType).toSet(),
        hasLength(1),
      );
    }
  });

  testWidgets('shows the Stockwise sign-in screen', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const MyApp());

    expect(find.text('Stockwise'), findsNothing);
    expect(find.text('WELCOME BACK'), findsOneWidget);
    expect(find.text('Sign in to Stockwise'), findsOneWidget);
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
    expect(find.text('Forgot password?'), findsOneWidget);
    expect(find.text('Continue with Google'), findsNothing);
  });

  testWidgets('shows split-screen branding on desktop login', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await tester.binding.setSurfaceSize(const Size(1280, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    expect(
      find.text('Turn your inventory into your advantage.'),
      findsOneWidget,
    );
    expect(find.text('Organized product catalog'), findsOneWidget);
    expect(find.text('AI-powered demand forecasting'), findsOneWidget);
    expect(find.text('Actionable low-stock alerts'), findsOneWidget);
    expect(find.text('₱1.24M'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'keeps login inputs and remember text light under dark app theme',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(theme: ThemeData.dark(), home: const LoginScreen()),
      );
      await tester.pumpAndSettle();

      final fields = tester.widgetList<TextField>(find.byType(TextField));
      for (final field in fields) {
        expect(field.style?.color, Colors.black87);
        expect(field.decoration?.filled, isTrue);
        expect(field.decoration?.fillColor, Colors.white);
        expect(
          field.decoration?.enabledBorder?.borderSide.color,
          const Color(0xFFE2DFE6),
        );
      }

      final rememberText = tester.widget<Text>(find.text('Remember me'));
      expect(rememberText.style?.color, const Color(0xFF333039));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('toggles login password visibility and remember me checkbox', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    var passwordField = tester
        .widgetList<TextField>(find.byType(TextField))
        .last;
    expect(passwordField.obscureText, isTrue);
    await tester.tap(find.text('Show'));
    await tester.pumpAndSettle();
    passwordField = tester.widgetList<TextField>(find.byType(TextField)).last;
    expect(passwordField.obscureText, isFalse);

    await tester.tap(find.byType(Checkbox));
    await tester.pumpAndSettle();
    expect(tester.widget<Checkbox>(find.byType(Checkbox)).value, isTrue);
  });

  testWidgets('shows desktop dashboard sidebar and responsive content', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await tester.binding.setSurfaceSize(const Size(1280, 900));
    final api = _FakeHomeApiService();
    final auth = AuthService()..username = 'admin';
    final theme = ThemeProvider();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<ApiService>.value(value: api),
          ChangeNotifierProvider<AuthService>.value(value: auth),
          ChangeNotifierProvider<ThemeProvider>.value(value: theme),
        ],
        child: const MaterialApp(home: HomeScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Stockwise'), findsOneWidget);
    expect(find.text('Inventory Health'), findsOneWidget);
    expect(find.text('Good morning, admin'), findsOneWidget);
    expect(find.text('Recent Activity'), findsOneWidget);
    expect(find.byType(LineChart), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
    final layoutError = tester.takeException();
    expect(layoutError, isNull);
    await tester.binding.setSurfaceSize(null);
  });

  testWidgets('keeps bottom navigation on narrow screens', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await tester.binding.setSurfaceSize(const Size(390, 844));
    final api = _FakeHomeApiService();
    final auth = AuthService()..username = 'admin';
    final theme = ThemeProvider();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<ApiService>.value(value: api),
          ChangeNotifierProvider<AuthService>.value(value: auth),
          ChangeNotifierProvider<ThemeProvider>.value(value: theme),
        ],
        child: const MaterialApp(home: HomeScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.text('Stockwise'), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.binding.setSurfaceSize(null);
  });

  testWidgets('opens the account creation screen from login', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Create an account'));
    await tester.pumpAndSettle();

    expect(find.text('CREATE YOUR WORKSPACE'), findsOneWidget);
    expect(find.text('Start managing smarter'), findsOneWidget);
    expect(find.text('Username'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
    expect(find.text('Confirm password'), findsNothing);
    expect(find.text('Create account'), findsOneWidget);
    expect(find.text('Continue with Google'), findsNothing);
    expect(find.text('Already have an account? '), findsOneWidget);
  });

  testWidgets('shows registration branding on desktop', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1280, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(const MaterialApp(home: RegisterScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Organized product catalog'), findsOneWidget);
    expect(find.text('AI-powered demand forecasting'), findsOneWidget);
    expect(find.text('Actionable low-stock alerts'), findsOneWidget);
    expect(find.text('Start managing smarter'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('requires terms agreement before registration', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: RegisterScreen()));
    await tester.pumpAndSettle();

    expect(find.byType(TextFormField), findsNWidgets(2));
    await tester.tap(find.text('Create account'));
    await tester.pumpAndSettle();

    expect(find.text('Enter a username'), findsOneWidget);
    expect(find.text('Enter a password'), findsOneWidget);
    expect(find.text('Please accept the terms to continue'), findsOneWidget);
  });

  testWidgets('shows historical chart and forecast table', (
    WidgetTester tester,
  ) async {
    final trend = {
      'status': 'OK',
      'product_name': 'Coffee',
      'label': 'RISING',
      'confidence': '80',
      'history': [
        {'year': '2026', 'month': '1', 'demand': '12'},
        {'year': '2026', 'month': '2', 'demand': '15'},
      ],
      'projections': [
        {
          'year': '2026',
          'month': '3',
          'predicted_demand': '18',
          'confidence': '75',
          'direction': 'UP',
        },
        {
          'year': '2026',
          'month': '4',
          'predicted_demand': '24',
          'confidence': '70',
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

    expect(find.text('Individual Product Trends'), findsOneWidget);
    expect(find.text('Product'), findsOneWidget);
    expect(find.text('Demand overview'), findsOneWidget);
    expect(
      find.text('Need at least 3 months of stock-out history'),
      findsOneWidget,
    );
    await tester.scrollUntilVisible(
      find.text('Top Products in ${_monthName(DateTime.now().month)}'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    expect(
      find.text('Top Products in ${_monthName(DateTime.now().month)}'),
      findsOneWidget,
    );
    expect(find.byType(BarChart), findsOneWidget);
    expect(
      api.lastTopProductsPath,
      '/analytics/top-products?month=${DateTime.now().month}&view=monthly',
    );
    expect(
      find.text(
        'Recommendation: Stock up on Coffee for next month based on current sales velocity.',
      ),
      findsOneWidget,
    );

    final selectedMonth = DateTime.now().month % 12 + 1;
    await tester.scrollUntilVisible(
      find.byType(DropdownButtonFormField<int>),
      100,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.byType(DropdownButtonFormField<int>));
    await tester.pumpAndSettle();
    await tester.tap(find.text(_monthName(selectedMonth)).last);
    await tester.pumpAndSettle();
    expect(
      api.lastTopProductsPath,
      '/analytics/top-products?month=$selectedMonth&view=monthly',
    );

    await tester.scrollUntilVisible(
      find.byKey(const Key('product-selector')),
      -300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.byKey(const Key('product-selector')));
    await tester.pumpAndSettle();
    expect(find.byType(Dialog), findsOneWidget);
    final dialog = find.byType(Dialog);
    expect(
      find.descendant(of: dialog, matching: find.text('Coffee')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: dialog, matching: find.text('Tea')),
      findsOneWidget,
    );
    await tester.enterText(find.byType(TextField).last, 'tea');
    await tester.pumpAndSettle();
    expect(
      find.descendant(of: dialog, matching: find.text('Coffee')),
      findsNothing,
    );
    expect(
      find.descendant(of: dialog, matching: find.text('Tea')),
      findsOneWidget,
    );
    await tester.tap(find.descendant(of: dialog, matching: find.text('Tea')));
    await tester.pumpAndSettle();

    expect(api.lastForecastPath, '/forecast/product/2?view=monthly');
    expect(find.text('URGENT: Reorder stock now'), findsOneWidget);
    expect(find.text('Tea'), findsWidgets);
    expect(
      find.text('Need at least 3 months of stock-out history'),
      findsOneWidget,
    );

    final horizonDropdown = find.byType(DropdownButton<String>).first;
    await tester.scrollUntilVisible(
      horizonDropdown,
      -300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(horizonDropdown);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Next 3 years').last);
    await tester.pumpAndSettle();
    expect(api.lastForecastPath, '/forecast/product/2?view=yearly');
    expect(api.lastTrendsPath, '/forecast/trends?view=yearly');
    expect(
      find.text('Need at least 3 years of stock-out history'),
      findsOneWidget,
    );
    expect(
      find.text('Top Products in ${_monthName(selectedMonth)}'),
      findsOneWidget,
    );
  });

  testWidgets(
    'selector updates the single overview chart for selected product',
    (WidgetTester tester) async {
      final api = _FakeForecastApiService(withForecast: true);
      await tester.pumpWidget(
        Provider<ApiService>.value(
          value: api,
          child: const MaterialApp(home: Scaffold(body: TrendsScreen())),
        ),
      );
      await tester.pumpAndSettle();

      expect(api.lastTrendsPath, '/forecast/trends?view=monthly');
      expect(find.byType(LineChart), findsOneWidget);
      final initialChart = tester.widget<LineChart>(find.byType(LineChart));
      final initialDemand = initialChart.data.lineBarsData.first.spots.first.y;
      expect(initialDemand, 12);

      await tester.tap(find.byKey(const Key('product-selector')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).last, 'tea');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Tea').last);
      await tester.pumpAndSettle();

      expect(api.lastForecastPath, '/forecast/product/2?view=monthly');
      expect(find.byType(LineChart), findsOneWidget);
      final selectedChart = tester.widget<LineChart>(find.byType(LineChart));
      expect(selectedChart.data.lineBarsData.first.spots.first.y, 102);
      expect(find.text('Product Report'), findsOneWidget);
      expect(find.text('In stock'), findsOneWidget);
      expect(find.text('₱2.00'), findsOneWidget);
    },
  );

  testWidgets('shows the responsive forecast dashboard for available data', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final api = _FakeForecastApiService(withForecast: true);
    await tester.pumpWidget(
      Provider<ApiService>.value(
        value: api,
        child: const MaterialApp(home: Scaffold(body: TrendsScreen())),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Demand Forecast'), findsOneWidget);
    expect(find.text('AI recommendations'), findsOneWidget);
    expect(find.text('Product Report'), findsOneWidget);
    expect(find.text('Current Stock'), findsOneWidget);
    expect(find.text('Minimum Stock'), findsOneWidget);
    expect(find.text('Unit Price'), findsOneWidget);
    expect(find.text('Low stock'), findsOneWidget);
    expect(find.text('Stock up on Coffee'), findsOneWidget);
    expect(find.text('Reorder Tea early'), findsOneWidget);
    expect(find.text('Demand overview'), findsOneWidget);
    expect(
      find.text('Demand is projected to rise 15% next month.'),
      findsOneWidget,
    );
    expect(find.text('URGENT: Reorder stock now'), findsOneWidget);
    expect(find.text('Reorder Tea early'), findsOneWidget);
    final theme = Theme.of(tester.element(find.text('AI recommendations')));
    final urgentContainer = tester.widget<Container>(
      find
          .ancestor(
            of: find.text('URGENT: Reorder stock now'),
            matching: find.byType(Container),
          )
          .first,
    );
    final urgentDecoration = urgentContainer.decoration! as BoxDecoration;
    expect(
      (urgentDecoration.border! as Border).top.color,
      theme.colorScheme.error.withValues(alpha: 0.55),
    );
    expect(find.byType(LineChart), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.scrollUntilVisible(
      find.text('Forecast accuracy'),
      240,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Forecast accuracy'), findsOneWidget);
    expect(find.text('Potential stockouts'), findsOneWidget);
    expect(find.text('Revenue opportunity'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.textContaining('Top Products in'),
      240,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.byType(BarChart), findsOneWidget);
    expect(tester.takeException(), isNull);

    expect(find.text('Individual Product Trends'), findsOneWidget);
    expect(find.textContaining('Peak:'), findsOneWidget);
    expect(find.textContaining('Confidence:'), findsOneWidget);
    expect(find.text('Date'), findsOneWidget);
    expect(find.text('Demand'), findsOneWidget);
    expect(find.text('Trend'), findsOneWidget);
    expect(find.byType(LineChart), findsOneWidget);
    expect(tester.takeException(), isNull);
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
  _FakeForecastApiService({this.withForecast = false});

  final bool withForecast;
  String? lastForecastPath;
  String? lastTopProductsPath;
  String? lastTrendsPath;

  @override
  Future<dynamic> get(String path) async {
    if (path == '/products') {
      return [
        {
          'id': 1,
          'name': 'Coffee',
          'price': '4.5',
          'quantity': '2',
          'min_stock': '10',
        },
        {
          'id': 2,
          'name': 'Tea',
          'price': '2.0',
          'quantity': '10',
          'min_stock': '5',
        },
      ];
    }
    if (path.startsWith('/forecast/trends')) {
      lastTrendsPath = path;
      return {
        'trends': const [],
        'recommendations': [
          {
            'type': 'HIGH_PRIORITY',
            'title': 'Stock up on Coffee',
            'description': 'Demand is projected to rise 15% next month.',
          },
          {
            'type': 'URGENT',
            'title': 'URGENT: Reorder stock now',
            'description': 'Current stock is below the minimum.',
          },
          {
            'type': 'OPPORTUNITY',
            'title': 'Reorder Tea early',
            'description': 'Lead time may increase.',
          },
        ],
      };
    }

    if (path.startsWith('/analytics/top-products')) {
      lastTopProductsPath = path;
      return [
        {'product_id': '1', 'product_name': 'Coffee', 'total_sold': '18'},
        {'product_id': '2', 'product_name': 'Tea', 'total_sold': '11'},
      ];
    }
    lastForecastPath = path;
    final isTea = path.startsWith('/forecast/product/2');
    if (withForecast) {
      final demand = isTea ? 102 : 12;
      return {
        'product': {'id': isTea ? 2 : 1, 'name': isTea ? 'Tea' : 'Coffee'},
        'status': 'OK',
        'view': path.contains('view=yearly') ? 'yearly' : 'monthly',
        'label': 'RISING',
        'confidence': '82',
        'peak_month': {'month': '11', 'year': '2026'},
        'history': [
          {'year': '2026', 'month': '1', 'demand': '$demand'},
          {'year': '2026', 'month': '2', 'demand': '${demand + 3}'},
          {'year': '2026', 'month': '3', 'demand': '${demand + 6}'},
        ],
        'projections': [
          {
            'year': '2026',
            'month': '4',
            'predicted_demand': '${demand + 8}',
            'confidence': '78',
            'direction': 'UP',
          },
          {
            'year': '2026',
            'month': '5',
            'predicted_demand': '${demand + 11}',
            'confidence': '74',
            'direction': 'UP',
          },
        ],
      };
    }
    return {
      'product': {'id': isTea ? 2 : 1, 'name': isTea ? 'Tea' : 'Coffee'},
      'status': 'INSUFFICIENT_DATA',
      'message': path.contains('view=yearly')
          ? 'Need at least 3 years of stock-out history'
          : 'Need at least 3 months of stock-out history',
      'data_points': 1,
    };
  }
}

class _FakeHomeApiService extends ApiService {
  @override
  Future<dynamic> get(String path) async {
    if (path == '/dashboard') {
      return {
        'stats': {'total_products': 3, 'total_stock': 42, 'low_stock_count': 1},
        'low_stock_products': [
          {'id': 1, 'name': 'Coffee', 'quantity': 2, 'min_stock': 5},
        ],
        'recent_transactions': [
          {
            'id': 1,
            'product_name': 'Coffee',
            'type': 'IN',
            'quantity': 10,
            'created_at': '2026-10-28T10:00:00',
            'category_name': 'Drinks',
          },
        ],
      };
    }
    if (path == '/products') {
      return [
        {'id': 1, 'name': 'Coffee', 'category_name': 'Drinks', 'quantity': 20},
        {'id': 2, 'name': 'Tea', 'category_name': 'Drinks', 'quantity': 22},
      ];
    }
    throw StateError('Unexpected API request: $path');
  }
}
