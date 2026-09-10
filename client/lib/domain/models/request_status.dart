import 'package:app/utils/json.dart';

enum RequestStatus implements WireEnum {
  open('open', 'Open'),
  inProgress('in_progress', 'In Progress'),
  resolved('resolved', 'Resolved'),
  closed('closed', 'Closed');

  @override
  final String wire;
  final String label;

  const RequestStatus(this.wire, this.label);

  bool get isSettled {
    return this == RequestStatus.resolved || this == RequestStatus.closed;
  }

  static RequestStatus? tryFromWire(String? value) => values.tryByWire(value);

  static RequestStatus fromWire(String value) {
    return values.byWire(value, label: 'request status');
  }

  List<RequestStatus> get nextOptions => switch (this) {
    .open => [.inProgress, .resolved],
    .inProgress => [.resolved, .open],
    .resolved => [.closed, .open],
    .closed => [.open],
  };
}

class RequestStatusConverter extends WireConverter<RequestStatus> {
  const RequestStatusConverter();

  @override
  RequestStatus fromJson(String json) => RequestStatus.fromWire(json);
}
