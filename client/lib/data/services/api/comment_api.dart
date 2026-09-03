import 'package:app/domain/models/comment.dart';
import 'package:app/utils/result.dart';

import 'rest_client.dart';

class CommentApi {
  const CommentApi(this._client);

  final RestClient _client;

  Future<Result<Comment>> create(int requestId, {required String content}) =>
      _client.post(
        '/request/$requestId/comment',
        asObject(Comment.fromJson),
        body: {'content': content},
      );
}
