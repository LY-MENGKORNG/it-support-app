import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app/ui/core/themes/theme.dart';
import 'package:app/ui/settings/view_models/settings_viewmodel.dart';
import 'package:app/ui/settings/widgets/settings_screen.dart';

import '../../fakes/fixtures.dart';
import '../../fakes/repositories/fake_session_repository.dart';

void main() {
  group('SettingsScreen', () {
    late FakeSessionRepository session;
    late SettingsViewModel viewModel;

    setUp(() {
      session = FakeSessionRepository(user: kStaff);
      viewModel = SettingsViewModel(sessionRepository: session);
    });

    tearDown(() => viewModel.dispose());

    Future<void> pumpScreen(WidgetTester tester) => tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark(),
        home: SettingsScreen(viewModel: viewModel),
      ),
    );

    testWidgets('shows the signed-in user', (tester) async {
      await pumpScreen(tester);

      expect(find.text('Bopha Lim'), findsOneWidget);
      expect(find.text('bopha.lim@example.com'), findsOneWidget);
      expect(find.text('IT Staff'), findsOneWidget);
    });

    // The whole point of the abstract repository: the screen is exercised
    // against a fake, with no HTTP and no shared_preferences in sight.
    testWidgets('signing out clears the session and the screen', (
      tester,
    ) async {
      await pumpScreen(tester);
      expect(find.text('Sign out'), findsOneWidget);

      await tester.tap(find.text('Sign out'));
      await tester.pumpAndSettle();

      expect(session.currentUser, isNull);
      expect(find.text('Bopha Lim'), findsNothing);
      // The API row is not user-specific, so it survives.
      expect(find.text('API server'), findsOneWidget);
    });
  });
}
