/// The kinds of change recorded in a request's audit trail.
enum RequestHistoryAction {
  created('created'),
  statusChanged('status_changed'),
  priorityChanged('priority_changed'),
  assigned('assigned'),
  unassigned('unassigned'),
  categoryChanged('category_changed');

  const RequestHistoryAction(this.wire);

  final String wire;

  static RequestHistoryAction fromWire(String value) => values.firstWhere(
    (action) => action.wire == value,
    orElse: () => throw FormatException('Unknown history action: $value'),
  );
}
