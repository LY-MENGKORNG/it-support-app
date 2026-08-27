import 'dart:convert';

import 'package:app/src/core/constant/request.dart';

class RequestModel {
  final int id;
  final String title;
  final String description;
  final DateTime createdAt;
  final int categoryId;
  final Priority priority;
  final RequestStatus status;
  final DateTime updatedAt;
  final int requesterId;
  final int? assigneeId;
  final DateTime? resolvedAt;
  final DateTime? closedAt;

  const RequestModel({
    required this.id,
    required this.title,
    required this.description,
    required this.createdAt,
    required this.categoryId,
    required this.priority,
    required this.status,
    required this.updatedAt,
    required this.requesterId,
    this.assigneeId,
    this.resolvedAt,
    this.closedAt,
  });

  factory RequestModel.fromJson(Map<String, dynamic> json) {
    return RequestModel(
      id: json['id'] as int,
      title: json['title'] as String,
      description: json['description'] as String,
      categoryId: json['categoryId'] as int,
      priority: Priority.values.byName(json['priority'] as String),
      status: RequestStatus.values.byName(json['status'] as String),
      requesterId: json['requesterId'] as int,
      assigneeId: json['assigneeId'] as int?,
      resolvedAt: json['resolvedAt'] != null
          ? DateTime.parse(json['resolvedAt'] as String)
          : null,
      closedAt: json['closedAt']
          ? DateTime.parse(json['closedAt'] as String)
          : null,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  static List<RequestModel> parseMany(String body) {
    final decoded = jsonDecode(body) as List<Object?>;
    final parsed = decoded.cast<Map<String, Object?>>();
    return parsed.map<RequestModel>(RequestModel.fromJson).toList();
  }

  static RequestModel? parseOne(String body) {
    return (jsonDecode(body)) as RequestModel?;
  }
}
