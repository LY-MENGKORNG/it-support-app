import 'package:flutter/material.dart';

import 'package:app/domain/models/user_role.dart';
import 'package:app/ui/core/ui/error_indicator.dart';
import 'package:app/ui/core/ui/user_avatar.dart';
import 'package:app/ui/users/view_models/user_list_viewmodel.dart';

/// The People tab — the directory of everyone who can raise or handle requests.
class UserListScreen extends StatelessWidget {
  const UserListScreen({super.key, required this.viewModel});

  final UserListViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('People')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              onChanged: viewModel.search,
              decoration: const InputDecoration(
                hintText: 'Search people',
                prefixIcon: Icon(Icons.search, size: 20),
              ),
            ),
          ),
          SizedBox(
            height: 36,
            child: ListenableBuilder(
              listenable: viewModel,
              builder: (context, _) => ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _RoleChip(
                    label: 'Everyone',
                    selected: viewModel.role == null,
                    onTap: () => viewModel.filterByRole(null),
                  ),
                  for (final role in UserRole.values)
                    _RoleChip(
                      label: role.label,
                      selected: viewModel.role == role,
                      onTap: () => viewModel.filterByRole(role),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Divider(),
          Expanded(
            child: ListenableBuilder(
              listenable: viewModel.load,
              builder: (context, child) {
                if (viewModel.load.running && viewModel.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (viewModel.load.error) {
                  return ErrorIndicator(
                    title: 'Could not load people',
                    error: viewModel.load.exception,
                    onPressed: viewModel.load.execute,
                  );
                }
                return child!;
              },
              child: ListenableBuilder(
                listenable: viewModel,
                builder: (context, _) {
                  if (viewModel.isEmpty) {
                    return const EmptyIndicator(
                      icon: Icons.people_outline,
                      title: 'No people found',
                    );
                  }

                  return ListView.separated(
                    itemCount: viewModel.users.length,
                    separatorBuilder: (_, _) => const Divider(),
                    itemBuilder: (context, index) {
                      final user = viewModel.users[index];

                      return ListTile(
                        leading: UserAvatar(user),
                        title: Text(user.name),
                        subtitle: Text(user.email),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              user.role.label,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                            if (!user.isActive)
                              Text(
                                'Inactive',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: theme.colorScheme.error,
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RoleChip extends StatelessWidget {
  const _RoleChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(right: 8),
    child: FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
    ),
  );
}
