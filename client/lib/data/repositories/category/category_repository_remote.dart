import 'package:app/data/services/api/api_client.dart';
import 'package:app/domain/models/request_category.dart';
import 'package:app/utils/result.dart';

import 'category_repository.dart';

class CategoryRepositoryRemote implements CategoryRepository {
  CategoryRepositoryRemote({required this._apiClient});

  final ApiClient _apiClient;

  List<RequestCategory>? _cache;

  /// Categories fill a dropdown on the create form and the filter sheet, and
  /// they almost never change — one fetch per app run is plenty.
  @override
  Future<Result<List<RequestCategory>>> getCategories({
    bool refresh = false,
  }) async {
    final cached = _cache;
    if (!refresh && cached != null) return Result.ok(cached);

    final result = await _apiClient.getCategories();
    if (result is Ok<List<RequestCategory>>) _cache = result.value;
    return result;
  }
}
