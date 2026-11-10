import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inventory_app/screens/register_screen.dart';
import 'package:inventory_app/widgets/legal_document_dialog.dart';

void main() {
  testWidgets('renders the exact Privacy Policy from Register', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: RegisterScreen()));

    await tester.tap(find.text('Privacy Policy'));
    await tester.pumpAndSettle();

    expect(find.text('Privacy Policy'), findsNWidgets(2));
    expect(find.text('1. Information We Collect'), findsOneWidget);
    expect(
      find.text(
        'We collect your username, securely hashed passwords, and the inventory data you input (products, quantities, prices). We also log stock transactions and audit events (who added/edited/deleted items).',
      ),
      findsOneWidget,
    );
    expect(find.text('5. Your Rights'), findsOneWidget);
    expect(
      find.text(
        'You have the right to access, update, or delete the personal information and inventory data stored in your workspace.',
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byType(Dialog),
        matching: find.byType(SingleChildScrollView),
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('adapts the document dialog to dark mode', (
    WidgetTester tester,
  ) async {
    final theme = ThemeData.dark();
    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => showDialog<void>(
                context: context,
                builder: (_) => const LegalDocumentDialog(
                  document: LegalDocument.termsOfService,
                ),
              ),
              child: const Text('Open legal document'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open legal document'));
    await tester.pumpAndSettle();

    final dialog = tester.widget<Dialog>(find.byType(Dialog));
    final title = tester.widget<Text>(find.text('Terms of Service'));
    expect(dialog.backgroundColor, theme.colorScheme.surface);
    expect(title.style?.color, theme.colorScheme.onSurface);
    expect(find.text('5. Limitation of Liability'), findsOneWidget);
    expect(
      find.text(
        'Stockwise shall not be liable for any indirect, incidental, or consequential damages resulting from the use or inability to use the service, including but not limited to inventory loss or data inaccuracies.',
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}
