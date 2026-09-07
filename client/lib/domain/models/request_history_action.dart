import 'package:app/utils/json.dart';

enum RequestHistoryAction implements WireEnum {
  created('created'),
  statusChanged('status_changed'),
  priorityChanged('priority_changed'),
  assigned('assigned'),
  unassigned('unassigned'),
  categoryChanged('category_changed');

  const RequestHistoryAction(this.wire);

  @override
  final String wire;

  static RequestHistoryAction? tryFromWire(String? value) =>
      values.tryByWire(value);

  static RequestHistoryAction fromWire(String value) =>
      values.byWire(value, label: 'history action');
}

class RequestHistoryActionConverter
    extends WireConverter<RequestHistoryAction> {
  const RequestHistoryActionConverter();

  @override
  RequestHistoryAction fromJson(String json) =>
      RequestHistoryAction.fromWire(json);
}
