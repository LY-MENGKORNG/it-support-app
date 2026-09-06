import 'package:app/utils/json.dart';

import 'user.dart';

class Comment {
  const Comment({
    required this.id,
    required this.requestId,
    required this.content,
    required this.author,
    required this.createdAt,
    this.updatedAt,
  });

  final int id;
  final int requestId;
  final String content;
  final User author;
  final DateTime createdAt;
  final DateTime? updatedAt;

  factory Comment.fromJson(JsonType json) {
    final cj = Json(json);

    return Comment(
      id: cj.intOf('id'),
      requestId: cj.intOf('requestId'),
      content: cj.stringOf('content'),
      author: User.fromJson(cj.objectOf('user')),
      createdAt: cj.dateOf('createdAt'),
      updatedAt: cj.dateOrNull('updatedAt'),
    );
  }
}
