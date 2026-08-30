import 'package:app/data/services/api/api_client.dart';
import 'package:app/domain/models/user.dart';
import 'package:app/domain/models/user_role.dart';
import 'package:app/utils/result.dart';

import 'user_repository.dart';

class UserRepositoryRemote implements UserRepository {
  UserRepositoryRemote({required this._apiClient});

  final ApiClient _apiClient;

  /// Caching is a repository concern, which is exactly why this list lives here
  /// and not in a view model: every detail screen asks for the assignable
  /// staff, and the answer changes rarely.
  List<User>? _assignableCache;

  @override
  Future<Result<List<User>>> getUsers({
    String? query,
    UserRole? role,
    int limit = 50,
    int offset = 0,
  }) => _apiClient.getUsers(
    query: query,
    role: role,
    limit: limit,
    offset: offset,
  );

  @override
  Future<Result<List<User>>> getAssignableUsers({bool refresh = false}) async {
    final cached = _assignableCache;
    if (!refresh && cached != null) return Result.ok(cached);

    final result = await _apiClient.getAssignableUsers();
    if (result is Ok<List<User>>) _assignableCache = result.value;
    return result;
  }

  @override
  Future<Result<User>> getUser(int id) => _apiClient.getUser(id);
}
