import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:app/data/repositories/user/user_repository_remote.dart';
import 'package:app/data/services/api/rest_client.dart';
import 'package:app/data/services/api/user_api.dart';
import 'package:app/utils/result.dart';

import '../../fakes/fixtures.dart';

void main() {
  /// The repository over a stubbed transport, counting how often the network is
  /// actually reached — the only thing the cache is supposed to change.
  ({RemoteUserRepository repository, int Function() calls}) build(
    http.Response Function() respond,
  ) {
    var calls = 0;
    final client = RestClient(
      baseUrl: 'http://test',
      client: MockClient((_) async {
        calls++;
        return respond();
      }),
    );

    return (
      repository: RemoteUserRepository(users: UserApi(client)),
      calls: () => calls,
    );
  }

  http.Response users() => http.Response(
    jsonEncode([userJson()]),
    200,
    headers: {'content-type': 'application/json'},
  );

  group('UserRepositoryRemote', () {
    test('caches the assignable list so repeat callers hit it once', () async {
      final (:repository, :calls) = build(users);

      final first = await repository.getAssignableUsers();
      final second = await repository.getAssignableUsers();

      expect(calls(), 1, reason: 'the second call should be served from cache');
      expect(first.asOk.value, second.asOk.value);
    });

    test('refresh: true goes back to the network', () async {
      final (:repository, :calls) = build(users);

      await repository.getAssignableUsers();
      await repository.getAssignableUsers(refresh: true);

      expect(calls(), 2);
    });

    test('a failed fetch is not cached', () async {
      final (:repository, :calls) = build(
        () => http.Response(
          '{"message":"boom"}',
          500,
          headers: {'content-type': 'application/json'},
        ),
      );

      final failed = await repository.getAssignableUsers();
      await repository.getAssignableUsers();

      expect(failed, isA<Error>());
      expect(calls(), 2, reason: 'an error must not poison the cache');
    });
  });
}
