import 'dart:convert';

import 'package:app/src/core/constant/role.dart';

class UserModel {
  final int id;
  final String name;
  final String email;
  final UserRole role;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserModel({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.email,
    required this.role,
    required this.isActive,
    required this.updatedAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as int,
      name: json['name'] as String,
      email: json['email'] as String,
      role: UserRole.values.byName(json['role'] as String),
      isActive: json['isActive'] as bool,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  static List<UserModel> parseMany(String body) {
    final decoded = jsonDecode(body) as List<Object?>;

    final parsed = decoded.cast<Map<String, Object?>>();

    return parsed.map<UserModel>(UserModel.fromJson).toList();
  }

  static UserModel parseOne(String body) {
    final decoded = jsonDecode(body) as Object?;

    final parsed = decoded as UserModel;
    return parsed;
  }
}
