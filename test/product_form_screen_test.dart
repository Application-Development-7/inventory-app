import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inventory_app/screens/product_form_screen.dart';
import 'package:inventory_app/services/api_service.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('validates required fields before submitting', (
    WidgetTester tester,
  ) async {
    final api = _ProductFormApi();
    await _pumpForm(tester, api);

    await tester.tap(find.text('Add product'));
    await tester.pumpAndSettle();

    expect(find.text('Product name cannot be empty'), findsOneWidget);
    expect(find.text('SKU cannot be empty'), findsOneWidget);
    expect(api.postCount, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('rejects invalid stock and price values', (
    WidgetTester tester,
  ) async {
    final api = _ProductFormApi();
    await _pumpForm(tester, api);
    await tester.enterText(find.byKey(const ValueKey('product-name')), 'Tea');
    await tester.enterText(find.byKey(const ValueKey('product-sku')), 'TEA-1');
    await tester.enterText(
      find.byKey(const ValueKey('product-quantity')),
      '12x',
    );
    await tester.enterText(find.byKey(const ValueKey('product-price')), 'abc');
    await tester.enterText(
      find.byKey(const ValueKey('product-min-stock')),
      'two',
    );

    await tester.tap(find.text('Add product'));
    await tester.pumpAndSettle();

    expect(find.text('Please enter a valid number'), findsNWidgets(2));
    expect(find.text('Please enter a valid price'), findsOneWidget);
    expect(api.postCount, 0);
  });

  testWidgets('does not send user id and shows clean API errors', (
    WidgetTester tester,
  ) async {
    final api = _ProductFormApi(failPost: true);
    await _pumpForm(tester, api);
    await tester.enterText(find.byKey(const ValueKey('product-name')), 'Tea');
    await tester.enterText(find.byKey(const ValueKey('product-sku')), 'TEA-1');

    await tester.tap(find.text('Add product'));
    await tester.pumpAndSettle();

    expect(api.postCount, 1);
    expect(api.submittedBody!.containsKey('user_id'), isFalse);
    expect(
      find.text('Unable to save product. Please try again.'),
      findsOneWidget,
    );
    expect(find.textContaining('Exception:'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('shows a success snackbar after adding a product', (
    WidgetTester tester,
  ) async {
    final api = _ProductFormApi();
    await tester.pumpWidget(
      Provider<ApiService>.value(
        value: api,
        child: MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => showDialog<void>(
                  context: context,
                  builder: (_) => const ProductFormScreen(),
                ),
                child: const Text('Open form'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open form'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const ValueKey('product-name')), 'Tea');
    await tester.enterText(find.byKey(const ValueKey('product-sku')), 'TEA-1');
    await tester.tap(find.text('Add product'));
    await tester.pumpAndSettle();

    expect(find.text('Product saved successfully!'), findsOneWidget);
    final snackBar = tester.widget<SnackBar>(find.byType(SnackBar));
    expect(snackBar.behavior, SnackBarBehavior.floating);
    expect(snackBar.backgroundColor, Colors.green);
    expect(tester.takeException(), isNull);
  });
}

Future<void> _pumpForm(WidgetTester tester, _ProductFormApi api) async {
  await tester.pumpWidget(
    Provider<ApiService>.value(
      value: api,
      child: const MaterialApp(home: ProductFormScreen()),
    ),
  );
  await tester.pumpAndSettle();
}

class _ProductFormApi extends ApiService {
  _ProductFormApi({this.failPost = false});

  final bool failPost;
  int postCount = 0;
  Map? submittedBody;

  @override
  Future<dynamic> get(String path) async {
    if (path == '/categories') return [];
    throw StateError('Unexpected API request: $path');
  }

  @override
  Future<dynamic> post(String path, Map body, {bool auth = true}) async {
    postCount++;
    submittedBody = body;
    if (failPost) throw Exception('Field user_id has no default');
    return {'id': 42};
  }
}
