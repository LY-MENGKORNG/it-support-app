import 'package:app/utils/json.dart';

enum RequestSort implements WireEnum {
  newest('newest', 'Newest first'),
  oldest('oldest', 'Oldest first'),
  priority('priority', 'Priority');

  const RequestSort(this.wire, this.label);

  @override
  final String wire;
  final String label;
}
