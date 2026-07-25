import 'package:alrasmarket/core/error/failure.dart';
import 'package:alrasmarket/features/clint/data/models/category_model.dart';
import 'package:dartz/dartz.dart';

abstract class BaseCategoriesRepository {
  Future<Either<Failure, List<CategoryModel>>> getCategories({
    bool forceRefresh = false,
  });
}
