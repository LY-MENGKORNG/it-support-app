enum Priority { low, medium, high, critical }

enum RequestStatus { open, inProgress, resolved, closed }

enum RequestHistoryStatus {
  created,
  statusChanged,
  priorityChanged,
  assigned,
  unassigned,
  categoryChanged,
}
