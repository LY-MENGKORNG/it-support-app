import 'package:app/utils/json.dart';

import 'request_category.dart';
import 'comment.dart';
import 'priority.dart';
import 'request_history.dart';
import 'request_status.dart';
import 'user.dart';

/// A support request as it appears in a list: everything needed to render a
/// row, nothing more. Comments and history belong to [RequestDetail].
class Request {
  const Request({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.priority,
    required this.status,
    required this.requester,
    required this.createdAt,
    required this.updatedAt,
    this.assignee,
    this.resolvedAt,
    this.closedAt,
  });

  final int id;
  final String title;
  final String description;
  final RequestCategory category;
  final Priority priority;
  final RequestStatus status;
  final User requester;

  /// Null while the request is waiting to be picked up.
  final User? assignee;

  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? resolvedAt;
  final DateTime? closedAt;

  bool get isAssigned => assignee != null;

  factory Request.fromJson(Json json) => Request(
    id: intOf(json, 'id'),
    title: stringOf(json, 'title'),
    description: stringOf(json, 'description'),
    category: RequestCategory.fromJson(objectOf(json, 'category')),
    priority: Priority.fromWire(stringOf(json, 'priority')),
    status: RequestStatus.fromWire(stringOf(json, 'status')),
    requester: User.fromJson(objectOf(json, 'requester')),
    assignee: switch (objectOrNull(json, 'assignee')) {
      final Json user => User.fromJson(user),
      null => null,
    },
    createdAt: dateOf(json, 'createdAt'),
    updatedAt: dateOf(json, 'updatedAt'),
    resolvedAt: dateOrNull(json, 'resolvedAt'),
    closedAt: dateOrNull(json, 'closedAt'),
  );
}

/// A request plus the two collections only the detail screen needs.
///
/// Composition rather than inheritance: a detail *has* a request, so every
/// widget that renders a summary keeps working unchanged.
class RequestDetail {
  const RequestDetail({
    required this.request,
    required this.comments,
    required this.history,
  });

  final Request request;
  final List<Comment> comments;
  final List<RequestHistory> history;

  int get id => request.id;

  factory RequestDetail.fromJson(Json json) => RequestDetail(
    request: Request.fromJson(json),
    comments: listOf(json, 'comments', Comment.fromJson),
    history: listOf(json, 'history', RequestHistory.fromJson),
  );

  RequestDetail copyWith({
    Request? request,
    List<Comment>? comments,
    List<RequestHistory>? history,
  }) => RequestDetail(
    request: request ?? this.request,
    comments: comments ?? this.comments,
    history: history ?? this.history,
  );
}

/// One page of requests, with the totals the list view needs to page through.
class RequestPage {
  const RequestPage({
    required this.items,
    required this.total,
    required this.hasMore,
  });

  final List<Request> items;
  final int total;
  final bool hasMore;

  factory RequestPage.fromJson(Json json) => RequestPage(
    items: listOf(json, 'items', Request.fromJson),
    total: intOf(json, 'total'),
    hasMore: boolOr(json, 'hasMore', fallback: false),
  );
}

/// The payload for creating a request.
///
/// There is no `requesterId`: the server reads the requester from the access
/// token, so raising a request in someone else's name is not something this
/// payload can express.
class NewRequest {
  const NewRequest({
    required this.title,
    required this.description,
    required this.categoryId,
    required this.priority,
    this.assigneeId,
  });

  final String title;
  final String description;
  final int categoryId;
  final Priority priority;

  /// Only IT staff may set this; the server rejects it from anyone else.
  final int? assigneeId;

  Json toJson() => {
    'title': title,
    'description': description,
    'categoryId': categoryId,
    'priority': priority.wire,
    if (assigneeId != null) 'assigneeId': assigneeId,
  };
}

/// A partial update to a request.
///
/// Only non-null fields are serialised, because the server treats an absent key
/// as "leave alone". [unassign] exists because clearing an assignee has to send
/// an explicit `assigneeId: null`, which an omitted field cannot express.
///
/// Like [NewRequest], it carries no actor. Every change is recorded in the
/// request's history against whoever the token says made it.
class RequestPatch {
  const RequestPatch({
    this.title,
    this.description,
    this.categoryId,
    this.priority,
    this.status,
    this.assigneeId,
    this.unassign = false,
  });

  final String? title;
  final String? description;
  final int? categoryId;
  final Priority? priority;
  final RequestStatus? status;
  final int? assigneeId;
  final bool unassign;

  Json toJson() => {
    if (title != null) 'title': title,
    if (description != null) 'description': description,
    if (categoryId != null) 'categoryId': categoryId,
    if (priority != null) 'priority': priority!.wire,
    if (status != null) 'status': status!.wire,
    if (unassign)
      'assigneeId': null
    else if (assigneeId != null)
      'assigneeId': assigneeId,
  };
}
