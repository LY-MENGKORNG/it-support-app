import 'package:app/domain/models/session.dart';
import 'package:app/domain/models/user.dart';
import 'package:app/utils/result.dart';

import 'rest_client.dart';

class AuthApi {
  const AuthApi(this._client);

  final RestClient _client;

  Future<Result<Session>> login({
    required String email,
    required String password,
  }) => _client.post(
    '/auth/login',
    asObject(Session.fromJson),
    body: {'email': email, 'password': password},
    authenticated: false,
  );

  Future<Result<User>> currentUser() =>
      _client.get('/auth/me', asObject(User.fromJson));
}
