import 'package:json_annotation/json_annotation.dart';

import 'package:app/utils/json.dart';

import 'request_category.dart';
import 'priority.dart';
import 'request_status.dart';
import 'user.dart';

part 'generated/request.g.dart';

@JsonSerializable(checked: true, createToJson: false)
class Request {
  final int id;
  final String title;
  final String description;
  final RequestCategory category;

  @PriorityConverter()
  final Priority priority;

  @RequestStatusConverter()
  final RequestStatus status;

  final User requester;
  final User? assignee;

  @LocalDateTime()
  final DateTime createdAt;

  @LocalDateTime()
  final DateTime updatedAt;

  @LocalDateTimeOrNull()
  final DateTime? resolvedAt;

  @LocalDateTimeOrNull()
  final DateTime? closedAt;

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

  factory Request.fromJson(JsonType json) => _$RequestFromJson(json);

  bool get isAssigned => assignee != null;
}

@JsonSerializable(checked: true, createToJson: false)
class RequestPage {
  @JsonKey(defaultValue: <Request>[])
  final List<Request> items;

  final int total;

  @JsonKey(defaultValue: false)
  final bool hasMore;

  const RequestPage({
    required this.items,
    required this.total,
    required this.hasMore,
  });

  factory RequestPage.fromJson(JsonType json) => _$RequestPageFromJson(json);
}

@JsonSerializable(createFactory: false, includeIfNull: false)
class NewRequest {
  final String title;
  final String description;
  final int categoryId;

  @PriorityConverter()
  final Priority priority;

  final int? assigneeId;

  const NewRequest({
    required this.title,
    required this.description,
    required this.categoryId,
    required this.priority,
    this.assigneeId,
  });

  JsonType toJson() => _$NewRequestToJson(this);
}

/// Hand-written, because a patch's absent and null keys mean different things.
class RequestPatch {
  final String? title;
  final String? description;
  final int? categoryId;
  final Priority? priority;
  final RequestStatus? status;
  final int? assigneeId;
  final bool unassign;

  const RequestPatch({
    this.title,
    this.description,
    this.categoryId,
    this.priority,
    this.status,
    this.assigneeId,
    this.unassign = false,
  });

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
