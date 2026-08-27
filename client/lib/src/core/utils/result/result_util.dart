/// The outcome of an operation that can fail: either [Ok] or [Err].
library;

import 'option_util.dart';

/// A container holding either a success value of type `T` ([Ok]) or a failure
/// of type `E` ([Err]).
///
/// The failure is part of the return type instead of an exception, so callers
/// have to account for it and the compiler says which errors are possible.
sealed class Result<T, E> {
  const Result();

  /// Runs [body], catching anything it throws into [Err].
  static Result<T, Object> tryCatch<T>(T Function() body) {
    try {
      return Ok(body());
    } catch (error) {
      return Err(error);
    }
  }

  /// Runs [body], passing anything it throws through [onError].
  static Result<T, E> tryCatchWith<T, E>(
    T Function() body,
    E Function(Object error, StackTrace stackTrace) onError,
  ) {
    try {
      return Ok(body());
    } catch (error, stackTrace) {
      return Err(onError(error, stackTrace));
    }
  }

  static Future<Result<T, Object>> tryCatchAsync<T>(
    Future<T> Function() body,
  ) async {
    try {
      return Ok(await body());
    } catch (error) {
      return Err(error);
    }
  }

  static Future<Result<T, E>> tryCatchAsyncWith<T, E>(
    Future<T> Function() body,
    E Function(Object error, StackTrace stackTrace) onError,
  ) async {
    try {
      return Ok(await body());
    } catch (error, stackTrace) {
      return Err(onError(error, stackTrace));
    }
  }

  bool get isOk => this is Ok<T, E>;

  bool get isErr => this is Err<T, E>;

  bool isOkAnd(bool Function(T value) predicate) => switch (this) {
    Ok(:final value) => predicate(value),
    Err() => false,
  };

  bool isErrAnd(bool Function(E error) predicate) => switch (this) {
    Ok() => false,
    Err(:final error) => predicate(error),
  };

  /// The success value.
  ///
  /// Throws [UnwrapError] describing the failure if there is one.
  T unwrap() => switch (this) {
    Ok(:final value) => value,
    Err(:final error) => throw UnwrapError(
      'called `unwrap()` on an `Err` value: $error',
    ),
  };

  /// The success value, or an [UnwrapError] prefixed with [message].
  T expect(String message) => switch (this) {
    Ok(:final value) => value,
    Err(:final error) => throw UnwrapError('$message: $error'),
  };

  /// The failure.
  ///
  /// Throws [UnwrapError] if this is [Ok].
  E unwrapErr() => switch (this) {
    Ok(:final value) => throw UnwrapError(
      'called `unwrapErr()` on an `Ok` value: $value',
    ),
    Err(:final error) => error,
  };

  E expectErr(String message) => switch (this) {
    Ok(:final value) => throw UnwrapError('$message: $value'),
    Err(:final error) => error,
  };

  T unwrapOr(T fallback) => switch (this) {
    Ok(:final value) => value,
    Err() => fallback,
  };

  T unwrapOrElse(T Function(E error) fallback) => switch (this) {
    Ok(:final value) => value,
    Err(:final error) => fallback(error),
  };

  T? get valueOrNull => switch (this) {
    Ok(:final value) => value,
    Err() => null,
  };

  E? get errorOrNull => switch (this) {
    Ok() => null,
    Err(:final error) => error,
  };

  /// Applies [f] to the success value, leaving a failure untouched.
  Result<U, E> map<U>(U Function(T value) f) => switch (this) {
    Ok(:final value) => Ok(f(value)),
    Err(:final error) => Err(error),
  };

  Future<Result<U, E>> mapAsync<U>(Future<U> Function(T value) f) async =>
      switch (this) {
        Ok(:final value) => Ok(await f(value)),
        Err(:final error) => Err(error),
      };

  /// Applies [f] to the failure, leaving a success untouched.
  ///
  /// Use it to adapt an error into the type the caller declares.
  Result<T, F> mapErr<F>(F Function(E error) f) => switch (this) {
    Ok(:final value) => Ok(value),
    Err(:final error) => Err(f(error)),
  };

  U mapOr<U>(U fallback, U Function(T value) f) => switch (this) {
    Ok(:final value) => f(value),
    Err() => fallback,
  };

  U mapOrElse<U>(U Function(E error) fallback, U Function(T value) f) =>
      switch (this) {
        Ok(:final value) => f(value),
        Err(:final error) => fallback(error),
      };

  /// Chains another fallible step onto a success. A failure short-circuits.
  Result<U, E> andThen<U>(Result<U, E> Function(T value) f) => switch (this) {
    Ok(:final value) => f(value),
    Err(:final error) => Err(error),
  };

  Future<Result<U, E>> andThenAsync<U>(
    Future<Result<U, E>> Function(T value) f,
  ) async => switch (this) {
    Ok(:final value) => await f(value),
    Err(:final error) => Err(error),
  };

  /// Runs [f] on the success value and returns this result unchanged.
  Result<T, E> inspect(void Function(T value) f) {
    if (this case Ok(:final value)) f(value);
    return this;
  }

  /// Runs [f] on the failure and returns this result unchanged, which is handy
  /// for logging without interrupting a chain.
  Result<T, E> inspectErr(void Function(E error) f) {
    if (this case Err(:final error)) f(error);
    return this;
  }

  Result<U, E> and<U>(Result<U, E> other) => switch (this) {
    Ok() => other,
    Err(:final error) => Err(error),
  };

  Result<T, F> or<F>(Result<T, F> other) => switch (this) {
    Ok(:final value) => Ok(value),
    Err() => other,
  };

  /// Recovers from a failure by producing another result from it.
  Result<T, F> orElse<F>(Result<T, F> Function(E error) f) => switch (this) {
    Ok(:final value) => Ok(value),
    Err(:final error) => f(error),
  };

  /// The success value as an [Option], discarding the failure.
  Option<T> ok() => switch (this) {
    Ok(:final value) => Some(value),
    Err() => None<T>(),
  };

  /// The failure as an [Option], discarding the success value.
  Option<E> err() => switch (this) {
    Ok() => None<E>(),
    Err(:final error) => Some(error),
  };

  /// Zero or one element, empty for a failure.
  Iterable<T> get iter sync* {
    if (this case Ok(:final value)) yield value;
  }

  /// Callback form of a `switch` over the two cases.
  R match<R>({
    required R Function(T value) ok,
    required R Function(E error) err,
  }) => switch (this) {
    Ok(:final value) => ok(value),
    Err(:final error) => err(error),
  };
}

/// A successful [Result].
final class Ok<T, E> extends Result<T, E> {
  const Ok(this.value);

  final T value;

  @override
  bool operator ==(Object other) => other is Ok && other.value == value;

  @override
  int get hashCode => Object.hash(Ok, value);

  @override
  String toString() => 'Ok($value)';
}

/// A failed [Result].
final class Err<T, E> extends Result<T, E> {
  const Err(this.error);

  final E error;

  @override
  bool operator ==(Object other) => other is Err && other.error == error;

  @override
  int get hashCode => Object.hash(Err, error);

  @override
  String toString() => 'Err($error)';
}

extension ResultFlatten<T, E> on Result<Result<T, E>, E> {
  /// Removes one level of nesting.
  Result<T, E> flatten() => switch (this) {
    Ok(:final value) => value,
    Err(:final error) => Err(error),
  };
}

extension ResultTranspose<T, E> on Result<Option<T>, E> {
  /// Swaps the two wrappers.
  Option<Result<T, E>> transpose() => switch (this) {
    Ok(value: Some(:final value)) => Some(Ok(value)),
    Ok(value: None()) => None<Result<T, E>>(),
    Err(:final error) => Some(Err(error)),
  };
}

extension ResultIterable<T, E> on Iterable<Result<T, E>> {
  /// Every success value, or the first failure encountered.
  Result<List<T>, E> collect() {
    final values = <T>[];
    for (final result in this) {
      switch (result) {
        case Ok(:final value):
          values.add(value);
        case Err(:final error):
          return Err(error);
      }
    }
    return Ok(values);
  }

  /// Successes and failures side by side, without stopping at the first one.
  (List<T> oks, List<E> errs) partition() {
    final oks = <T>[];
    final errs = <E>[];
    for (final result in this) {
      switch (result) {
        case Ok(:final value):
          oks.add(value);
        case Err(:final error):
          errs.add(error);
      }
    }
    return (oks, errs);
  }
}

extension FutureResult<T, E> on Future<Result<T, E>> {
  Future<Result<U, E>> map<U>(U Function(T value) f) async =>
      (await this).map(f);

  Future<Result<T, F>> mapErr<F>(F Function(E error) f) async =>
      (await this).mapErr(f);

  Future<Result<U, E>> andThen<U>(
    Future<Result<U, E>> Function(T value) f,
  ) async => (await this).andThenAsync(f);

  Future<T> unwrapOr(T fallback) async => (await this).unwrapOr(fallback);

  Future<R> match<R>({
    required R Function(T value) ok,
    required R Function(E error) err,
  }) async => (await this).match(ok: ok, err: err);
}
