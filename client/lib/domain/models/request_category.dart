import 'package:app/utils/json.dart';

/// A bucket a request belongs to — Network, Hardware, Software, and so on.
class RequestCategory {
  const RequestCategory({
    required this.id,
    required this.name,
    this.description,
    this.createdAt,
  });

  final int id;
  final String name;

  /// Absent when a category arrives embedded in a request list row, which
  /// carries only `{ id, name }`.
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
