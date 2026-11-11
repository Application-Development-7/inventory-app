import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inventory_app/screens/products_screen.dart';
import 'package:inventory_app/services/api_service.dart';
import 'package:inventory_app/widgets/skeleton_loader.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('shows product-row skeletons while products load', (
    WidgetTester tester,
  ) async {
    final api = _DelayedProductsApiService();
    await tester.pumpWidget(
      Provider<ApiService>.value(
        value: api,
        child: const MaterialApp(home: ProductsScreen()),
      ),
    );
    await tester.pump();

    expect(find.byType(SkeletonLoader), findsOneWidget);
    expect(tester.takeException(), isNull);

    api.products.complete([]);
    await tester.pumpAndSettle();
    expect(find.byType(SkeletonLoader), findsNothing);
  });

  testWidgets('shows an API error object without crashing the product screen', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      Provider<ApiService>.value(
        value: _ErrorProductsApiService(),
        child: const MaterialApp(home: ProductsScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.textContaining('Products response must be a JSON array'),
      findsOneWidget,
    );
    expect(find.textContaining('Database error'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('opens the product form in a centered modal dialog', (
    WidgetTester tester,
  ) async {
    final api = _ProductsApiService();
    await tester.pumpWidget(
      Provider<ApiService>.value(
        value: api,
        child: const MaterialApp(home: ProductsScreen()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Add Product'));
    await tester.pumpAndSettle();

    expect(find.byType(Dialog), findsOneWidget);
    expect(find.text('NEW INVENTORY ITEM'), findsOneWidget);
    expect(find.text('Add a product'), findsOneWidget);
    expect(find.text('Initial stock'), findsOneWidget);
    expect(find.text('Minimum stock'), findsOneWidget);
    expect(api.requestedPaths, ['/products', '/categories']);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(find.byType(Dialog), findsNothing);
  });

  testWidgets('filters, sorts, and switches product layouts locally', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final api = _ProductsApiService();
    await tester.pumpWidget(
      Provider<ApiService>.value(
        value: api,
        child: const MaterialApp(home: ProductsScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(ListView), findsOneWidget);
    expect(find.text('Banana'), findsOneWidget);
    expect(find.text('Cereal'), findsOneWidget);
    expect(find.text('Lamp'), findsOneWidget);
    expect(find.byType(PopupMenuButton<String>), findsNWidgets(3));

    await tester.tap(find.byType(DropdownButtonFormField<String>).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Food').last);
    await tester.pumpAndSettle();

    expect(find.text('Lamp'), findsNothing);
    expect(find.text('Banana'), findsOneWidget);
    expect(find.text('Cereal'), findsOneWidget);

    await tester.tap(find.byType(DropdownButtonFormField<String>).last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Stock: High to Low').last);
    await tester.pumpAndSettle();

    expect(
      tester.getTopLeft(find.text('Banana').last).dy,
      lessThan(tester.getTopLeft(find.text('Cereal').last).dy),
    );

    await tester.tap(find.byType(DropdownButtonFormField<String>).last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Default').last);
    await tester.pumpAndSettle();

    await tester.tap(find.byType(DropdownButtonFormField<String>).last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Alphabetical: A-Z').last);
    await tester.pumpAndSettle();
    expect(
      tester.getTopLeft(find.text('Banana').last).dy,
      lessThan(tester.getTopLeft(find.text('Cereal').last).dy),
    );

    await tester.tap(find.byTooltip('Show as grid'));
    await tester.pumpAndSettle();
    expect(find.byType(GridView), findsOneWidget);
    final grid = tester.widget<GridView>(find.byType(GridView));
    final gridDelegate =
        grid.gridDelegate as SliverGridDelegateWithMaxCrossAxisExtent;
    expect(gridDelegate.maxCrossAxisExtent, 380);
    expect(gridDelegate.childAspectRatio, 1.8);
    expect(api.requestedPaths, ['/products']);
  });

  testWidgets('paginates ten products and fits the table on mobile', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(320, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      Provider<ApiService>.value(
        value: _ManyProductsApiService(),
        child: const MaterialApp(home: ProductsScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Product 1'), findsOneWidget);
    expect(find.text('Product 10'), findsOneWidget);
    expect(find.text('Product 11'), findsNothing);
    expect(find.text('CATEGORY'), findsNothing);
    expect(find.text('PRICE'), findsNothing);
    final categoryY = tester.getTopLeft(find.text('Category').first).dy;
    final sortY = tester.getTopLeft(find.text('Sort by').first).dy;
    final addY = tester.getTopLeft(find.byTooltip('Add Product')).dy;
    expect((categoryY - sortY).abs(), lessThan(1));
    expect((categoryY - addY).abs(), lessThan(1));
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is SingleChildScrollView &&
            widget.scrollDirection == Axis.horizontal,
      ),
      findsNothing,
    );
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

    expect(find.text('Product 1'), findsNothing);
    expect(find.text('Product 11'), findsOneWidget);
    expect(find.text('Showing 2 of 12 products'), findsOneWidget);
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
  });

  testWidgets('shows a red success snackbar after deleting a product', (
    WidgetTester tester,
  ) async {
    final api = _ProductsApiService();
    await tester.pumpWidget(
      Provider<ApiService>.value(
        value: api,
        child: const MaterialApp(home: ProductsScreen()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Product actions').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete').last);
    await tester.pumpAndSettle();

    expect(api.deletedPath, '/products/2');
    expect(find.text('Product deleted'), findsOneWidget);
    final snackBar = tester.widget<SnackBar>(find.byType(SnackBar));
    expect(snackBar.behavior, SnackBarBehavior.floating);
    expect(snackBar.backgroundColor, ThemeData().colorScheme.error);
    expect(tester.takeException(), isNull);
  });
}

class _DelayedProductsApiService extends ApiService {
  final products = Completer<List<Map<String, dynamic>>>();

  @override
  Future<dynamic> get(String path) {
    if (path == '/categories') return Future.value([]);
    if (path == '/products') return products.future;
    throw StateError('Unexpected API request: $path');
  }
}

class _ErrorProductsApiService extends ApiService {
  @override
  Future<dynamic> get(String path) async {
    if (path == '/products') return {'message': 'Database error'};
    throw StateError('Unexpected API request: $path');
  }
}

class _ManyProductsApiService extends ApiService {
  @override
  Future<dynamic> get(String path) async {
    if (path == '/products') {
      return List.generate(
        12,
        (index) => {
          'id': index + 1,
          'name': 'Product ${index + 1}',
          'category_name': 'Category',
          'quantity': index + 1,
          'min_stock': 2,
          'price': 1.0,
        },
      );
    }
    throw StateError('Unexpected API request: $path');
  }
}

class _ProductsApiService extends ApiService {
  final requestedPaths = <String>[];
  String? deletedPath;

  @override
  Future<dynamic> get(String path) async {
    requestedPaths.add(path);
    if (path == '/categories') {
      return [
        {'id': 1, 'name': 'Food'},
        {'id': 2, 'name': 'Home'},
      ];
    }
    if (path == '/products') {
      return [
        {
          'id': 2,
          'name': 'Cereal',
          'category_name': 'Food',
          'quantity': null,
          'min_stock': '1',
          'price': null,
        },
        {
          'id': 1,
          'name': 'Banana',
          'category_name': 'Food',
          'quantity': '9',
          'min_stock': '2',
          'price': '1.50',
        },
        {
          'id': 3,
          'name': 'Lamp',
          'category_name': 'Home',
          'quantity': 'invalid',
          'min_stock': '3',
          'price': '12.00',
        },
      ];
    }
    throw StateError('Unexpected API request: $path');
  }

  @override
  Future<dynamic> delete(String path) async {
    deletedPath = path;
    return {'message': 'Deleted'};
  }
}
