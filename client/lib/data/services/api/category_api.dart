import 'package:app/domain/models/request_category.dart';
import 'package:app/utils/result.dart';
import 'package:app/utils/api.dart';

class CategoryApi {
  final RestClient _client;

  const CategoryApi(this._client);

  Future<Result<List<RequestCategory>>> list() {
    return _client.get('/category', asList(RequestCategory.fromJson));
  }
}
