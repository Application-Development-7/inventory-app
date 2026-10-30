import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inventory_app/screens/products_screen.dart';
import 'package:inventory_app/services/api_service.dart';
import 'package:provider/provider.dart';

void main() {
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
}

class _ProductsApiService extends ApiService {
  final requestedPaths = <String>[];

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
          'id': 1,
          'name': 'Banana',
          'category_name': 'Food',
          'quantity': '9',
          'min_stock': '2',
          'price': '1.50',
        },
        {
          'id': 2,
          'name': 'Cereal',
          'category_name': 'Food',
          'quantity': null,
          'min_stock': '1',
          'price': null,
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
}
