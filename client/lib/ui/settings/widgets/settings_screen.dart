import 'package:flutter/material.dart';

import 'package:app/data/services/api/rest_client.dart';
import 'package:app/ui/core/ui/user_avatar.dart';
import 'package:app/ui/settings/view_models/settings_viewmodel.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key, required this.viewModel});

  final SettingsViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListenableBuilder(
        listenable: Listenable.merge([viewModel, viewModel.signOut]),
        builder: (context, _) {
          final user = viewModel.currentUser;

          return ListView(
            children: [
              if (user != null) ...[
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      UserAvatar(user, size: 48),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(user.name, style: theme.textTheme.titleMedium),
                            const SizedBox(height: 2),
                            Text(
                              user.email,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              user.role.label,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.logout_outlined),
                  title: const Text('Sign out'),
                  subtitle: const Text("Forgets this device's saved sign-in"),
                  trailing: viewModel.signOut.running
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : null,
                  onTap: viewModel.signOut.running
                      ? null
                      : viewModel.signOut.execute,
                ),
              ],
              const Divider(),
              ListTile(
                leading: const Icon(Icons.dns_outlined),
                title: const Text('API server'),
                subtitle: Text(RestClient.defaultBaseUrl),
              ),
              ListTile(
                leading: const Icon(Icons.info_outline),
                title: const Text('About'),
                subtitle: const Text(
                  'IT Support — internal request tracking demo',
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
