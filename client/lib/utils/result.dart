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

  /// Creates a successful [Result], completed with the specified [value].
  const factory Result.ok(T value) = Ok._;

  /// Creates an error [Result], completed with the specified [error].
  const factory Result.error(Exception error) = Error._;
}

/// A successful [Result] with a returned [value].
final class Ok<T> extends Result<T> {
  const Ok._(this.value);

  /// The returned value of this result.
  final T value;

  @override
  String toString() => 'Result<$T>.ok($value)';
}

/// An error [Result] with a resulting [error].
final class Error<T> extends Result<T> {
  const Error._(this.error);

  /// The resulting error of this result.
  final Exception error;

  @override
  String toString() => 'Result<$T>.error($error)';
}

extension ResultCast<T> on Result<T> {
  /// Narrows this result to [Ok] so `.value` can be read directly.
  ///
  /// Only use it where the branch has already been checked — in a test, or
  /// after an `is Error<T>` early return. Anywhere else, prefer a `switch`,
  /// which the compiler checks for you.
  Ok<T> get asOk => this as Ok<T>;

  /// Narrows this result to [Error] so `.error` can be read directly.
  Error<T> get asError => this as Error<T>;
}

extension ResultMap<T> on Result<T> {
  /// Applies [transform] to a successful value, forwarding an error untouched.
  ///
  /// Saves repositories from writing the same three-line `switch` every time
  /// they need to reshape a service's payload.
  Result<R> map<R>(R Function(T value) transform) => switch (this) {
    Ok<T>(:final value) => Result.ok(transform(value)),
    Error<T>(:final error) => Result.error(error),
  };
}
