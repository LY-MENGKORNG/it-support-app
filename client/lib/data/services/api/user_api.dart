import 'package:app/core/network/api_client.dart';
import 'package:app/data/models/user_model.dart';
import 'package:flutter/foundation.dart';

class UserApiService {
  final ApiClient _apiClient;

  UserApiService({required this._apiClient});

  Future<List<UserModel>> fetchUsers() async {
    final res = await _apiClient.get('/user');

    if (res.statusCode != 200) {
      throw Exception('failed to fetch users');
    }

    return compute(UserModel.parseUsers, res.body);
  }
}
