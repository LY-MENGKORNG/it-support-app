import 'package:app/utils/json.dart';

import 'user.dart';

class Session {
  const Session({required this.accessToken, required this.user});

  final String accessToken;
  final User user;

  factory Session.fromJson(Json json) => Session(
    accessToken: stringOf(json, 'accessToken'),
    user: User.fromJson(objectOf(json, 'user')),
  );

  @override
  String toString() => 'Session(${user.email})';
}
