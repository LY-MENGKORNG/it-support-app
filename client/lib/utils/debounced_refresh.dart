import 'dart:async';

import 'command.dart';

/// A reload that the user triggers over and over: typing, filtering, sorting.
class DebouncedRefresh {
  DebouncedRefresh(
    this._command, {
    this.delay = const Duration(milliseconds: 350),
  });

  final Command0<void> _command;

  /// How quiet the trigger has to be before [schedule] fires.
  final Duration delay;

  Timer? _timer;
  bool _queued = false;

  /// Applies [change], then reloads, once [delay] has passed with no further
  /// call — each call restarting the wait.
  void schedule(void Function() change) {
    _timer?.cancel();
    _timer = Timer(delay, () {
      change();
      now();
    });
  }

  /// Reloads immediately — for a control the user had to aim at.
  Future<void> now() async {
    if (_command.running) {
      _queued = true;
      return;
    }

    await _command.execute();

    if (_queued) {
      _queued = false;
      await now();
    }
  }

  /// Drops a pending [schedule]. Call it from the owner's `dispose`, or a
  /// keystroke from a screen that is already gone will still fire a request.
  void cancel() => _timer?.cancel();
}
