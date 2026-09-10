import 'package:app/domain/models/session.dart';
import 'package:app/domain/models/user.dart';
import 'package:app/utils/api.dart';
import 'package:app/utils/result.dart';

class AuthApi {
  final RestClient _client;

  const AuthApi(this._client);

  Future<Result<Session>> login({
    required String email,
    required String password,
  }) {
    return _client.post(
      '/auth/login',
      asObject(Session.fromJson),
      body: {'email': email, 'password': password},
      authenticated: false,
    );
  }

  Future<Result<User>> currentUser() {
    return _client.get('/auth/me', asObject(User.fromJson));
  }
}
