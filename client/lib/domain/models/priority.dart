import 'package:app/utils/enum.dart';

enum Priority implements WireEnum {
  low('low', 'Low', 0),
  medium('medium', 'Medium', 1),
  high('high', 'High', 2),
  critical('critical', 'Critical', 3);

  @override
  final String wire;
  final String label;
  final int rank;

  const Priority(this.wire, this.label, this.rank);

  String get hint => switch (this) {
    .low => 'Inconvenient, but you can keep working.',
    .medium => 'Slowing you down. The default for most requests.',
    .high => 'You are blocked on this.',
    .critical => 'Several people are blocked, or something is unsafe.',
  };

  static Priority? tryFromWire(String? value) => values.tryByWire(value);

  static Priority fromWire(String value) {
    return values.byWire(value, label: 'priority');
  }
}

class PriorityConverter extends WireConverter<Priority> {
  const PriorityConverter();

  @override
  Priority fromJson(String json) => .fromWire(json);
}
