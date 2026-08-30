import 'package:flutter/foundation.dart';

import 'result.dart';

/// Defines a command action that returns a [Result] of type [T].
/// Used by [Command0] for actions without arguments.
typedef CommandAction0<T> = Future<Result<T>> Function();

/// Defines a command action that returns a [Result] of type [T].
/// Takes an argument of type [A].
/// Used by [Command1] for actions with one argument.
typedef CommandAction1<T, A> = Future<Result<T>> Function(A);

/// Facilitates interaction with a view model.
///
/// Encapsulates an action, exposes its running and error states, and ensures
/// that it can't be launched again until it finishes.
///
/// This is what stops a view model from growing a `_isLoading` / `_error` pair
/// per action — and, more importantly, from forgetting to reset one of them.
///
/// Use [Command0] for actions without arguments.
/// Use [Command1] for actions with one argument.
///
/// Consume the action result by listening to changes, then call [clearResult]
/// when the state is consumed.
abstract class Command<T> extends ChangeNotifier {
  bool _running = false;

  /// Whether the action is running.
  bool get running => _running;

  Result<T>? _result;

  /// Whether the action completed with an error.
  bool get error => _result is Error;

  /// Whether the action completed successfully.
  bool get completed => _result is Ok;

  /// The result of the most recent action.
  ///
  /// Returns `null` if the action is running or has not run yet.
  Result<T>? get result => _result;

  /// The exception from the most recent failed run, or null.
  ///
  /// Lets a widget show *why* something failed without importing `Result` or
  /// pattern-matching on it — the UI layer asks the command, not the result.
  Exception? get exception => switch (_result) {
    Error<T>(:final error) => error,
    _ => null,
  };

  /// Clears the most recent action's result.
  void clearResult() {
    _result = null;
    notifyListeners();
  }

  /// Execute the provided [action], notifying listeners and setting the running
  /// and result states as necessary.
  Future<void> _execute(CommandAction0<T> action) async {
    // Ensure the action can't launch multiple times.
    // e.g. avoid multiple taps on button
    if (_running) return;

    // Notify listeners.
    // e.g. button shows loading state
    _running = true;
    _result = null;
    notifyListeners();

    try {
      _result = await action();
    } finally {
      _running = false;
      notifyListeners();
    }
  }
}

/// A [Command] that accepts no arguments.
final class Command0<T> extends Command<T> {
  /// Creates a [Command0] with the provided [CommandAction0].
  Command0(this._action);

  final CommandAction0<T> _action;

  /// Executes the action.
  Future<void> execute() async {
    await _execute(_action);
  }
}

/// A [Command] that accepts one argument.
final class Command1<T, A> extends Command<T> {
  /// Creates a [Command1] with the provided [CommandAction1].
  Command1(this._action);

  final CommandAction1<T, A> _action;

  /// Executes the action with the specified [argument].
  Future<void> execute(A argument) async {
    await _execute(() => _action(argument));
  }
}
