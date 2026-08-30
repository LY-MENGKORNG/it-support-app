import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:app/ui/core/themes/theme.dart';
import 'package:app/ui/core/ui/content_column.dart';
import 'package:app/ui/core/ui/home_shell.dart';

/// The shell is chosen by window width, so these tests set a window size and
/// check which navigation appeared. That is the whole contract: same routes,
/// same state, a different frame around them.
void main() {
  /// A router carrying the same three branches the real one does, since
  /// [HomeShell] needs a real [StatefulNavigationShell] to build.
  GoRouter buildRouter() => GoRouter(
    initialLocation: '/requests',
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => HomeShell(shell: shell),
        branches: [
          for (final name in ['requests', 'users', 'settings'])
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/$name',
                  builder: (context, state) => Center(child: Text('$name tab')),
                ),
              ],
            ),
        ],
      ),
    ],
  );

  Future<void> pumpAt(WidgetTester tester, Size size) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp.router(theme: AppTheme.dark(), routerConfig: buildRouter()),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('a narrow window navigates from the bottom', (tester) async {
    await pumpAt(tester, const Size(400, 800));

    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.byType(NavigationRail), findsNothing);
    expect(find.text('requests tab'), findsOneWidget);
  });

  testWidgets('a wide window navigates from the side', (tester) async {
    await pumpAt(tester, const Size(1000, 800));

    expect(find.byType(NavigationRail), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
  });

  testWidgets('the rail stays collapsed until there is room for labels', (
    tester,
  ) async {
    await pumpAt(tester, const Size(1000, 800));
    expect(
      tester.widget<NavigationRail>(find.byType(NavigationRail)).extended,
      isFalse,
    );

    await pumpAt(tester, const Size(1400, 900));
    expect(
      tester.widget<NavigationRail>(find.byType(NavigationRail)).extended,
      isTrue,
    );
  });

  testWidgets('both layouts offer the same destinations', (tester) async {
    for (final size in [const Size(400, 800), const Size(1200, 800)]) {
      await pumpAt(tester, size);

      for (final label in ['Requests', 'People', 'Settings']) {
        expect(
          find.text(label),
          findsWidgets,
          reason: 'at width ${size.width}',
        );
      }
    }
  });

  testWidgets('tapping a destination switches branch in either layout', (
    tester,
  ) async {
    for (final size in [const Size(400, 800), const Size(1200, 800)]) {
      await pumpAt(tester, size);

      await tester.tap(find.text('Settings').last);
      await tester.pumpAndSettle();

      expect(
        find.text('settings tab'),
        findsOneWidget,
        reason: 'at width ${size.width}',
      );
    }
  });

  // Without this the request list would stretch the full width of a desktop
  // window, which is the thing the wide layout exists to prevent.
  testWidgets('page content is capped and centred', (tester) async {
    await pumpAt(tester, const Size(1600, 900));

    expect(find.byType(ContentColumn), findsOneWidget);

    // ContentColumn is an Align, so it fills the window on purpose; the cap is
    // on the box inside it, which is what the page actually gets to use.
    final capped = tester.getSize(
      find
          .descendant(
            of: find.byType(ContentColumn),
            matching: find.byType(ConstrainedBox),
          )
          .first,
    );
    expect(capped.width, lessThanOrEqualTo(840));

    // ...and what is left over is split evenly, so the column sits centred in
    // the space beside the rail rather than hugging one edge.
    final railWidth = tester.getSize(find.byType(NavigationRail)).width;
    final content = tester.getRect(
      find
          .descendant(
            of: find.byType(ContentColumn),
            matching: find.byType(ConstrainedBox),
          )
          .first,
    );
    final available = 1600 - railWidth;
    expect(content.center.dx - railWidth, closeTo(available / 2, 2));
  });
}
