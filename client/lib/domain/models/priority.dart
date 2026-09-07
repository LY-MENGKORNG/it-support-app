import 'package:app/utils/json.dart';

enum Priority implements WireEnum {
  low('low', 'Low', 0),
  medium('medium', 'Medium', 1),
  high('high', 'High', 2),
  critical('critical', 'Critical', 3);

  const Priority(this.wire, this.label, this.rank);

  @override
  final String wire;
  final String label;
  final int rank;

  static Priority? tryFromWire(String? value) => values.tryByWire(value);

  static Priority fromWire(String value) =>
      values.byWire(value, label: 'priority');
}

class PriorityConverter extends WireConverter<Priority> {
  const PriorityConverter();

  @override
  Priority fromJson(String json) => Priority.fromWire(json);
}
