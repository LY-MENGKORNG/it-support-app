import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

final class LoginHeader extends StatelessWidget {
  const LoginHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);

    return Column(
      children: [
        Icon(Icons.support_agent, size: 40, color: theme.colorScheme.primary),
        const SizedBox(height: 20),
        Text('IT Support', style: theme.textTheme.h2),
        const SizedBox(height: 6),
        Text(
          'Sign in to raise and track requests.',
          style: theme.textTheme.p.copyWith(color: theme.colorScheme.primary),
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}
