import 'package:app/utils/json.dart';

import 'user.dart';

class Session {
  const Session({required this.accessToken, required this.user});

  final String accessToken;
  final User user;

  factory Session.fromJson(JsonType json) {
    final sj = Json(json);
    return Session(
      accessToken: sj.stringOf('accessToken'),
      user: User.fromJson(sj.objectOf('user')),
    );
  }

  @override
  String toString() => 'Session(${user.email})';
}
