import 'package:json_annotation/json_annotation.dart';

import 'package:app/utils/json.dart';

part 'generated/request_category.g.dart';

@JsonSerializable(checked: true, createToJson: false)
class RequestCategory {
  const RequestCategory({
    required this.id,
    required this.name,
    this.description,
    this.createdAt,
  });

  factory RequestCategory.fromJson(JsonType json) =>
      _$RequestCategoryFromJson(json);

  final int id;
  final String name;

  final String? description;

  @LocalDateTimeOrNull()
  final DateTime? createdAt;

  @override
  bool operator ==(Object other) =>
      other is RequestCategory && other.id == id && other.name == name;

  @override
  int get hashCode => Object.hash(id, name);

  @override
  String toString() => 'RequestCategory($id, $name)';
}
