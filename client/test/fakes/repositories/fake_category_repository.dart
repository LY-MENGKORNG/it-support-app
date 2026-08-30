import 'package:app/data/repositories/category/category_repository.dart';
import 'package:app/domain/models/request_category.dart';
import 'package:app/utils/result.dart';

import '../fixtures.dart';

class FakeCategoryRepository implements CategoryRepository {
  FakeCategoryRepository({List<RequestCategory>? categories})
    : _categories = categories ?? const [kCategory];

  final List<RequestCategory> _categories;

  Exception? error;

  @override
  Future<Result<List<RequestCategory>>> getCategories({
    bool refresh = false,
  }) async {
    if (error != null) return Result.error(error!);
    return Result.ok(_categories);
  }
}
