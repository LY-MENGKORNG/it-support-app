import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'content_column.dart';

/// The three top-level destinations, and where they sit.
///
/// One list, read by both layouts below, so a new tab cannot appear in the
/// bottom bar and be forgotten in the rail.
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

/// The navigation frame that wraps the app's top-level destinations.
///
/// [StatefulNavigationShell] keeps a separate navigation stack per tab and
/// preserves each one's state, so switching tabs does not reset scroll position
/// or reload the list.
///
/// The shell picks its layout from the window width, not the platform: the same
/// macOS build shows a rail when the window is wide and a bottom bar when it is
/// dragged narrow, and a tablet gets the right one in each orientation without
/// a second code path.
class HomeShell extends StatelessWidget {
  const HomeShell({super.key, required this.shell});

  final StatefulNavigationShell shell;

  void _onTap(int index) {
    // Tapping the destination you are already on pops that branch back to its
    // root — the behaviour people expect from both a nav bar and a rail.
    shell.goBranch(index, initialLocation: index == shell.currentIndex);
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;

    // Every screen inside the shell is capped and centred here rather than
    // wrapping itself, so the rule holds for tabs added later too.
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
          // A hairline instead of a shadow: the theme draws separation with
          // borders everywhere else, and elevation would be the odd one out.
          const VerticalDivider(width: 1, thickness: 1),
          Expanded(child: body),
        ],
      ),
    );
  }
}
