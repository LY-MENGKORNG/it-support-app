enum RequestHistoryAction {
  created('created'),
  statusChanged('status_changed'),
  priorityChanged('priority_changed'),
  assigned('assigned'),
  unassigned('unassigned'),
  categoryChanged('category_changed');

  const RequestHistoryAction(this.wire);

  final String wire;

  static RequestHistoryAction? tryFromWire(String? value) {
    for (final action in values) {
      if (action.wire == value) return action;
    }
    return null;
  }

  static RequestHistoryAction fromWire(String value) =>
      tryFromWire(value) ??
      (throw FormatException('Unknown history action: $value'));
}
