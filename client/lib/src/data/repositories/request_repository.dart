import 'package:app/src/data/models/request_model.dart';
import 'package:app/src/data/services/api/request_api.dart';

class RequestRepository {
  final RequestApiService _apiService;

  RequestRepository({required this._apiService});

  Future<List<RequestModel>> getRequests() {
    return _apiService.fetchRequests();
  }
}
