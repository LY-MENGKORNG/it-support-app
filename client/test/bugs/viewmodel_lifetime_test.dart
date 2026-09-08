import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';

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
/// `GoRouter` holds a subscription of its own, taken at construction for
/// `refreshListenable`, that is supposed to last for the whole run.
void main() {
  ({FakeSessionRepository session, GoRouter router, Widget app}) build() {
    // The route builders resolve these three from the registry. The session is
    // handed to `router` instead, so the object the guard redirects on and the
    // one the screens use cannot drift apart.
    Get.put<RequestRepository>(FakeRequestRepository());
    Get.put<CategoryRepository>(FakeCategoryRepository());
    Get.put<UserRepository>(FakeUserRepository());
    addTearDown(Get.reset);

    final session = FakeSessionRepository(user: kStaff);
    final router = routing.router(session);
    addTearDown(router.dispose);

    return (
      session: session,
      router: router,
      app: MaterialApp.router(routerConfig: router),
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

    // Settle to a signed-out baseline first: each loop iteration below signs
    // in and out again, so the count has to be measured from the same state it
    // will be compared against.
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
