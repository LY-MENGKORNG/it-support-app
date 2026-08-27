/// An optional value: either [Some] or [None].
library;

import 'result_util.dart';

/// Thrown when a value is forced out of an empty [Option] or a failing
/// [Result].
class UnwrapError extends Error {
  UnwrapError(this.message);

  final String message;

  @override
  String toString() => 'UnwrapError: $message';
}

/// The absent option.
///
/// `None<Never>` is a subtype of `Option<T>` for every `T`, so this constant
/// can be used wherever an empty option is expected.
const Option<Never> none = None<Never>();

/// A container holding either one value ([Some]) or no value ([None]).
///
/// Unlike `T?`, an [Option] nests, so `Option<Option<T>>` can tell "absent"
/// apart from "present but empty".
sealed class Option<T> {
  const Option();

  const factory Option.some(T value) = Some<T>;

  /// An empty option with an explicit type: `Option<int>.none()`.
  const factory Option.none() = None<T>;

  /// Wraps a nullable value, mapping `null` to [None].
  factory Option.from(T? value) => value == null ? None<T>() : Some<T>(value);

  bool get isSome => this is Some<T>;

  bool get isNone => this is None<T>;

  bool isSomeAnd(bool Function(T value) predicate) => switch (this) {
    Some(:final value) => predicate(value),
    None() => false,
  };

  bool contains(T other) => switch (this) {
    Some(:final value) => value == other,
    None() => false,
  };

  /// The contained value.
  ///
  /// Throws [UnwrapError] if there is none.
  T unwrap() => switch (this) {
    Some(:final value) => value,
    None() => throw UnwrapError('called `unwrap()` on a `None` value'),
  };

  /// The contained value, or an [UnwrapError] with [message].
  T expect(String message) => switch (this) {
    Some(:final value) => value,
    None() => throw UnwrapError(message),
  };

  T unwrapOr(T fallback) => switch (this) {
    Some(:final value) => value,
    None() => fallback,
  };

  T unwrapOrElse(T Function() fallback) => switch (this) {
    Some(:final value) => value,
    None() => fallback(),
  };

  /// The contained value as a nullable, for interop with plain Dart APIs.
  T? get valueOrNull => switch (this) {
    Some(:final value) => value,
    None() => null,
  };

  /// Applies [f] to the contained value, if any.
  Option<U> map<U>(U Function(T value) f) => switch (this) {
    Some(:final value) => Some(f(value)),
    None() => None<U>(),
  };

  Future<Option<U>> mapAsync<U>(Future<U> Function(T value) f) async =>
      switch (this) {
        Some(:final value) => Some(await f(value)),
        None() => None<U>(),
      };

  U mapOr<U>(U fallback, U Function(T value) f) => switch (this) {
    Some(:final value) => f(value),
    None() => fallback,
  };

  U mapOrElse<U>(U Function() fallback, U Function(T value) f) =>
      switch (this) {
        Some(:final value) => f(value),
        None() => fallback(),
      };

  /// Chains another optional step onto the contained value (flatMap).
  Option<U> andThen<U>(Option<U> Function(T value) f) => switch (this) {
    Some(:final value) => f(value),
    None() => None<U>(),
  };

  Future<Option<U>> andThenAsync<U>(
    Future<Option<U>> Function(T value) f,
  ) async => switch (this) {
    Some(:final value) => await f(value),
    None() => None<U>(),
  };

  /// Keeps the value only while it satisfies [predicate].
  Option<T> filter(bool Function(T value) predicate) => switch (this) {
    Some(:final value) when predicate(value) => this,
    _ => None<T>(),
  };

  /// Runs [f] on the contained value and returns this option unchanged.
  Option<T> inspect(void Function(T value) f) {
    if (this case Some(:final value)) f(value);
    return this;
  }

  Option<U> and<U>(Option<U> other) => isSome ? other : None<U>();

  Option<T> or(Option<T> other) => isSome ? this : other;

  Option<T> orElse(Option<T> Function() other) => isSome ? this : other();

  /// [Some] when exactly one of the two options holds a value.
  Option<T> xor(Option<T> other) => switch ((this, other)) {
    (Some(), None()) => this,
    (None(), Some()) => other,
    _ => None<T>(),
  };

  /// Pairs both values, or [None] if either is empty.
  Option<(T, U)> zip<U>(Option<U> other) => switch ((this, other)) {
    (Some(value: final a), Some(value: final b)) => Some((a, b)),
    _ => None<(T, U)>(),
  };

  Option<R> zipWith<U, R>(Option<U> other, R Function(T a, U b) f) =>
      switch ((this, other)) {
        (Some(value: final a), Some(value: final b)) => Some(f(a, b)),
        _ => None<R>(),
      };

  /// Converts absence into the failure [error].
  Result<T, E> okOr<E>(E error) => switch (this) {
    Some(:final value) => Ok(value),
    None() => Err(error),
  };

  Result<T, E> okOrElse<E>(E Function() error) => switch (this) {
    Some(:final value) => Ok(value),
    None() => Err(error()),
  };

  /// Zero or one element, so an option can flow into `for` or `expand`.
  Iterable<T> get iter sync* {
    if (this case Some(:final value)) yield value;
  }

  List<T> toList() => iter.toList();

  /// Callback form of a `switch` over the two cases.
  R match<R>({required R Function(T value) some, required R Function() none}) =>
      switch (this) {
        Some(:final value) => some(value),
        None() => none(),
      };
}

/// An [Option] holding a value.
final class Some<T> extends Option<T> {
  const Some(this.value);

  final T value;

  @override
  bool operator ==(Object other) => other is Some && other.value == value;

  @override
  int get hashCode => Object.hash(Some, value);

  @override
  String toString() => 'Some($value)';
}

/// An [Option] holding nothing.
final class None<T> extends Option<T> {
  const None();

  /// Every `None` is equal to every other, whatever its type argument, since
  /// none of them carry a value.
  @override
  bool operator ==(Object other) => other is None;

  @override
  int get hashCode => (None).hashCode;

  @override
  String toString() => 'None';
}

extension OptionFlatten<T> on Option<Option<T>> {
  /// Removes one level of nesting.
  Option<T> flatten() => switch (this) {
    Some(:final value) => value,
    None() => None<T>(),
  };
}

extension OptionTranspose<T, E> on Option<Result<T, E>> {
  /// Swaps the two wrappers.
  Result<Option<T>, E> transpose() => switch (this) {
    Some(value: Ok(:final value)) => Ok(Some(value)),
    Some(value: Err(:final error)) => Err(error),
    None() => Ok(None<T>()),
  };
}

extension NullableToOption<T extends Object> on T? {
  /// Wraps a nullable value, mapping `null` to [None].
  Option<T> toOption() {
    final self = this;
    return self == null ? None<T>() : Some<T>(self);
  }
}

extension OptionIterable<T> on Iterable<Option<T>> {
  /// Every value, or [None] as soon as one element is empty.
  Option<List<T>> collect() {
    final values = <T>[];
    for (final option in this) {
      switch (option) {
        case Some(:final value):
          values.add(value);
        case None():
          return None<List<T>>();
      }
    }
    return Some(values);
  }

  /// The values that are present, skipping the empty ones.
  Iterable<T> whereSome() => expand((option) => option.iter);
}

extension FutureOption<T> on Future<Option<T>> {
  Future<Option<U>> map<U>(U Function(T value) f) async => (await this).map(f);

  Future<Option<U>> andThen<U>(Future<Option<U>> Function(T value) f) async =>
      (await this).andThenAsync(f);

  Future<T> unwrapOr(T fallback) async => (await this).unwrapOr(fallback);
}
