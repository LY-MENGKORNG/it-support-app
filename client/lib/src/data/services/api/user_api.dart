import 'package:app/src/core/network/api_client.dart';
import 'package:app/src/data/models/user_model.dart';
import 'package:flutter/foundation.dart';

import 'package:http/http.dart' as http;

class UserApiService {
  final ApiClient apiClient = ApiClient(client: http.Client());

  Future<List<UserModel>> fetchUsers() async {
    final res = await apiClient.get('/user');

    if (res.statusCode != 200) {
      throw Exception('failed to fetch users');
    }

    /**
      Asynchronously runs the given [callback] (`UserModel.parseMany`) - with the provided [message] (`res.body`) -
      in the background and completes with the result.

      This is useful for operations that take longer than a few milliseconds, and
      which would therefore risk skipping frames. For tasks that will only take up
      to a millisecond, consider [SchedulerBinding.scheduleTask] instead.
     */
    return compute(UserModel.parseMany, res.body);
  }
}
