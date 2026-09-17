import 'package:flutter/material.dart';

import 'package:app/utils/date_format.dart';
import 'package:app/ui/core/ui/status_chip.dart';
import 'package:app/domain/models/request.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

class RequestCard extends StatelessWidget {
  final Request request;
  final VoidCallback onTap;

  const RequestCard({super.key, required this.request, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final textStyle = theme.textTheme.p.copyWith(
      color: theme.colorScheme.foreground,
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
                    style: theme.textTheme.h4.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text('#${request.id}', style: textStyle),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              request.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: textStyle,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                StatusChip(request.status, dense: true),
                PriorityChip(request.priority, dense: true),
                Text(request.category.name, style: textStyle),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(
                  Icons.person_outline,
                  size: 14,
                  color: theme.colorScheme.foreground,
                ),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    request.requester.name,
                    overflow: TextOverflow.ellipsis,
                    style: textStyle,
                  ),
                ),
                const SizedBox(width: 12),
                Icon(
                  request.isAssigned
                      ? Icons.assignment_ind_outlined
                      : Icons.person_off_outlined,
                  size: 14,
                  color: request.isAssigned
                      ? theme.colorScheme.foreground
                      : theme.colorScheme.destructive,
                ),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    request.assignee?.name ?? 'Unassigned',
                    overflow: TextOverflow.ellipsis,
                    style: request.isAssigned
                        ? textStyle
                        : textStyle.copyWith(
                            color: theme.colorScheme.destructive,
                          ),
                  ),
                ),
                const Spacer(),
                Text(formatRelative(request.createdAt), style: textStyle),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
