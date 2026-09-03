import 'package:app/domain/models/request_category.dart';
import 'package:app/utils/result.dart';

import 'rest_client.dart';

class CategoryApi {
  const CategoryApi(this._client);

  final RestClient _client;

  Future<Result<List<RequestCategory>>> list() {
    return _client.get('/category', asList(RequestCategory.fromJson));
  }
}
