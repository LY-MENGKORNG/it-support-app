import 'package:app/data/services/api/user_api.dart';
import 'package:app/domain/models/user.dart';
import 'package:app/domain/models/user_role.dart';
import 'package:app/utils/result.dart';

import 'user_repository.dart';

class RemoteUserRepository implements UserRepository {
  RemoteUserRepository({required this._users});

  final UserApi _users;

  List<User>? _assignableCache;

  @override
  Future<Result<List<User>>> getUsers({
    String? query,
    UserRole? role,
    int limit = 50,
    int offset = 0,
  }) => _users.list(query: query, role: role, limit: limit, offset: offset);

  @override
  Future<Result<List<User>>> getAssignableUsers({bool refresh = false}) async {
    final cached = _assignableCache;
    if (!refresh && cached != null) return Result.ok(cached);

    final result = await _users.assignable();
    if (result is Ok<List<User>>) _assignableCache = result.value;
    return result;
  }

  @override
  Future<Result<User>> getUser(int id) => _users.get(id);
}
