import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:app/data/repositories/category/category_repository.dart';
import 'package:app/data/repositories/request/request_repository.dart';
import 'package:app/data/repositories/session/session_repository.dart';
import 'package:app/data/repositories/user/user_repository.dart';
import 'package:app/routing/router.dart' as routing;
import 'package:app/routing/routes.dart';

import '../fakes/fixtures.dart';
import '../fakes/repositories/fake_category_repository.dart';
import '../fakes/repositories/fake_request_repository.dart';
import '../fakes/repositories/fake_session_repository.dart';
import '../fakes/repositories/fake_user_repository.dart';

/// Reproduces the leak: view models were built inline in `GoRoute.builder`, so
/// nothing owned them and nothing ever called `dispose`. The one with a visible
/// symptom is `SettingsViewModel`, which subscribes to the shared
/// [SessionRepository] in its constructor — so every visit to Settings left
/// another permanent listener on an object that lives as long as the app, each
/// one still notifying a screen that had been gone for some time.
///
/// The session's listener count is the probe. Only deltas are asserted on:
/// `provider` and `GoRouter` hold subscriptions of their own that are supposed
/// to last for the whole run.
void main() {
  ({FakeSessionRepository session, GoRouter router, Widget app}) build() {
    final session = FakeSessionRepository(user: kStaff);
    final router = routing.router(session);
    addTearDown(router.dispose);

    return (
      session: session,
      router: router,
      app: MultiProvider(
        providers: [
          Provider<RequestRepository>.value(value: FakeRequestRepository()),
          Provider<CategoryRepository>.value(value: FakeCategoryRepository()),
          Provider<UserRepository>.value(value: FakeUserRepository()),
          ChangeNotifierProvider<SessionRepository>.value(value: session),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
  }

  Future<void> signInAgain(FakeSessionRepository session) =>
      session.signIn(email: 'bopha.lim@example.com', password: 'password-123');

  testWidgets('leaving a route disposes the view model it created', (
    tester,
  ) async {
    final it = build();
    await tester.pumpWidget(it.app);
    await tester.pumpAndSettle();

    it.router.go(Routes.settings);
    await tester.pumpAndSettle();
    final whileOpen = it.session.listenerCount;

    // Signing out sends the guard to /login, which takes the whole shell —
    // and every view model inside it — off the tree.
    await it.session.signOut();
    await tester.pumpAndSettle();

    expect(
      it.session.listenerCount,
      whileOpen - 1,
      reason: 'the settings view model must release its session listener',
    );
  });

  testWidgets('revisiting a route leaves no view models behind', (
    tester,
  ) async {
    final it = build();
    await tester.pumpWidget(it.app);
    await tester.pumpAndSettle();

    // Settle first: the count includes provider's own subscription, taken the
    // first time a route reads the session, and that one never comes back.
    it.router.go(Routes.settings);
    await tester.pumpAndSettle();
    await it.session.signOut();
    await tester.pumpAndSettle();
    final noViewModels = it.session.listenerCount;

    for (var visit = 0; visit < 3; visit++) {
      await signInAgain(it.session);
      await tester.pumpAndSettle();
      it.router.go(Routes.settings);
      await tester.pumpAndSettle();
      await it.session.signOut();
      await tester.pumpAndSettle();
    }

    expect(
      it.session.listenerCount,
      noViewModels,
      reason: 'three more visits to Settings must not accumulate listeners',
    );
  });
}
