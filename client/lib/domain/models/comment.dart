import 'package:json_annotation/json_annotation.dart';
import 'package:app/utils/json.dart';

import 'user.dart';
part 'generated/comment.g.dart';

@JsonSerializable(checked: true, createToJson: false)
class Comment {
  final int id;
  final int requestId;
  final String content;

  @JsonKey(name: 'user')
  final User author;

  @LocalDateTime()
  final DateTime createdAt;
  @LocalDateTimeOrNull()
  final DateTime? updatedAt;

  const Comment({
    required this.id,
    required this.requestId,
    required this.content,
    required this.author,
    required this.createdAt,
    this.updatedAt,
  });

  factory Comment.fromJson(JsonType json) => _$CommentFromJson(json);
}
