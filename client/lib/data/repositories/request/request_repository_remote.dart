import 'package:app/data/services/api/api_client.dart';
import 'package:app/domain/models/comment.dart';
import 'package:app/domain/models/request.dart';
import 'package:app/domain/models/request_filters.dart';
import 'package:app/utils/result.dart';

import 'request_repository.dart';

/// Request data backed by the HTTP API.
///
/// Currently a straight pass-through. It exists anyway so that adding a cache,
/// an offline queue, or a second data source later is a change to *this* class
/// rather than to every view model that reads requests.
class RequestRepositoryRemote implements RequestRepository {
  const RequestRepositoryRemote({required this._apiClient});

  final ApiClient _apiClient;

  @override
  Future<Result<RequestPage>> getRequests(RequestFilters filters) =>
      _apiClient.getRequests(filters);

  @override
  Future<Result<RequestDetail>> getRequest(int id) => _apiClient.getRequest(id);

  @override
  Future<Result<RequestDetail>> createRequest(NewRequest draft) =>
      _apiClient.postRequest(draft);

  @override
  Future<Result<RequestDetail>> updateRequest(int id, RequestPatch patch) =>
      _apiClient.patchRequest(id, patch);

  @override
  Future<Result<Comment>> addComment(
    int requestId, {
    required String content,
  }) => _apiClient.postComment(requestId, content: content);
}
