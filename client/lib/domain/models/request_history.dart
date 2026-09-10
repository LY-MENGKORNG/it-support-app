import 'package:json_annotation/json_annotation.dart';

import 'package:app/utils/json.dart';

import 'request_history_action.dart';
import 'user.dart';

part 'generated/request_history.g.dart';

@JsonSerializable(checked: true, createToJson: false)
class RequestHistory {
  final int id;
  final int requestId;

  @RequestHistoryActionConverter()
  final RequestHistoryAction action;

  /// The API calls them `user`; in a history entry they are who acted.
  @JsonKey(name: 'user')
  final User actor;

  @LocalDateTime()
  final DateTime createdAt;

  final String? oldValue;
  final String? newValue;

  const RequestHistory({
    required this.id,
    required this.requestId,
    required this.action,
    required this.actor,
    required this.createdAt,
    this.oldValue,
    this.newValue,
  });

  factory RequestHistory.fromJson(JsonType json) =>
      _$RequestHistoryFromJson(json);
}
