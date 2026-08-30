import 'package:app/data/repositories/user/user_repository.dart';
import 'package:app/domain/models/user.dart';
import 'package:app/domain/models/user_role.dart';
import 'package:app/utils/result.dart';

import '../fixtures.dart';

class FakeUserRepository implements UserRepository {
  FakeUserRepository({List<User>? users})
    : _users = users ?? const [kEmployee, kStaff];

  final List<User> _users;

  Exception? error;

  @override
  Future<Result<List<User>>> getUsers({
    String? query,
    UserRole? role,
    int limit = 50,
    int offset = 0,
  }) async {
    if (error != null) return Result.error(error!);

    return Result.ok(
      _users.where((user) {
        if (role != null && user.role != role) return false;
        if (query != null && query.isNotEmpty) {
          return user.name.toLowerCase().contains(query.toLowerCase());
        }
        return true;
      }).toList(),
    );
  }

  @override
  Future<Result<List<User>>> getAssignableUsers({bool refresh = false}) async {
    if (error != null) return Result.error(error!);
    return Result.ok(_users.where((user) => user.role.isSupportStaff).toList());
  }

  @override
  Future<Result<User>> getUser(int id) async {
    if (error != null) return Result.error(error!);

    for (final user in _users) {
      if (user.id == id) return Result.ok(user);
    }
    return Result.error(Exception('User $id not found'));
  }
}
