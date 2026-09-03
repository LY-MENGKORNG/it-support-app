import 'dart:core';
import 'dart:core' as core;

/// Utility class that simplifies handling errors.
///
/// Return a [Result] from a function to indicate success or failure.
///
/// A [Result] is either an [Ok] with a value of type [T]
/// or an [Error] with an [Exception].
///
/// Dart's exceptions are unchecked: nothing forces a caller to handle them, and
/// nothing documents which ones a function can throw. Returning a [Result]
/// instead makes failure part of the signature, and the `switch` below cannot
/// compile unless both cases are handled.
///
/// Evaluate the result using a switch statement:
/// ```dart
/// switch (result) {
///   case Ok():
///     print(result.value);
///   case Error():
///     print(result.error);
/// }
/// ```
sealed class Result<T> {
  const Result();

  const factory Result.ok(T value) = Ok._;

  const factory Result.error(Exception error) = Error._;

  static Result<T> safeTry<T>(
    T Function() body, {
    ErrorMapper onError = _asExceptionOrRethrow,
  }) {
    try {
      return Result.ok(body());
    } catch (error, stackTrace) {
      return Result.error(onError(error, stackTrace));
    }
  }

  static Future<Result<T>> safeTryAsync<T>(
    Future<T> Function() body, {
    ErrorMapper onError = _asExceptionOrRethrow,
  }) async {
    try {
      return Result.ok(await body());
    } catch (error, stackTrace) {
      return Result.error(onError(error, stackTrace));
    }
  }
}

final class Ok<T> extends Result<T> {
  const Ok._(this.value);

  final T value;

  @override
  String toString() => 'Result<$T>.ok($value)';
}

final class Error<T> extends Result<T> {
  const Error._(this.error);

  final Exception error;

  @override
  String toString() => 'Result<$T>.error($error)';
}

typedef ErrorMapper = Exception Function(Object error, StackTrace stackTrace);

Never rethrowWithStack(Object error, StackTrace stackTrace) =>
    core.Error.throwWithStackTrace(error, stackTrace);

Exception _asExceptionOrRethrow(Object error, StackTrace stackTrace) =>
    error is Exception ? error : rethrowWithStack(error, stackTrace);

extension ResultCast<T> on Result<T> {
  Ok<T> get asOk => this as Ok<T>;

  Error<T> get asError => this as Error<T>;
}

extension ResultMap<T> on Result<T> {
  Result<R> map<R>(R Function(T value) transform) => switch (this) {
    Ok<T>(:final value) => Result.ok(transform(value)),
    Error<T>(:final error) => Result.error(error),
  };

  Result<R> flatMap<R>(Result<R> Function(T value) transform) => switch (this) {
    Ok<T>(:final value) => transform(value),
    Error<T>(:final error) => Result.error(error),
  };
}
