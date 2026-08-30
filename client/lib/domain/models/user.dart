import 'package:app/utils/json.dart';

import 'user_role.dart';

/// Someone who can raise or handle requests.
///
/// Immutable, like every domain model here: a change means a new instance, so
/// data can only be mutated in the data layer where it belongs.
class User {
  const User({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
  });

  final int id;
  final String name;
  final String email;
  final UserRole role;

  /// The request list embeds a *summary* of each user (id, name, email, role)
  /// while `/user` returns the full row. These three are optional so one model
  /// covers both shapes rather than forcing a near-duplicate class.
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory User.fromJson(Json json) => User(
    id: intOf(json, 'id'),
    name: stringOf(json, 'name'),
    email: stringOf(json, 'email'),
    role: UserRole.fromWire(stringOf(json, 'role')),
    isActive: boolOr(json, 'isActive', fallback: true),
    createdAt: dateOrNull(json, 'createdAt'),
    updatedAt: dateOrNull(json, 'updatedAt'),
  );

  /// First letter of each of the first two words — for avatars.
  String get initials {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
    if (parts.isEmpty) return '?';
    return parts.take(2).map((p) => p[0].toUpperCase()).join();
  }

  @override
  bool operator ==(Object other) =>
      other is User &&
      other.id == id &&
      other.name == name &&
      other.email == email &&
      other.role == role &&
      other.isActive == isActive;

  @override
  int get hashCode => Object.hash(id, name, email, role, isActive);

  @override
  String toString() => 'User($id, $name)';
}
