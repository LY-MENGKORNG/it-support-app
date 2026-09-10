import 'package:app/utils/json.dart';

enum RequestHistoryAction implements WireEnum {
  created('created'),
  statusChanged('status_changed'),
  priorityChanged('priority_changed'),
  assigned('assigned'),
  unassigned('unassigned'),
  categoryChanged('category_changed');

  @override
  final String wire;

  const RequestHistoryAction(this.wire);

  static RequestHistoryAction? tryFromWire(String? value) {
    return values.tryByWire(value);
  }

  static RequestHistoryAction fromWire(String value) {
    return values.byWire(value, label: 'history action');
  }
}

class RequestHistoryActionConverter
    extends WireConverter<RequestHistoryAction> {
  const RequestHistoryActionConverter();

  @override
  RequestHistoryAction fromJson(String json) =>
      RequestHistoryAction.fromWire(json);
}
