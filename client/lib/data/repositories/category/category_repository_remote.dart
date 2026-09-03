import 'package:app/data/services/api/category_api.dart';
import 'package:app/domain/models/request_category.dart';
import 'package:app/utils/result.dart';

import 'category_repository.dart';

class RemoteCategoryRepository implements CategoryRepository {
  RemoteCategoryRepository({required this._categories});

  final CategoryApi _categories;

  List<RequestCategory>? _cache;

  @override
  Future<Result<List<RequestCategory>>> getCategories({
    bool refresh = false,
  }) async {
    final cached = _cache;
    if (!refresh && cached != null) return Result.ok(cached);

    final result = await _categories.list();
    if (result is Ok<List<RequestCategory>>) _cache = result.value;
    return result;
  }
}
