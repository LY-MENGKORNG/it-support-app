import 'package:flutter/material.dart';

import 'package:app/domain/models/priority.dart';
import 'package:app/domain/models/request_status.dart';
import 'package:app/ui/core/themes/semantic_colors.dart';
import 'package:app/ui/core/themes/theme.dart';

class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.color, this.dense = false});

  final String label;
  final Color color;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: dense ? 6 : 8,
        vertical: dense ? 2 : 4,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        border: Border.all(color: color.withValues(alpha: 0.55)),
        borderRadius: AppTheme.radius,
      ),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: dense ? 10 : 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}

class StatusChip extends StatelessWidget {
  const StatusChip(this.status, {super.key, this.dense = false});

  final RequestStatus status;
  final bool dense;

  @override
  Widget build(BuildContext context) =>
      _Badge(label: status.label, color: status.color, dense: dense);
}

class PriorityChip extends StatelessWidget {
  const PriorityChip(this.priority, {super.key, this.dense = false});

  final Priority priority;
  final bool dense;

  @override
  Widget build(BuildContext context) =>
      _Badge(label: priority.label, color: priority.color, dense: dense);
}
