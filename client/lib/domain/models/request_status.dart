import 'package:app/utils/json.dart';

enum RequestStatus implements WireEnum {
  open('open', 'Open'),
  inProgress('in_progress', 'In Progress'),
  resolved('resolved', 'Resolved'),
  closed('closed', 'Closed');

  const RequestStatus(this.wire, this.label);

  @override
  final String wire;
  final String label;

  static RequestStatus? tryFromWire(String? value) => values.tryByWire(value);

  static RequestStatus fromWire(String value) =>
      values.byWire(value, label: 'request status');

  List<RequestStatus> get nextOptions => switch (this) {
    RequestStatus.open => [RequestStatus.inProgress, RequestStatus.resolved],
    RequestStatus.inProgress => [RequestStatus.resolved, RequestStatus.open],
    RequestStatus.resolved => [RequestStatus.closed, RequestStatus.open],
    RequestStatus.closed => [RequestStatus.open],
  };

  bool get isSettled {
    return this == RequestStatus.resolved || this == RequestStatus.closed;
  }
}

class RequestStatusConverter extends WireConverter<RequestStatus> {
  const RequestStatusConverter();

  @override
  RequestStatus fromJson(String json) => RequestStatus.fromWire(json);
}
