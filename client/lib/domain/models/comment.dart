import 'package:app/utils/json.dart';

import 'user.dart';

/// One message in a request's discussion thread.
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

  factory Comment.fromJson(Json json) => Comment(
    id: intOf(json, 'id'),
    requestId: intOf(json, 'requestId'),
    content: stringOf(json, 'content'),
    // The API calls this `user`; `author` reads better at the call site.
    author: User.fromJson(objectOf(json, 'user')),
    createdAt: dateOf(json, 'createdAt'),
    updatedAt: dateOrNull(json, 'updatedAt'),
  );
}
