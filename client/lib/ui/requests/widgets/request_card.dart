import 'package:flutter/material.dart';

import 'package:app/utils/date_format.dart';
import 'package:app/ui/core/ui/status_chip.dart';
import 'package:app/domain/models/request.dart';

/// One row in the requests list.
///
/// A separate widget because it is the unit the list repeats, and because
/// keeping it out of the screen means the screen file stays about *the list*.
class RequestCard extends StatelessWidget {
  const RequestCard({super.key, required this.request, required this.onTap});

  final Request request;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    request.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text('#${request.id}', style: muted),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              request.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: muted,
            ),
            const SizedBox(height: 12),
            // Wrap rather than Row: on a narrow phone these badges would
            // otherwise overflow instead of moving to a second line.
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                StatusChip(request.status, dense: true),
                PriorityChip(request.priority, dense: true),
                Text(request.category.name, style: muted),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(
                  Icons.person_outline,
                  size: 14,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    request.requester.name,
                    overflow: TextOverflow.ellipsis,
                    style: muted,
                  ),
                ),
                const SizedBox(width: 12),
                Icon(
                  request.isAssigned
                      ? Icons.assignment_ind_outlined
                      : Icons.person_off_outlined,
                  size: 14,
                  color: request.isAssigned
                      ? theme.colorScheme.onSurfaceVariant
                      : theme.colorScheme.error,
                ),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    request.assignee?.name ?? 'Unassigned',
                    overflow: TextOverflow.ellipsis,
                    style: request.isAssigned
                        ? muted
                        : muted?.copyWith(color: theme.colorScheme.error),
                  ),
                ),
                const Spacer(),
                Text(formatRelative(request.createdAt), style: muted),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
