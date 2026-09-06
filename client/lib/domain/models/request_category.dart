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

  factory RequestCategory.fromJson(JsonType json) {
    final rcj = Json(json);

    return RequestCategory(
      id: rcj.intOf('id'),
      name: rcj.stringOf('name'),
      description: rcj.stringOrNull('description'),
      createdAt: rcj.dateOrNull('createdAt'),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is RequestCategory && other.id == id && other.name == name;

  @override
  int get hashCode => Object.hash(id, name);

  @override
  String toString() => 'RequestCategory($id, $name)';
}
