import 'dart:async';

import 'command.dart';

/// A reload that the user triggers over and over: typing, filtering, sorting.
///
/// Two behaviours every list screen needs, and neither of them is state a view
/// model should be keeping:
///
/// - **Debounce.** A keystroke must not be a request. [schedule] waits for the
///   typing to stop first.
/// - **Coalescing.** A trigger that arrives while the command is still running
///   is remembered and run once at the end. Without it the trigger is simply
///   dropped — [Command] refuses to run twice at once — so the list would be
///   left showing results for a filter the user has already changed.
///
/// It drives a [Command0] rather than a bare callback, and asks that command
/// whether it is running: a reload started from somewhere else (a pull to
/// refresh, say) is then coalesced with, instead of raced against.
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
  ///
  /// [change] runs late on purpose: it sets the state the command reads, and
  /// reading it once per keystroke is the thing being avoided.
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
