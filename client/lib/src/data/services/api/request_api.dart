import 'package:app/src/core/network/api_client.dart';
import 'package:app/src/data/models/request_model.dart';
import 'package:flutter/foundation.dart';

import 'package:http/http.dart' as http;

class RequestApiService {
  final ApiClient apiClient = ApiClient(client: http.Client());

  Future<List<RequestModel>> fetchRequests() async {
    final res = await apiClient.get('/request');

    if (res.statusCode != 200) {
      throw Exception('failed to fetch users');
    }

    return compute(RequestModel.parseMany, res.body);
  }
}
