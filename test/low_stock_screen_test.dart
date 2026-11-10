import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inventory_app/screens/low_stock_screen.dart';
import 'package:inventory_app/services/api_service.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('filters categories and toggles to responsive low-stock grid', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final api = _LowStockApiService();
    await tester.pumpWidget(
      Provider<ApiService>.value(
        value: api,
        child: const MaterialApp(home: Scaffold(body: LowStockScreen())),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Coffee'), findsOneWidget);
    expect(find.text('Tea'), findsOneWidget);
    expect(find.text('Soap'), findsOneWidget);
    expect(find.text('PRODUCT'), findsOneWidget);
    expect(find.text('CATEGORY'), findsNothing);
    expect(find.text('STOCK'), findsOneWidget);
    expect(find.text('MIN'), findsOneWidget);
    expect(find.text('Low'), findsNWidgets(2));
    expect(find.text('Out'), findsOneWidget);
    expect(find.byType(PopupMenuButton<String>), findsNWidgets(3));
    expect(find.byType(SliverList), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is SingleChildScrollView &&
            widget.scrollDirection == Axis.horizontal,
      ),
      findsNothing,
    );

    await tester.enterText(find.byType(TextField), 'COF-001');
    await tester.pumpAndSettle();
    expect(find.text('Coffee'), findsOneWidget);
    expect(find.text('Tea'), findsNothing);
    expect(find.text('Soap'), findsNothing);

    await tester.enterText(find.byType(TextField), '');
    await tester.pumpAndSettle();
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Beverages').last);
    await tester.pumpAndSettle();

    expect(find.text('Coffee'), findsOneWidget);
    expect(find.text('Tea'), findsOneWidget);
    expect(find.text('Soap'), findsNothing);

    await tester.tap(find.byTooltip('Show as grid'));
    await tester.pumpAndSettle();
    final grid = tester.widget<SliverGrid>(find.byType(SliverGrid));
    final delegate =
        grid.gridDelegate as SliverGridDelegateWithMaxCrossAxisExtent;
    expect(delegate.maxCrossAxisExtent, 350);
    expect(delegate.mainAxisExtent, 220);
    expect(api.requestedPaths, ['/products/low-stock']);
    expect(find.byIcon(Icons.warning_amber_rounded), findsNWidgets(2));
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'paginates low-stock rows ten at a time without horizontal scroll',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        Provider<ApiService>.value(
          value: _PagedLowStockApiService(),
          child: const MaterialApp(home: Scaffold(body: LowStockScreen())),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Low-stock product 1'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('Low-stock product 10'),
        120,
        scrollable: find.byType(Scrollable).last,
      );
      expect(find.text('Low-stock product 10'), findsOneWidget);
      expect(find.text('Low-stock product 11'), findsNothing);
      expect(find.text('Showing 10 of 12'), findsOneWidget);
      expect(find.text('1/2'), findsOneWidget);
      expect(
        tester
            .widget<IconButton>(
              find.ancestor(
                of: find.byTooltip('Previous page'),
                matching: find.byType(IconButton),
              ),
            )
            .onPressed,
        isNull,
      );

      await tester.tap(find.byTooltip('Next page'));
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.text('Low-stock product 11'),
        120,
        scrollable: find.byType(Scrollable).last,
      );
      expect(find.text('Low-stock product 11'), findsOneWidget);
      expect(find.text('Showing 2 of 12'), findsOneWidget);
      expect(find.text('2/2'), findsOneWidget);
      expect(
        tester
            .widget<IconButton>(
              find.ancestor(
                of: find.byTooltip('Next page'),
                matching: find.byType(IconButton),
              ),
            )
            .onPressed,
        isNull,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('shows an all-stocked-up empty state', (
    WidgetTester tester,
  ) async {
    final api = _LowStockApiService(empty: true);
    await tester.pumpWidget(
      Provider<ApiService>.value(
        value: api,
        child: const MaterialApp(home: Scaffold(body: LowStockScreen())),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('All stocked up!'), findsOneWidget);
    expect(api.requestedPaths, ['/products/low-stock']);
    expect(tester.takeException(), isNull);
  });
}

class _PagedLowStockApiService extends ApiService {
  @override
  Future<dynamic> get(String path) async {
    if (path != '/products/low-stock') {
      throw StateError('Unexpected API request: $path');
    }
    return List.generate(
      12,
      (index) => {
        'id': index + 1,
        'name': 'Low-stock product ${index + 1}',
        'sku': 'LOW-${index + 1}',
        'category_name': 'Category',
        'quantity': index % 2,
        'min_stock': 5,
      },
    );
  }
}

class _LowStockApiService extends ApiService {
  _LowStockApiService({this.empty = false});

  final bool empty;
  final requestedPaths = <String>[];

  @override
  Future<dynamic> get(String path) async {
    requestedPaths.add(path);
    if (path != '/products/low-stock') {
      throw StateError('Unexpected API request: $path');
    }
    if (empty) return [];
    return [
      {
        'id': 1,
        'name': 'Coffee',
        'sku': 'COF-001',
        'category_name': 'Beverages',
        'quantity': '2',
        'min_stock': '10',
      },
      {
        'id': 2,
        'name': 'Tea',
        'category_name': 'Beverages',
        'quantity': 1,
        'min_stock': 8,
      },
      {
        'id': 3,
        'name': 'Soap',
        'category_name': 'Household',
        'quantity': null,
        'min_stock': '4',
      },
    ];
  }
}
