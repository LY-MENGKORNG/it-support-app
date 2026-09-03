import 'package:app/domain/models/request_category.dart';
import 'package:app/utils/result.dart';

abstract interface class CategoryRepository {
  Future<Result<List<RequestCategory>>> getCategories({bool refresh = false});
}
