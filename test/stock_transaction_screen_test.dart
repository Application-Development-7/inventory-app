import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inventory_app/screens/stock_transaction_screen.dart';
import 'package:inventory_app/services/api_service.dart';
import 'package:provider/provider.dart';

void main() {
  for (final brightness in [Brightness.light, Brightness.dark]) {
    testWidgets('styles stock dialog for $brightness mode', (
      WidgetTester tester,
    ) async {
      final colorScheme = ColorScheme.fromSeed(
        seedColor: Colors.teal,
        brightness: brightness,
      );
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(colorScheme: colorScheme),
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => showDialog<void>(
                  context: context,
                  builder: (_) => const StockTransactionScreen(
                    product: {'id': 12, 'name': 'Tea', 'quantity': 8},
                    type: 'OUT',
                  ),
                ),
                child: const Text('Open stock form'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open stock form'));
      await tester.pumpAndSettle();

      final dialog = tester.widget<Dialog>(find.byType(Dialog));
      expect(dialog.backgroundColor, colorScheme.surface);
      final title = tester.widget<Text>(find.text('Stock Out'));
      expect(title.style?.color, colorScheme.onSurface);
      final subtitle = tester.widget<Text>(find.text('Tea'));
      expect(subtitle.style?.color, colorScheme.onSurface);

      final banner = find.ancestor(
        of: find.text('Record a sale'),
        matching: find.byType(Container),
      );
      final bannerContainer = tester.widgetList<Container>(banner).first;
      expect(
        (bannerContainer.decoration! as BoxDecoration).color,
        colorScheme.error.withValues(alpha: 0.15),
      );

      expect(
        tester
            .widget<Icon>(find.byIcon(Icons.remove_circle_outline_rounded))
            .color,
        isNull,
      );
      final dialogTheme = tester
          .widgetList<Theme>(
            find.descendant(
              of: find.byType(Dialog),
              matching: find.byType(Theme),
            ),
          )
          .first;
      expect(
        dialogTheme.data.inputDecorationTheme.fillColor,
        colorScheme.surfaceContainerHighest.withValues(alpha: 0.38),
      );

      expect(
        tester.widget<OutlinedButton>(find.byType(OutlinedButton)),
        isNotNull,
      );
      final confirmButton = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Confirm stock out'),
      );
      expect(
        confirmButton.style?.backgroundColor?.resolve({}),
        colorScheme.error,
      );
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('shows a success snackbar after stock is updated', (
    WidgetTester tester,
  ) async {
    final api = _StockApiService();
    await tester.pumpWidget(
      Provider<ApiService>.value(
        value: api,
        child: MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => showDialog<void>(
                  context: context,
                  builder: (_) => const StockTransactionScreen(
                    product: {'id': 12, 'name': 'Tea', 'quantity': 8},
                    type: 'IN',
                  ),
                ),
                child: const Text('Open stock form'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open stock form'));
    await tester.pumpAndSettle();
    expect(find.text('Stock In'), findsOneWidget);
    expect(find.text('Tea'), findsOneWidget);
    expect(find.text('Add to inventory'), findsOneWidget);
    expect(find.text('8 units on hand'), findsOneWidget);
    expect(find.byKey(const ValueKey('stock-quantity')), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);
    await tester.tap(find.text('Confirm stock in'));
    await tester.pumpAndSettle();

    expect(api.submittedPath, '/stock');
    expect(find.text('Stock updated successfully!'), findsOneWidget);
    final snackBar = tester.widget<SnackBar>(find.byType(SnackBar));
    expect(snackBar.behavior, SnackBarBehavior.floating);
    expect(snackBar.backgroundColor, Colors.green);
    expect(tester.takeException(), isNull);
  });
}

class _StockApiService extends ApiService {
  String? submittedPath;

  @override
  Future<dynamic> post(String path, Map body, {bool auth = true}) async {
    submittedPath = path;
    return {'id': 5};
  }
}
