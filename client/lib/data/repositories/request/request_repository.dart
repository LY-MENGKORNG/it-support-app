import 'package:app/domain/models/comment.dart';
import 'package:app/domain/models/request.dart';
import 'package:app/domain/models/request_filters.dart';
import 'package:app/utils/result.dart';

/// The source of truth for request data.
///
/// Abstract so the implementation can be swapped without touching a single
/// view model — a remote one in production, a fake one in tests, and a local
/// one later if this app ever goes offline-first.
abstract class RequestRepository {
  Future<Result<RequestPage>> getRequests(RequestFilters filters);

  Future<Result<RequestDetail>> getRequest(int id);

  Future<Result<RequestDetail>> createRequest(NewRequest draft);

  Future<Result<RequestDetail>> updateRequest(int id, RequestPatch patch);

  Future<Result<Comment>> addComment(int requestId, {required String content});
}
