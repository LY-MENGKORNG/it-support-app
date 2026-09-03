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

    test('flatMap chains a step that can fail', () {
      Result<int> parse(String value) => switch (int.tryParse(value)) {
        final int parsed => Result.ok(parsed),
        null => Result.error(FormatException('not a number: $value')),
      };

      expect(const Result.ok('7').flatMap(parse).asOk.value, 7);
      expect(const Result.ok('x').flatMap(parse), isA<Error<int>>());

      final failure = Exception('boom');
      final chained = Result<String>.error(failure).flatMap(parse);
      expect(chained.asError.error, failure);
    });
  });

  // The bridge between Dart's unchecked exceptions and this app's Results.
  // Every `try`/`catch` in the app is supposed to be one of these.
  group('Result.safeTry', () {
    test('a returned value is Ok', () {
      expect(Result.safeTry(() => 2 + 2).asOk.value, 4);
    });

    test('a thrown exception becomes Error', () {
      final result = Result.safeTry<int>(
        () => throw const FormatException('bad input'),
      );

      expect(result.asError.error, isA<FormatException>());
    });

    test('onError translates the failure into a domain exception', () {
      final result = Result.safeTry<int>(
        () => throw const FormatException('bad input'),
        onError: (error, _) => Exception('could not read the value'),
      );

      expect('${result.asError.error}', contains('could not read the value'));
    });

    // A bug is not a failure to report: swallowing it would hide it behind
    // whatever message the UI shows for an error result.
    test('an Error keeps travelling instead of becoming a Result', () {
      expect(
        () => Result.safeTry<int>(() => throw StateError('bug')),
        throwsStateError,
      );
    });

    test('a mapper may still claim one', () {
      final result = Result.safeTry<int>(
        () => throw ArgumentError('bad'),
        onError: (error, _) => Exception('handled: $error'),
      );

      expect('${result.asError.error}', contains('handled'));
    });
  });

  group('Result.safeTryAsync', () {
    test('a completed future is Ok', () async {
      final result = await Result.safeTryAsync(() async => 'done');

      expect(result.asOk.value, 'done');
    });

    test('a rejected future becomes Error', () async {
      final result = await Result.safeTryAsync<String>(
        () async => throw Exception('nope'),
      );

      expect(result, isA<Error<String>>());
    });

    // The `await` has to sit inside the `try`: a rejection that arrives after
    // an asynchronous gap must be caught the same way a synchronous throw is.
    test('a rejection after a gap is caught too', () async {
      final result = await Result.safeTryAsync<String>(() async {
        await Future<void>.delayed(Duration.zero);
        throw Exception('late');
      });

      expect(result, isA<Error<String>>());
    });
  });
}
