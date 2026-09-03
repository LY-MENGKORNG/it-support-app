import 'package:app/domain/models/user.dart';
import 'package:app/domain/models/user_role.dart';
import 'package:app/utils/result.dart';

import 'rest_client.dart';

class UserApi {
  const UserApi(this._client);

  final RestClient _client;

  static const _path = '/user';

  Future<Result<List<User>>> list({
    String? query,
    UserRole? role,
    int limit = 50,
    int offset = 0,
  }) => _client.get(
    _path,
    asList(User.fromJson),
    query: {
      if (query != null && query.trim().isNotEmpty) 'q': query.trim(),
      if (role != null) 'role': role.wire,
      'limit': limit,
      'offset': offset,
    },
  );

  Future<Result<List<User>>> assignable() =>
      _client.get('$_path/assignable', asList(User.fromJson));

  Future<Result<User>> get(int id) =>
      _client.get('$_path/$id', asObject(User.fromJson));
}
