import 'package:app/utils/enum.dart';

enum RequestSort implements WireEnum {
  newest('newest', 'Newest first'),
  oldest('oldest', 'Oldest first'),
  priority('priority', 'Priority');

  @override
  final String wire;
  final String label;

  const RequestSort(this.wire, this.label);
}
