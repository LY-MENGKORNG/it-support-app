import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:app/data/repositories/session/session_repository_remote.dart';
import 'package:app/data/services/api/api_client.dart';
import 'package:app/data/services/shared_preferences_service.dart';
import 'package:app/domain/models/user.dart';
import 'package:app/utils/result.dart';

import '../../fakes/fixtures.dart';

/// Exercises the real repository over a stubbed transport and the in-memory
/// `shared_preferences` backend, because the interesting behaviour here is
/// precisely how those two are kept in step — a fake for either would test
/// nothing worth testing.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late List<http.Request> sent;

  ({SessionRepositoryRemote session, ApiClient client}) build(
    http.Response Function(http.Request) handler,
  ) {
    sent = [];
    final mock = MockClient((request) async {
      sent.add(request);
      return handler(request);
    });

    final client = ApiClient(client: mock, baseUrl: 'http://test');
    final session = SessionRepositoryRemote(
      apiClient: client,
      preferences: const SharedPreferencesService(),
    );

    // Closing the loop the way `config/dependencies.dart` does, so a restored
    // token really is the one sent back to the server.
    client.authTokenProvider = () => session.accessToken;

    return (session: session, client: client);
  }

  http.Response ok(Object body) => http.Response(
    jsonEncode(body),
    200,
    headers: {'content-type': 'application/json'},
  );

  http.Response unauthorized() => http.Response(
    jsonEncode({'message': 'Invalid or expired session'}),
    401,
    headers: {'content-type': 'application/json'},
  );

  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('signIn', () {
    test('stores the token and exposes the user', () async {
      final (:session, client: _) = build(
        (_) => ok({'accessToken': 'jwt-123', 'user': userJson()}),
      );

      final result = await session.signIn(
        email: 'bopha.lim@example.com',
        password: 'password-123',
      );

      expect(result, isA<Ok<void>>());
      expect(session.isSignedIn, isTrue);
      expect(session.accessToken, 'jwt-123');
      expect(session.currentUser?.name, 'Bopha Lim');

      final stored = await const SharedPreferencesService().fetchToken();
      expect(stored.asOk.value, 'jwt-123');
    });

    test('a rejection leaves the app signed out and stores nothing', () async {
      final (:session, client: _) = build((_) => unauthorized());

      final result = await session.signIn(
        email: 'bopha.lim@example.com',
        password: 'wrong',
      );

      expect(result, isA<Error<void>>());
      expect(session.isSignedIn, isFalse);
      expect(session.accessToken, isNull);

      final stored = await const SharedPreferencesService().fetchToken();
      expect(stored.asOk.value, isNull);
    });

    test('notifies listeners so the router can redirect', () async {
      final (:session, client: _) = build(
        (_) => ok({'accessToken': 'jwt-123', 'user': userJson()}),
      );

      var notifications = 0;
      session.addListener(() => notifications++);

      await session.signIn(email: 'a@b.com', password: 'password-123');

      expect(notifications, 1);
    });
  });

  group('restore', () {
    test('with no stored token, signs nobody in and calls nothing', () async {
      final (:session, client: _) = build((_) => fail('no request expected'));

      final result = await session.restore();

      expect(result.asOk.value, isNull);
      expect(session.isSignedIn, isFalse);
      expect(session.isRestoring, isFalse);
      expect(sent, isEmpty);
    });

    test('a stored token is exchanged for the user it belongs to', () async {
      await const SharedPreferencesService().saveToken('jwt-123');
      final (:session, client: _) = build((_) => ok(userJson()));

      final result = await session.restore();

      expect(sent.single.url.path, '/auth/me');
      expect(sent.single.headers['authorization'], 'Bearer jwt-123');
      expect(result.asOk.value?.name, 'Bopha Lim');
      expect(session.isSignedIn, isTrue);
    });

    // A dead token must not wedge the app: the session has to end up cleanly
    // signed out, with nothing left on disk to fail the same way next launch.
    test('a rejected token is discarded rather than kept', () async {
      await const SharedPreferencesService().saveToken('expired');
      final (:session, client: _) = build((_) => unauthorized());

      final result = await session.restore();

      expect(result, isA<Ok<User?>>());
      expect(result.asOk.value, isNull);
      expect(session.isSignedIn, isFalse);
      expect(session.accessToken, isNull);

      final stored = await const SharedPreferencesService().fetchToken();
      expect(stored.asOk.value, isNull);
    });

    test('isRestoring is false once it finishes, even on failure', () async {
      await const SharedPreferencesService().saveToken('expired');
      final (:session, client: _) = build((_) => unauthorized());

      expect(session.isRestoring, isTrue);
      await session.restore();
      expect(session.isRestoring, isFalse);
    });
  });

  group('signOut', () {
    test('clears the session and the stored token', () async {
      final (:session, client: _) = build(
        (_) => ok({'accessToken': 'jwt-123', 'user': userJson()}),
      );
      await session.signIn(email: 'a@b.com', password: 'password-123');

      await session.signOut();

      expect(session.isSignedIn, isFalse);
      expect(session.accessToken, isNull);

      final stored = await const SharedPreferencesService().fetchToken();
      expect(stored.asOk.value, isNull);
    });
  });

  // The wiring in `config/dependencies.dart`, verified end to end: a token the
  // server no longer accepts ends the session by itself, wherever it is used.
  test('a 401 on an ordinary call signs the session out', () async {
    var responses = <http.Response>[
      ok({'accessToken': 'jwt-123', 'user': userJson()}),
      unauthorized(),
    ];
    final (:session, :client) = build((_) => responses.removeAt(0));
    client.onUnauthorized = session.signOut;

    await session.signIn(email: 'a@b.com', password: 'password-123');
    expect(session.isSignedIn, isTrue);

    await client.getRequest(42);

    expect(session.isSignedIn, isFalse);
    expect(session.accessToken, isNull);
  });
}
