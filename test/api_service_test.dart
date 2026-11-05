import 'package:flutter_test/flutter_test.dart';
import 'package:inventory_app/services/api_service.dart';

void main() {
  test('parses a JSON array of objects', () {
    final result = ApiService.parseListResponse([
      {'id': 1, 'name': 'Coffee'},
    ], endpoint: 'Products');

    expect(result, [
      {'id': 1, 'name': 'Coffee'},
    ]);
  });

  test('reports an API error object instead of casting it to a list', () {
    expect(
      () => ApiService.parseListResponse({
        'message': 'Database error',
      }, endpoint: 'Products'),
      throwsA(
        isA<FormatException>()
            .having((error) => error.message, 'message', contains('Products'))
            .having(
              (error) => error.message,
              'message',
              contains('Database error'),
            ),
      ),
    );
  });

  test('rejects non-object entries in a list response', () {
    expect(
      () =>
          ApiService.parseListResponse(['invalid item'], endpoint: 'Products'),
      throwsA(isA<FormatException>()),
    );
  });
}
