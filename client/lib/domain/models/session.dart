import 'package:app/utils/json.dart';

import 'user.dart';

/// What a successful login returns: proof of identity, and the identity itself.
///
/// The token is what every later request carries; the user comes along so the
/// app can render a name and a role without a second round trip.
class Session {
  const Session({required this.accessToken, required this.user});

  final String accessToken;
  final User user;

  factory Session.fromJson(Json json) => Session(
    accessToken: stringOf(json, 'accessToken'),
    user: User.fromJson(objectOf(json, 'user')),
  );

  /// Never print the token — this ends up in logs and error reports.
  @override
  String toString() => 'Session(${user.email})';
}
