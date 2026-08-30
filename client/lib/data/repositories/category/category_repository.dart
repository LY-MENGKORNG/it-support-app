import 'package:app/domain/models/request_category.dart';
import 'package:app/utils/result.dart';

/// The source of truth for request categories.
abstract class CategoryRepository {
  Future<Result<List<RequestCategory>>> getCategories({bool refresh = false});
}
