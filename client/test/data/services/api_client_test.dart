import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:app/data/services/api/api_client.dart';
import 'package:app/data/services/api/api_exception.dart';
import 'package:app/domain/models/priority.dart';
import 'package:app/domain/models/request.dart';
import 'package:app/domain/models/request_filters.dart';
import 'package:app/domain/models/request_sort.dart';
import 'package:app/domain/models/request_status.dart';
import 'package:app/utils/result.dart';

import '../../fakes/fixtures.dart';

/// Builds a real [ApiClient] over a stubbed transport, so these tests exercise
/// URL building, status handling and JSON parsing together — the parts most
/// likely to drift from the server — without touching the network.
({ApiClient client, List<http.Request> sent}) buildClient(
  http.Response Function(http.Request) handler, {
  String? token,
  void Function()? onUnauthorized,
}) {
  final sent = <http.Request>[];
  final mock = MockClient((request) async {
    sent.add(request);
    return handler(request);
  });

  return (
    client: ApiClient(
      client: mock,
      baseUrl: 'http://test',
      authTokenProvider: token == null ? null : () => token,
      onUnauthorized: onUnauthorized,
    ),
    sent: sent,
  );
}

http.Response ok(Object body) => http.Response(
  jsonEncode(body),
  200,
  headers: {'content-type': 'application/json'},
);

http.Response fail(int status, Object body) => http.Response(
  jsonEncode(body),
  status,
  headers: {'content-type': 'application/json'},
);

void main() {
  group('getRequests', () {
    test('sends every active filter as a query parameter', () async {
      final (:client, :sent) = buildClient(
        (_) => ok(pageJson([requestJson()])),
      );

      await client.getRequests(
        const RequestFilters(
          query: 'wifi',
          status: RequestStatus.inProgress,
          priority: Priority.high,
          categoryId: 3,
          sort: RequestSort.priority,
          offset: 40,
        ),
      );

      final params = sent.single.url.queryParameters;
      expect(params['q'], 'wifi');
      expect(params['status'], 'in_progress');
      expect(params['priority'], 'high');
      expect(params['categoryId'], '3');
      expect(params['sort'], 'priority');
      expect(params['offset'], '40');
    });

    test('parses the page envelope', () async {
      final (:client, sent: _) = buildClient(
        (_) => ok(
          pageJson(
            [requestJson(), requestJson(id: 43)],
            total: 51,
            hasMore: true,
          ),
        ),
      );

      final result = await client.getRequests(const RequestFilters());

      expect(result, isA<Ok<RequestPage>>());
      expect(result.asOk.value.items, hasLength(2));
      expect(result.asOk.value.total, 51);
      expect(result.asOk.value.hasMore, isTrue);
    });
  });

  group('failures come back as Result.error, never as a throw', () {
    test('a 404 becomes a typed HttpException', () async {
      final (:client, sent: _) = buildClient(
        (_) => fail(404, {'message': 'Request 9 not found'}),
      );

      final result = await client.getRequest(9);

      expect(result, isA<Error<RequestDetail>>());
      final error = result.asError.error;
      expect(error, isA<HttpException>());
      expect((error as HttpException).isNotFound, isTrue);
      expect(error.message, 'Request 9 not found');
    });

    test('validation errors are surfaced per field', () async {
      final (:client, sent: _) = buildClient(
        (_) => fail(400, {
          'message': 'Validation failed',
          'errors': [
            {'path': 'title', 'message': 'Too small: expected >=3 characters'},
          ],
        }),
      );

      final result = await client.postRequest(
        const NewRequest(
          title: 'x',
          description: 'y',
          categoryId: 1,
          priority: Priority.low,
        ),
      );

      final error = result.asError.error as HttpException;
      expect(error.isValidation, isTrue);
      expect(error.fieldErrors['title'], contains('>=3'));
    });

    test('a dropped connection becomes a NetworkException', () async {
      final client = ApiClient(
        client: MockClient(
          (_) async => throw http.ClientException('Connection refused'),
        ),
        baseUrl: 'http://test',
      );

      final result = await client.getRequests(const RequestFilters());

      expect(result.asError.error, isA<NetworkException>());
    });

    test(
      'a non-JSON body is reported as a parse failure, not a crash',
      () async {
        final (:client, sent: _) = buildClient(
          (_) => http.Response('<html>502 Bad Gateway</html>', 200),
        );

        final result = await client.getRequests(const RequestFilters());

        expect(result.asError.error, isA<ParseException>());
      },
    );

    test('an unexpected response shape is a ParseException too', () async {
      // 200 OK, valid JSON, wrong shape — the contract-mismatch case.
      final (:client, sent: _) = buildClient((_) => ok({'unexpected': true}));

      final result = await client.getRequests(const RequestFilters());

      expect(result.asError.error, isA<ParseException>());
    });
  });

  group('mutations', () {
    test('PATCH sends the patch body and parses the updated record', () async {
      final (:client, :sent) = buildClient(
        (_) => ok(requestDetailJson(status: 'resolved')),
      );

      final result = await client.patchRequest(
        42,
        const RequestPatch(status: RequestStatus.resolved),
      );

      expect(sent.single.method, 'PATCH');
      expect(sent.single.url.path, '/request/42');
      // No actor on the wire — the server takes it from the token.
      expect(jsonDecode(sent.single.body), {'status': 'resolved'});
      expect(result.asOk.value.request.status, RequestStatus.resolved);
    });

    test('comments POST to the nested route', () async {
      final (:client, :sent) = buildClient((_) => ok(commentJson()));

      final result = await client.postComment(42, content: 'On it.');

      expect(sent.single.url.path, '/request/42/comment');
      expect(jsonDecode(sent.single.body), {'content': 'On it.'});
      expect(result.asOk.value.author.name, 'Bopha Lim');
    });
  });

  group('authentication', () {
    test('login posts credentials without a bearer header', () async {
      final (:client, :sent) = buildClient(
        (_) => ok({'accessToken': 'jwt-123', 'user': userJson()}),
        // A token is available, and must still not be sent: a stale one must
        // not be able to affect whether a fresh sign-in succeeds.
        token: 'stale-token',
      );

      final result = await client.login(
        email: 'bopha.lim@example.com',
        password: 'password-123',
      );

      expect(sent.single.method, 'POST');
      expect(sent.single.url.path, '/auth/login');
      expect(sent.single.headers.containsKey('authorization'), isFalse);
      expect(jsonDecode(sent.single.body), {
        'email': 'bopha.lim@example.com',
        'password': 'password-123',
      });
      expect(result.asOk.value.accessToken, 'jwt-123');
      expect(result.asOk.value.user.name, 'Bopha Lim');
    });

    test('every other call carries the bearer token', () async {
      final (:client, :sent) = buildClient(
        (_) => ok(requestDetailJson()),
        token: 'jwt-123',
      );

      await client.getRequest(42);

      expect(sent.single.headers['authorization'], 'Bearer jwt-123');
    });

    test('no token means no header, rather than an empty one', () async {
      final (:client, :sent) = buildClient((_) => ok(requestDetailJson()));

      await client.getRequest(42);

      expect(sent.single.headers.containsKey('authorization'), isFalse);
    });

    test('a 401 reports the dead session exactly once', () async {
      var unauthorizedCalls = 0;
      final (:client, sent: _) = buildClient(
        (_) => fail(401, {'message': 'Invalid or expired session'}),
        token: 'expired',
        onUnauthorized: () => unauthorizedCalls++,
      );

      final result = await client.getRequest(42);

      expect(unauthorizedCalls, 1);
      expect((result.asError.error as HttpException).isUnauthorized, isTrue);
    });

    test('a 401 from login does not end the session', () async {
      // Signing in is the one place a 401 is an ordinary answer — "wrong
      // password" must not be reported as an expired session.
      var unauthorizedCalls = 0;
      final (:client, sent: _) = buildClient(
        (_) => fail(401, {'message': 'Invalid email or password'}),
        onUnauthorized: () => unauthorizedCalls++,
      );

      final result = await client.login(email: 'a@b.com', password: 'nope');

      expect(unauthorizedCalls, 0);
      expect((result.asError.error as HttpException).isUnauthorized, isTrue);
    });

    test('/auth/me parses the signed-in user', () async {
      final (:client, :sent) = buildClient(
        (_) => ok(userJson()),
        token: 'jwt-123',
      );

      final result = await client.getCurrentUser();

      expect(sent.single.url.path, '/auth/me');
      expect(result.asOk.value.email, 'bopha.lim@example.com');
    });
  });
}
