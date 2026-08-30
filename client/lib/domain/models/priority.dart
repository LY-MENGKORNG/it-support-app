/// How urgent a request is.
///
/// Wire values live on the enum rather than in its member *names*: the API
/// speaks snake_case, Dart style is lowerCamelCase, and `Enum.values.byName`
/// conflates the two. An explicit [wire] keeps the API's vocabulary at the
/// boundary.
///
/// Nothing here knows what colour a priority is — that is a UI decision, and
/// this file deliberately imports no Flutter code.
enum Priority {
  low('low', 'Low', 0),
  medium('medium', 'Medium', 1),
  high('high', 'High', 2),
  critical('critical', 'Critical', 3);

  const Priority(this.wire, this.label, this.rank);

  /// The string the API uses.
  final String wire;

  /// The string a human should read.
  final String label;

  /// Higher means more urgent.
  final int rank;

  static Priority fromWire(String value) => values.firstWhere(
    (priority) => priority.wire == value,
    orElse: () => throw FormatException('Unknown priority: $value'),
  );
}
