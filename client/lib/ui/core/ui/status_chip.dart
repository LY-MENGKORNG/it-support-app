import 'package:flutter/material.dart';
import 'package:app/domain/models/priority.dart';
import 'package:app/domain/models/request_status.dart';
import 'package:app/ui/core/styles/semantic_color.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

class StatusChip extends StatelessWidget {
  final RequestStatus status;
  final bool dense;

  const StatusChip(this.status, {super.key, this.dense = false});

  @override
  Widget build(BuildContext context) {
    return ShadBadge(
      backgroundColor: status.color,
      // color: status.color,
      // dense: dense,
      child: Text(status.label),
    );
  }
}

class PriorityChip extends StatelessWidget {
  final Priority priority;
  final bool dense;

  const PriorityChip(this.priority, {super.key, this.dense = false});

  @override
  Widget build(BuildContext context) {
    return ShadBadge(
      backgroundColor: priority.color,
      child: Text(priority.label),
    );
  }
}
