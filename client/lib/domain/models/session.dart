import 'package:json_annotation/json_annotation.dart';

import 'package:app/utils/json.dart';

import 'user.dart';

part 'generated/session.g.dart';

@JsonSerializable(checked: true, createToJson: false)
class Session {
  const Session({required this.accessToken, required this.user});

  factory Session.fromJson(JsonType json) => _$SessionFromJson(json);

  final String accessToken;
  final User user;

  @override
  String toString() => 'Session(${user.email})';
}
