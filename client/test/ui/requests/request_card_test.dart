import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app/domain/models/priority.dart';
import 'package:app/domain/models/request_status.dart';
import 'package:app/ui/core/themes/theme.dart';
import 'package:app/ui/requests/widgets/request_card.dart';

import '../../fakes/fixtures.dart';

/// Wraps a widget in the minimum the framework needs (a Directionality, a
/// Theme, a Material ancestor) so one widget can be pumped in isolation.
Widget harness(Widget child) => MaterialApp(
  theme: AppTheme.dark(),
  home: Scaffold(body: child),
);

void main() {
  testWidgets('renders the request summary', (tester) async {
    final request = buildRequest(
      status: RequestStatus.inProgress,
      priority: Priority.critical,
      assignee: kStaff,
    );

    await tester.pumpWidget(
      harness(RequestCard(request: request, onTap: () {})),
    );

    expect(find.text('Laptop cannot connect to Wi-Fi'), findsOneWidget);
    expect(find.text('#42'), findsOneWidget);
    // Badges are upper-cased for display.
    expect(find.text('IN PROGRESS'), findsOneWidget);
    expect(find.text('CRITICAL'), findsOneWidget);
    expect(find.text('Network'), findsOneWidget);
    expect(find.text('Malis Tep'), findsOneWidget);
    expect(find.text('Bopha Lim'), findsOneWidget);
  });

  testWidgets('an unassigned request says so', (tester) async {
    await tester.pumpWidget(
      harness(RequestCard(request: buildRequest(), onTap: () {})),
    );

    expect(find.text('Unassigned'), findsOneWidget);
  });

  testWidgets('reports taps', (tester) async {
    var taps = 0;

    await tester.pumpWidget(
      harness(RequestCard(request: buildRequest(), onTap: () => taps++)),
    );
    await tester.tap(find.byType(RequestCard));

    expect(taps, 1);
  });
}
