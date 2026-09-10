import 'package:app/domain/models/comment.dart';
import 'package:app/utils/result.dart';
import 'package:app/utils/api.dart';

class CommentApi {
  final RestClient _client;

  const CommentApi(this._client);

  Future<Result<Comment>> create(int requestId, {required String content}) {
    return _client.post(
      '/request/$requestId/comment',
      asObject(Comment.fromJson),
      body: {'content': content},
    );
  }
}
