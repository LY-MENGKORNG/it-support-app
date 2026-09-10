import 'package:json_annotation/json_annotation.dart';

import 'package:app/domain/models/comment.dart';
import 'package:app/domain/models/request.dart';
import 'package:app/domain/models/request_history.dart';
import 'package:app/utils/json.dart';

part 'generated/request_detail.g.dart';

@JsonSerializable(checked: true, createToJson: false)
class RequestDetail {
  const RequestDetail({
    required this.request,
    required this.comments,
    required this.history,
  });

  factory RequestDetail.fromJson(JsonType json) =>
      _$RequestDetailFromJson(json);

  /// The detail payload is flat: the request's own fields sit alongside
  /// `comments` and `history` rather than nested under a `request` key, so
  /// this field is read from the whole payload instead of from one key of it.
  @JsonKey(readValue: _wholePayload)
  final Request request;

  @JsonKey(defaultValue: <Comment>[])
  final List<Comment> comments;
  @JsonKey(defaultValue: <RequestHistory>[])
  final List<RequestHistory> history;

  static Object? _wholePayload(Map<dynamic, dynamic> json, String key) => json;

  int get id => request.id;

  RequestDetail copyWith({
    Request? request,
    List<Comment>? comments,
    List<RequestHistory>? history,
  }) => RequestDetail(
    request: request ?? this.request,
    comments: comments ?? this.comments,
    history: history ?? this.history,
  );
}
