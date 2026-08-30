import 'package:flutter/material.dart';

/// Shown while a token saved on this device is checked against the server.
///
/// It exists so the router has somewhere to park during an async check — the
/// alternative is showing the login form and yanking it away a frame later.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.support_agent,
              size: 44,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 20),
            Text('IT Support', style: theme.textTheme.titleMedium),
            const SizedBox(height: 24),
            const SizedBox(width: 120, child: LinearProgressIndicator()),
          ],
        ),
      ),
    );
  }
}
