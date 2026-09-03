import 'package:app/utils/json.dart';

class RequestCategory {
  const RequestCategory({
    required this.id,
    required this.name,
    this.description,
    this.createdAt,
  });

  final int id;
  final String name;

  final String? description;
  final DateTime? createdAt;

  factory RequestCategory.fromJson(Json json) => RequestCategory(
    id: intOf(json, 'id'),
    name: stringOf(json, 'name'),
    description: stringOrNull(json, 'description'),
    createdAt: dateOrNull(json, 'createdAt'),
  );

  @override
  bool operator ==(Object other) =>
      other is RequestCategory && other.id == id && other.name == name;

  @override
  int get hashCode => Object.hash(id, name);

  @override
  String toString() => 'RequestCategory($id, $name)';
}
