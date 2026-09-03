import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'content_column.dart';

const _destinations = [
  (
    icon: Icons.confirmation_number_outlined,
    selectedIcon: Icons.confirmation_number,
    label: 'Requests',
  ),
  (icon: Icons.people_outline, selectedIcon: Icons.people, label: 'People'),
  (
    icon: Icons.settings_outlined,
    selectedIcon: Icons.settings,
    label: 'Settings',
  ),
];

class HomeShell extends StatelessWidget {
  const HomeShell({super.key, required this.shell});

  final StatefulNavigationShell shell;

  void _onTap(int index) {
    shell.goBranch(index, initialLocation: index == shell.currentIndex);
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;

    final body = ContentColumn(child: shell);

    if (width < Breakpoints.compact) {
      return Scaffold(
        body: body,
        bottomNavigationBar: NavigationBar(
          selectedIndex: shell.currentIndex,
          onDestinationSelected: _onTap,
          destinations: [
            for (final destination in _destinations)
              NavigationDestination(
                icon: Icon(destination.icon),
                selectedIcon: Icon(destination.selectedIcon),
                label: destination.label,
              ),
          ],
        ),
      );
    }

    final theme = Theme.of(context);

    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: shell.currentIndex,
            onDestinationSelected: _onTap,
            // Labels only once there is room for them; below that the icons
            // carry the meaning and tooltips fill the gap.
            extended: width >= Breakpoints.expanded,
            labelType: width >= Breakpoints.expanded
                ? null
                : NavigationRailLabelType.all,
            backgroundColor: theme.colorScheme.surfaceContainerLowest,
            destinations: [
              for (final destination in _destinations)
                NavigationRailDestination(
                  icon: Icon(destination.icon),
                  selectedIcon: Icon(destination.selectedIcon),
                  label: Text(destination.label),
                ),
            ],
          ),
          const VerticalDivider(width: 1, thickness: 1),
          Expanded(child: body),
        ],
      ),
    );
  }
}
