import 'package:json_annotation/json_annotation.dart';
import 'package:app/utils/json.dart';

import 'user_role.dart';

part 'generated/user.g.dart';

@JsonSerializable(checked: true, createToJson: false)
class User {
  final int id;
  final String name;
  final String email;

  @UserRoleConverter()
  final UserRole role;

  @JsonKey(defaultValue: true)
  final bool isActive;

  @LocalDateTimeOrNull()
  final DateTime? createdAt;

  @LocalDateTimeOrNull()
  final DateTime? updatedAt;

  const User({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
  });

  factory User.fromJson(JsonType json) => _$UserFromJson(json);

  String get initials {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
    if (parts.isEmpty) return '?';
    return parts.take(2).map((p) => p[0].toUpperCase()).join();
  }

  @override
  bool operator ==(Object other) {
    return other is User &&
        other.id == id &&
        other.name == name &&
        other.email == email &&
        other.role == role &&
        other.isActive == isActive;
  }

  @override
  int get hashCode => Object.hash(id, name, email, role, isActive);

  @override
  String toString() => 'User($id, $name)';
}
