/// Where a request has got to. See [Priority] for why `wire` exists.
enum RequestStatus {
  open('open', 'Open'),
  inProgress('in_progress', 'In Progress'),
  resolved('resolved', 'Resolved'),
  closed('closed', 'Closed');

  const RequestStatus(this.wire, this.label);

  final String wire;
  final String label;

  static RequestStatus fromWire(String value) => values.firstWhere(
    (status) => status.wire == value,
    orElse: () => throw FormatException('Unknown request status: $value'),
  );

  /// Statuses a request can move to from here. Reopening is always allowed, so
  /// every status can reach [open]; the rest follow the normal flow.
  List<RequestStatus> get nextOptions => switch (this) {
    RequestStatus.open => [RequestStatus.inProgress, RequestStatus.resolved],
    RequestStatus.inProgress => [RequestStatus.resolved, RequestStatus.open],
    RequestStatus.resolved => [RequestStatus.closed, RequestStatus.open],
    RequestStatus.closed => [RequestStatus.open],
  };

  bool get isSettled =>
      this == RequestStatus.resolved || this == RequestStatus.closed;
}
