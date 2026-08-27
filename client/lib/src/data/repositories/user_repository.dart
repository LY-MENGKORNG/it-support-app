import 'package:app/src/data/models/user_model.dart';
import 'package:app/src/data/services/api/user_api.dart';

class UserRepository {
  final UserApiService _apiService;

  UserRepository({required this._apiService});

  Future<List<UserModel>> getUsers() {
    return _apiService.fetchUsers();
  }
}
