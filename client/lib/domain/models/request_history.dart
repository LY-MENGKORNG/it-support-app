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

  factory RequestHistory.fromJson(JsonType json) {
    final rhj = Json(json);
    return RequestHistory(
      id: rhj.intOf('id'),
      requestId: rhj.intOf('requestId'),
      action: RequestHistoryAction.fromWire(rhj.stringOf('action')),
      actor: User.fromJson(rhj.objectOf('user')),
      createdAt: rhj.dateOf('createdAt'),
      oldValue: rhj.stringOrNull('oldValue'),
      newValue: rhj.stringOrNull('newValue'),
    );
  }
}
