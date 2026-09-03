import 'package:app/domain/models/comment.dart';
import 'package:app/domain/models/request.dart';
import 'package:app/domain/models/request_filters.dart';
import 'package:app/utils/result.dart';

abstract interface class RequestRepository {
  Future<Result<RequestPage>> getRequests(RequestFilters filters);

  Future<Result<RequestDetail>> getRequest(int id);

  Future<Result<RequestDetail>> createRequest(NewRequest draft);

  Future<Result<RequestDetail>> updateRequest(int id, RequestPatch patch);

  Future<Result<Comment>> addComment(int requestId, {required String content});
}
