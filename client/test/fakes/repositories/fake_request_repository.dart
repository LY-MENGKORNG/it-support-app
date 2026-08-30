import 'package:app/data/repositories/request/request_repository.dart';
import 'package:app/domain/models/comment.dart';
import 'package:app/domain/models/request.dart';
import 'package:app/domain/models/request_filters.dart';
import 'package:app/utils/result.dart';

import '../fixtures.dart';

/// An in-memory [RequestRepository].
///
/// A fake rather than a mock: it actually behaves like a repository, so a test
/// asserts on real outcomes ("the list now has two rows") instead of on which
/// methods happened to be called.
class FakeRequestRepository implements RequestRepository {
  FakeRequestRepository({List<Request>? requests}) : _requests = [...?requests];

  final List<Request> _requests;

  /// Set to make the next call fail, so error paths can be exercised.
  Exception? error;

  /// Every filter this repository was asked for, in order — lets a test assert
  /// that paging and search actually reached the data layer.
  final List<RequestFilters> receivedFilters = [];

  int _nextId = 100;

  @override
  Future<Result<RequestPage>> getRequests(RequestFilters filters) async {
    receivedFilters.add(filters);
    if (error != null) return Result.error(error!);

    final matching = _requests.where((request) {
      if (filters.status != null && request.status != filters.status) {
        return false;
      }
      if (filters.priority != null && request.priority != filters.priority) {
        return false;
      }
      final query = filters.query;
      if (query != null && query.isNotEmpty) {
        return request.title.toLowerCase().contains(query.toLowerCase());
      }
      return true;
    }).toList();

    final page = matching.skip(filters.offset).take(filters.limit).toList();

    return Result.ok(
      RequestPage(
        items: page,
        total: matching.length,
        hasMore: filters.offset + page.length < matching.length,
      ),
    );
  }

  @override
  Future<Result<RequestDetail>> getRequest(int id) async {
    if (error != null) return Result.error(error!);

    for (final request in _requests) {
      if (request.id == id) {
        return Result.ok(
          RequestDetail(
            request: request,
            comments: const [],
            history: const [],
          ),
        );
      }
    }
    return Result.error(Exception('Request $id not found'));
  }

  @override
  Future<Result<RequestDetail>> createRequest(NewRequest draft) async {
    if (error != null) return Result.error(error!);

    final created = buildRequest(id: _nextId++);
    _requests.insert(0, created);
    return Result.ok(
      RequestDetail(request: created, comments: const [], history: const []),
    );
  }

  @override
  Future<Result<RequestDetail>> updateRequest(
    int id,
    RequestPatch patch,
  ) async {
    if (error != null) return Result.error(error!);

    final index = _requests.indexWhere((request) => request.id == id);
    if (index == -1) return Result.error(Exception('Request $id not found'));

    final before = _requests[index];
    final updated = Request(
      id: before.id,
      title: patch.title ?? before.title,
      description: patch.description ?? before.description,
      category: before.category,
      priority: patch.priority ?? before.priority,
      status: patch.status ?? before.status,
      requester: before.requester,
      assignee: patch.unassign
          ? null
          : (patch.assigneeId == null ? before.assignee : kStaff),
      createdAt: before.createdAt,
      updatedAt: DateTime.now(),
    );
    _requests[index] = updated;

    return Result.ok(
      RequestDetail(request: updated, comments: const [], history: const []),
    );
  }

  @override
  Future<Result<Comment>> addComment(
    int requestId, {
    required String content,
  }) async {
    if (error != null) return Result.error(error!);

    return Result.ok(
      Comment(
        id: _nextId++,
        requestId: requestId,
        content: content,
        author: kStaff,
        createdAt: DateTime.now(),
      ),
    );
  }
}
