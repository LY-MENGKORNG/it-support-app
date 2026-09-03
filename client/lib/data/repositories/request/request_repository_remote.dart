import 'package:app/data/services/api/comment_api.dart';
import 'package:app/data/services/api/request_api.dart';
import 'package:app/domain/models/comment.dart';
import 'package:app/domain/models/request.dart';
import 'package:app/domain/models/request_filters.dart';
import 'package:app/utils/result.dart';

import 'request_repository.dart';

class RemoteRequestRepository implements RequestRepository {
  const RemoteRequestRepository({
    required this._requests,
    required this._comments,
  });

  final RequestApi _requests;
  final CommentApi _comments;

  @override
  Future<Result<RequestPage>> getRequests(RequestFilters filters) =>
      _requests.list(filters);

  @override
  Future<Result<RequestDetail>> getRequest(int id) => _requests.get(id);

  @override
  Future<Result<RequestDetail>> createRequest(NewRequest draft) =>
      _requests.create(draft);

  @override
  Future<Result<RequestDetail>> updateRequest(int id, RequestPatch patch) =>
      _requests.update(id, patch);

  @override
  Future<Result<Comment>> addComment(
    int requestId, {
    required String content,
  }) => _comments.create(requestId, content: content);
}
