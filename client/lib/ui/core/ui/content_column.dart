import 'package:flutter/material.dart';

/// Layout breakpoints, in one place.
///
/// Named after what changes at each width rather than after a device, because
/// a phone in landscape and a small desktop window are the same problem.
abstract final class Breakpoints {
  /// Below this the navigation sits at the bottom; above it, at the side.
  static const compact = 700.0;

  /// Above this there is room for the navigation rail to show its labels.
  static const expanded = 1100.0;

  static bool isCompact(BuildContext context) =>
      MediaQuery.sizeOf(context).width < compact;
}

/// Caps a page's width and centres it.
///
/// A list of requests stretched across a 27-inch monitor is unreadable: the eye
/// loses the line, and a row's status ends up a foot away from its title. Text
/// columns want roughly 60–90 characters, and this is how every screen gets
/// that without each one inventing its own number.
class ContentColumn extends StatelessWidget {
  const ContentColumn({super.key, required this.child, this.maxWidth = 840});

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) => Align(
    // Top rather than centre: a short page should start under the app bar, not
    // float in the middle of the window.
    alignment: Alignment.topCenter,
    child: ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: child,
    ),
  );
}
