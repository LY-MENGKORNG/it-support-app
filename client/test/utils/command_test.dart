import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:app/utils/command.dart';
import 'package:app/utils/result.dart';

void main() {
  group('Command0', () {
    test('reports running, then completed', () async {
      final completer = Completer<Result<int>>();
      final command = Command0<int>(() => completer.future);

      expect(command.running, isFalse);
      expect(command.completed, isFalse);

      final pending = command.execute();
      expect(command.running, isTrue);

      completer.complete(const Result.ok(7));
      await pending;

      expect(command.running, isFalse);
      expect(command.completed, isTrue);
      expect(command.error, isFalse);
      expect(command.result?.asOk.value, 7);
    });

    test('reports an error without throwing', () async {
      final failure = Exception('nope');
      final command = Command0<int>(() async => Result.error(failure));

      await command.execute();

      expect(command.error, isTrue);
      expect(command.completed, isFalse);
      expect(command.exception, failure);
    });

    // This is the guarantee that stops a double-tap from firing two writes.
    test('ignores execute() while already running', () async {
      var calls = 0;
      final completer = Completer<Result<void>>();
      final command = Command0<void>(() {
        calls++;
        return completer.future;
      });

      final first = command.execute();
      await command.execute();
      await command.execute();

      expect(calls, 1);

      completer.complete(const Result.ok(null));
      await first;
      expect(calls, 1);
    });

    test('clearResult resets the consumed state', () async {
      final command = Command0<int>(() async => const Result.ok(1));
      await command.execute();
      expect(command.completed, isTrue);

      command.clearResult();

      expect(command.completed, isFalse);
      expect(command.error, isFalse);
      expect(command.result, isNull);
    });

    test('notifies listeners on start and finish', () async {
      final command = Command0<int>(() async => const Result.ok(1));
      var notifications = 0;
      command.addListener(() => notifications++);

      await command.execute();

      expect(notifications, 2);
    });
  });

  group('Command1', () {
    test('passes its argument through', () async {
      final command = Command1<String, int>(
        (value) async => Result.ok('got $value'),
      );

      await command.execute(5);

      expect(command.result?.asOk.value, 'got 5');
    });
  });
}
