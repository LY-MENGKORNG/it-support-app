import 'priority.dart';
import 'request_sort.dart';
import 'request_status.dart';

class RequestFilters {
  const RequestFilters({
    this.query,
    this.status,
    this.priority,
    this.categoryId,
    this.requesterId,
    this.assigneeId,
    this.unassignedOnly = false,
    this.sort = RequestSort.newest,
    this.limit = 20,
    this.offset = 0,
  });

  final String? query;
  final RequestStatus? status;
  final Priority? priority;
  final int? categoryId;
  final int? requesterId;
  final int? assigneeId;
  final bool unassignedOnly;
  final RequestSort sort;
  final int limit;
  final int offset;

  bool get isFiltering =>
      (query != null && query!.isNotEmpty) ||
      status != null ||
      priority != null ||
      categoryId != null ||
      requesterId != null ||
      assigneeId != null ||
      unassignedOnly;

  RequestFilters copyWith({
    String? query,
    RequestStatus? status,
    Priority? priority,
    int? categoryId,
    int? requesterId,
    int? assigneeId,
    bool? unassignedOnly,
    RequestSort? sort,
    int? limit,
    int? offset,
    bool clearQuery = false,
    bool clearStatus = false,
    bool clearPriority = false,
    bool clearCategory = false,
    bool clearAssignee = false,
    bool clearRequester = false,
  }) => RequestFilters(
    query: clearQuery ? null : (query ?? this.query),
    status: clearStatus ? null : (status ?? this.status),
    priority: clearPriority ? null : (priority ?? this.priority),
    categoryId: clearCategory ? null : (categoryId ?? this.categoryId),
    requesterId: clearRequester ? null : (requesterId ?? this.requesterId),
    assigneeId: clearAssignee ? null : (assigneeId ?? this.assigneeId),
    unassignedOnly: unassignedOnly ?? this.unassignedOnly,
    sort: sort ?? this.sort,
    limit: limit ?? this.limit,
    offset: offset ?? this.offset,
  );

  Map<String, dynamic> toQueryParameters() => {
    if (query != null && query!.trim().isNotEmpty) 'q': query!.trim(),
    if (status != null) 'status': status!.wire,
    if (priority != null) 'priority': priority!.wire,
    if (categoryId != null) 'categoryId': categoryId,
    if (requesterId != null) 'requesterId': requesterId,
    if (assigneeId != null) 'assigneeId': assigneeId,
    if (unassignedOnly) 'unassigned': 'true',
    'sort': sort.wire,
    'limit': limit,
    'offset': offset,
  };
}
