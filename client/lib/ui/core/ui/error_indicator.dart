import 'package:flutter/material.dart';

import 'package:app/data/services/api/api_exception.dart';

class ErrorIndicator extends StatelessWidget {
  const ErrorIndicator({
    super.key,
    required this.title,
    this.error,
    this.onPressed,
    this.label = 'Try again',
  });

  final String title;

  final Object? error;
  final VoidCallback? onPressed;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final detail = error == null ? null : messageFor(error!);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 40, color: theme.colorScheme.error),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleSmall,
            ),
            if (detail != null) ...[
              const SizedBox(height: 8),
              Text(
                detail,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            if (onPressed != null) ...[
              const SizedBox(height: 20),
              OutlinedButton.icon(
                onPressed: onPressed,
                icon: const Icon(Icons.refresh, size: 18),
                label: Text(label),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class EmptyIndicator extends StatelessWidget {
  const EmptyIndicator({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.onPressed,
  });

  final IconData icon;
  final String title;
  final String? message;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 40, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(height: 16),
            Text(title, style: theme.textTheme.titleMedium),
            if (message != null) ...[
              const SizedBox(height: 8),
              Text(
                message!,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            if (onPressed != null) ...[
              const SizedBox(height: 20),
              OutlinedButton.icon(
                onPressed: onPressed,
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Refresh'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
