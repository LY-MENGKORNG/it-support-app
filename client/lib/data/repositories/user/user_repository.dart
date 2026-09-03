import 'package:app/domain/models/user.dart';
import 'package:app/domain/models/user_role.dart';
import 'package:app/utils/result.dart';

abstract interface class UserRepository {
  Future<Result<List<User>>> getUsers({
    String? query,
    UserRole? role,
    int limit,
    int offset,
  });

  Future<Result<List<User>>> getAssignableUsers({bool refresh = false});

  Future<Result<User>> getUser(int id);
}
