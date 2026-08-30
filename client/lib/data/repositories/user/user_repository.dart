import 'package:app/domain/models/user.dart';
import 'package:app/domain/models/user_role.dart';
import 'package:app/utils/result.dart';

/// The source of truth for people.
abstract class UserRepository {
  Future<Result<List<User>>> getUsers({
    String? query,
    UserRole? role,
    int limit,
    int offset,
  });

  /// Staff and admins — the only people a request can be assigned to.
  Future<Result<List<User>>> getAssignableUsers({bool refresh = false});

  Future<Result<User>> getUser(int id);
}
