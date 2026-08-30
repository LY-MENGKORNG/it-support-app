import 'package:flutter_test/flutter_test.dart';

import 'package:app/utils/result.dart';

void main() {
  group('Result', () {
    test('Ok carries its value', () {
      const result = Result.ok(42);

      expect(result, isA<Ok<int>>());
      expect(result.asOk.value, 42);
    });

    test('Error carries its exception', () {
      final failure = Exception('nope');
      final result = Result<int>.error(failure);

      expect(result, isA<Error<int>>());
      expect(result.asError.error, failure);
    });

    // The point of the type: the compiler will not let you read a value
    // without deciding what happens when there isn't one.
    test('a switch must handle both branches', () {
      String describe(Result<int> result) => switch (result) {
        Ok<int>(:final value) => 'ok $value',
        Error<int>(:final error) => 'failed $error',
      };

      expect(describe(const Result.ok(1)), 'ok 1');
      expect(describe(Result.error(Exception('x'))), contains('failed'));
    });

    test('map transforms a value and leaves an error alone', () {
      expect(const Result.ok(2).map((value) => value * 2).asOk.value, 4);

      final failure = Exception('boom');
      final mapped = Result<int>.error(failure).map((value) => value * 2);
      expect(mapped.asError.error, failure);
    });
  });
}
