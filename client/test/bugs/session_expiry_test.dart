import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:app/data/repositories/session/session_repository.dart';
import 'package:app/data/repositories/session/session_repository_remote.dart';
import 'package:app/data/services/api/auth_api.dart';
import 'package:app/data/services/api/rest_client.dart';
import 'package:app/data/services/local/shared_preference_service.dart';
import 'package:app/routing/router.dart';
import 'package:app/utils/result.dart';

import '../fakes/fixtures.dart';

/// Reproduces the reported bug: when the session expires the app should send
/// the user back to the login screen, but it sits on a loading screen instead.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  http.Response ok(Object body) => http.Response(
    jsonEncode(body),
    200,
    headers: {'content-type': 'application/json'},
  );

  http.Response expired() => http.Response(
    jsonEncode({'message': 'Invalid or expired session'}),
    401,
    headers: {'content-type': 'application/json'},
  );

  ({RemoteSessionRepository session, RestClient client}) build(
    http.Response Function(http.Request) handler,
  ) {
    final client = RestClient(
      client: MockClient((request) async => handler(request)),
      baseUrl: 'http://test',
    );
    final session = RemoteSessionRepository(
      auth: AuthApi(client),
      preferences: const SharedPreferencesService(),
    );
    // Same wiring as config/di/dependencies.dart
    client.authTokenProvider = () => session.accessToken;
    client.onUnauthorized = session.signOut;
    return (session: session, client: client);
  }

  test('A: token already expired at startup -> session is cleared', () async {
    SharedPreferences.setMockInitialValues({'access_token': 'expired'});

    final it = build((request) => expired());
    await it.session.restore();

    expect(it.session.isRestoring, isFalse, reason: 'restore must finish');
    expect(it.session.isSignedIn, isFalse, reason: 'session must be cleared');
  });

  test('B: session expires WHILE using the app -> session is cleared', () async {
    SharedPreferences.setMockInitialValues({'access_token': 'good'});

    var expiredNow = false;
    final it = build((request) {
      if (expiredNow) return expired();
      return request.url.path == '/auth/me'
          ? ok(userJson())
          : ok(const <String, Object?>{});
    });

    await it.session.restore();
    expect(it.session.isSignedIn, isTrue, reason: 'signed in to begin with');

    var notified = 0;
    it.session.addListener(() => notified++);

    // The token expires on the server. The app makes an ordinary call.
    expiredNow = true;
    final call = await it.client.get<Object?>('/requests', (p) => p);
    expect(call, isA<Error<Object?>>(), reason: 'server rejected the call');

    // Give the fire-and-forget signOut() a chance to run.
    await Future<void>.delayed(Duration.zero);

    expect(notified, greaterThan(0), reason: 'router must be told to re-check');
    expect(
      it.session.isSignedIn,
      isFalse,
      reason: 'a 401 during normal use must clear the session',
    );
    expect(
      await const SharedPreferencesService().fetchToken(),
      isA<Ok<String?>>().having((r) => r.value, 'stored token', isNull),
      reason: 'the dead token must not survive on disk',
    );
  });

  testWidgets('C: cleared session sends the router to the login screen', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({'access_token': 'expired'});
    final it = build((request) => expired());

    await tester.pumpWidget(
      ChangeNotifierProvider<SessionRepository>.value(
        value: it.session,
        child: MaterialApp.router(routerConfig: router(it.session)),
      ),
    );

    await it.session.restore();
    await tester.pumpAndSettle();

    expect(find.text('Sign in'), findsWidgets, reason: 'should be on login');
  });
}
