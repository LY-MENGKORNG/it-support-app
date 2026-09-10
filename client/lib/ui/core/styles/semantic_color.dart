import 'package:flutter/material.dart';

import 'package:app/domain/models/priority.dart';
import 'package:app/domain/models/request_history_action.dart';
import 'package:app/domain/models/request_status.dart';

extension PriorityStyle on Priority {
  Color get color => switch (this) {
    .low => const Color(0xFF6B7280),
    .medium => const Color(0xFF3B82F6),
    .high => const Color(0xFFF59E0B),
    .critical => const Color(0xFFEF4444),
  };
}

extension RequestStatusStyle on RequestStatus {
  Color get color => switch (this) {
    .open => const Color(0xFF38BDF8),
    .inProgress => const Color(0xFFA78BFA),
    .resolved => const Color(0xFF34D399),
    .closed => const Color(0xFF6B7280),
  };
}

extension RequestHistoryActionStyle on RequestHistoryAction {
  IconData get icon => switch (this) {
    .created => Icons.add,
    .statusChanged => Icons.swap_horiz,
    .priorityChanged => Icons.priority_high,
    .assigned => Icons.person_add_alt,
    .unassigned => Icons.person_remove_alt_1,
    .categoryChanged => Icons.label_outline,
  };
}
