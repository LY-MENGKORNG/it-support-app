import 'dart:convert';

enum UserRole { employee, staff, admin }

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
      role: json['role'] as UserRole,
      isActive: json['isActive'] as bool,
      createdAt: json['createdAt'] as DateTime,
      updatedAt: json['updatedAt'] as DateTime,
    );
  }

  static List<UserModel> parseUsers(String body) {
    final decoded = jsonDecode(body) as List<Object?>;

    final parsed = decoded.cast<Map<String, Object?>>();

    return parsed.map<UserModel>(UserModel.fromJson).toList();
  }
}
