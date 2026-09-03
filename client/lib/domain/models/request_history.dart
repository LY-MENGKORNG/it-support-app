import 'package:app/utils/json.dart';

import 'request_history_action.dart';
import 'user.dart';

class RequestHistory {
  const RequestHistory({
    required this.id,
    required this.requestId,
    required this.action,
    required this.actor,
    required this.createdAt,
    this.oldValue,
    this.newValue,
  });

  final int id;
  final int requestId;
  final RequestHistoryAction action;
  final User actor;
  final DateTime createdAt;
  final String? oldValue;
  final String? newValue;

  factory RequestHistory.fromJson(Json json) => RequestHistory(
    id: intOf(json, 'id'),
    requestId: intOf(json, 'requestId'),
    action: RequestHistoryAction.fromWire(stringOf(json, 'action')),
    actor: User.fromJson(objectOf(json, 'user')),
    createdAt: dateOf(json, 'createdAt'),
    oldValue: stringOrNull(json, 'oldValue'),
    newValue: stringOrNull(json, 'newValue'),
  );
}
