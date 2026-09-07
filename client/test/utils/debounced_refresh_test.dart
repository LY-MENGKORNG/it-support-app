import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:app/utils/command.dart';
import 'package:app/utils/debounced_refresh.dart';
import 'package:app/utils/result.dart';

void main() {
  /// A command whose runs can be finished one at a time, so a trigger can be
  /// aimed at the window while another run is still in flight.
  ({Command0<void> command, int Function() runs, void Function() finish})
  controllable() {
    var runs = 0;
    final pending = <Completer<Result<void>>>[];

    return (
      command: Command0<void>(() {
        runs++;
        final completer = Completer<Result<void>>();
        pending.add(completer);
        return completer.future;
      }),
      runs: () => runs,
      finish: () => pending.removeAt(0).complete(const Result.ok(null)),
    );
  }

  group('schedule', () {
    testWidgets('one run for a burst of triggers', (tester) async {
      final it = controllable();
      final refresh = DebouncedRefresh(
        it.command,
        delay: const Duration(milliseconds: 50),
      );

      for (final letter in ['w', 'i', 'f', 'i']) {
        refresh.schedule(() {});
        await tester.pump(const Duration(milliseconds: 10));
        expect(it.runs(), 0, reason: 'still typing ($letter)');
      }

      await tester.pump(const Duration(milliseconds: 50));
      expect(it.runs(), 1);
      it.finish();
    });

    testWidgets('the change is applied when the run happens, not before', (
      tester,
    ) async {
      final it = controllable();
      final refresh = DebouncedRefresh(
        it.command,
        delay: const Duration(milliseconds: 50),
      );
      var applied = 0;

      refresh.schedule(() => applied++);
      refresh.schedule(() => applied++);
      expect(applied, 0);

      await tester.pump(const Duration(milliseconds: 50));
      expect(applied, 1, reason: 'the superseded keystroke never applied');
      it.finish();
    });

    testWidgets('cancel drops a pending run', (tester) async {
      final it = controllable();
      final refresh = DebouncedRefresh(
        it.command,
        delay: const Duration(milliseconds: 50),
      );

      refresh.schedule(() {});
      refresh.cancel();
      await tester.pump(const Duration(milliseconds: 100));

      expect(it.runs(), 0);
    });
  });

  group('now', () {
    test('triggers during a run are coalesced into one more run', () async {
      final it = controllable();
      final refresh = DebouncedRefresh(it.command);

      final first = refresh.now();
      // Both of these land while the first run is still in flight. Without
      // coalescing the command refuses them and the list is left showing
      // results for a filter the user has already changed.
      final second = refresh.now();
      final third = refresh.now();
      expect(it.runs(), 1);

      // The first run lands, which is what starts the catch-up run — so the
      // trigger that arrived too early is honoured exactly once, not twice.
      it.finish();
      await Future<void>.delayed(Duration.zero);
      expect(it.runs(), 2, reason: 'two triggers, one catch-up run');

      it.finish();
      await Future.wait([first, second, third]);
      expect(it.runs(), 2);
    });

    test('a disposed command is not run', () async {
      final it = controllable();
      final refresh = DebouncedRefresh(it.command);

      it.command.dispose();
      await refresh.now();

      expect(it.runs(), 0);
    });
  });
}
