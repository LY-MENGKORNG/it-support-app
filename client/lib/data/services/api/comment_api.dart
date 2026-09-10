import 'package:app/domain/models/comment.dart';
import 'package:app/utils/result.dart';
import 'package:app/utils/api.dart';

class CommentApi {
  const CommentApi(this._client);

  final RestClient _client;

  Future<Result<Comment>> create(int requestId, {required String content}) {
    return _client.post(
      '/request/$requestId/comment',
      asObject(Comment.fromJson),
      body: {'content': content},
    );
  }
}
