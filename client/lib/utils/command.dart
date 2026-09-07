import 'package:flutter/foundation.dart';

import 'result.dart';
import 'safe_notifier.dart';

typedef ZeroArgAction<T> = Future<Result<T>> Function();
typedef OneArgAction<T, A> = Future<Result<T>> Function(A);

abstract class Command<T> extends ChangeNotifier with SafeNotifier {
  bool _running = false;
  Result<T>? _result;

  bool get running => _running;
  bool get error => _result is Error;
  bool get completed => _result is Ok;
  Result<T>? get result => _result;

  Exception? get exception => switch (_result) {
    Error<T>(:final error) => error,
    _ => null,
  };

  Future<void> _execute(ZeroArgAction<T> action) async {
    if (_running) return;

    _running = true;
    _result = null;
    notifySafely();

    try {
      _result = await action();
    } finally {
      _running = false;
      notifySafely();
    }
  }

  void clearResult() {
    _result = null;
    notifySafely();
  }
}

/// A utility class for executing an action with notify its listeners before and after execution.
final class Command0<T> extends Command<T> {
  Command0(this._action);

  final ZeroArgAction<T> _action;

  Future<void> execute() async {
    await _execute(_action);
  }
}

/// A utility class for executing an action containing one arguments by notifying its listeners before and after execution.
final class Command1<T, A> extends Command<T> {
  Command1(this._action);

  final OneArgAction<T, A> _action;

  Future<void> execute(A argument) async {
    await _execute(() => _action(argument));
  }
}
