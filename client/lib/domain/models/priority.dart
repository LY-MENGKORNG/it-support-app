enum Priority {
  low('low', 'Low', 0),
  medium('medium', 'Medium', 1),
  high('high', 'High', 2),
  critical('critical', 'Critical', 3);

  const Priority(this.wire, this.label, this.rank);

  final String wire;
  final String label;
  final int rank;

  static Priority? tryFromWire(String? value) {
    for (final priority in values) {
      if (priority.wire == value) return priority;
    }
    return null;
  }

  static Priority fromWire(String value) =>
      tryFromWire(value) ?? (throw FormatException('Unknown priority: $value'));
}
