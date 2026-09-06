import 'package:app/utils/json.dart';

import 'request_category.dart';
import 'comment.dart';
import 'priority.dart';
import 'request_history.dart';
import 'request_status.dart';
import 'user.dart';

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

  final User? assignee;

  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? resolvedAt;
  final DateTime? closedAt;

  bool get isAssigned => assignee != null;

  factory Request.fromJson(JsonType json) {
    final rj = Json(json);

    return Request(
      id: rj.intOf('id'),
      title: rj.stringOf('title'),
      description: rj.stringOf('description'),
      category: RequestCategory.fromJson(rj.objectOf('category')),
      priority: Priority.fromWire(rj.stringOf('priority')),
      status: RequestStatus.fromWire(rj.stringOf('status')),
      requester: User.fromJson(rj.objectOf('requester')),
      assignee: switch (rj.objectOrNull('assignee')) {
        final JsonType user => User.fromJson(user),
        null => null,
      },
      createdAt: rj.dateOf('createdAt'),
      updatedAt: rj.dateOf('updatedAt'),
      resolvedAt: rj.dateOrNull('resolvedAt'),
      closedAt: rj.dateOrNull('closedAt'),
    );
  }
}

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

  factory RequestDetail.fromJson(JsonType json) {
    final rdj = Json(json);

    return RequestDetail(
      request: Request.fromJson(json),
      comments: rdj.listOf('comments', Comment.fromJson),
      history: rdj.listOf('history', RequestHistory.fromJson),
    );
  }

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

class RequestPage {
  const RequestPage({
    required this.items,
    required this.total,
    required this.hasMore,
  });

  final List<Request> items;
  final int total;
  final bool hasMore;

  factory RequestPage.fromJson(JsonType json) {
    final rpj = Json(json);
    return RequestPage(
      items: rpj.listOf('items', Request.fromJson),
      total: rpj.intOf('total'),
      hasMore: rpj.boolOr('hasMore', fallback: false),
    );
  }
}

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

  final int? assigneeId;

  JsonType toJson() => {
    'title': title,
    'description': description,
    'categoryId': categoryId,
    'priority': priority.wire,
    if (assigneeId != null) 'assigneeId': assigneeId,
  };
}

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

  JsonType toJson() => {
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
