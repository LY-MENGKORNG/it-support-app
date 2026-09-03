enum RequestStatus {
  open('open', 'Open'),
  inProgress('in_progress', 'In Progress'),
  resolved('resolved', 'Resolved'),
  closed('closed', 'Closed');

  const RequestStatus(this.wire, this.label);

  final String wire;
  final String label;

  static RequestStatus? tryFromWire(String? value) {
    for (final status in values) {
      if (status.wire == value) return status;
    }
    return null;
  }

  static RequestStatus fromWire(String value) {
    return tryFromWire(value) ??
        (throw FormatException('Unknown request status: $value'));
  }

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
