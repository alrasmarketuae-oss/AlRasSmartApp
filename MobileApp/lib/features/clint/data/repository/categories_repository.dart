import 'package:alrasmarket/core/error/failure.dart';
import 'package:alrasmarket/features/clint/data/datasource/categories_remote_data_source.dart';
import 'package:alrasmarket/features/clint/data/models/category_model.dart';
import 'package:alrasmarket/features/clint/domain/repository/base_categories_repository.dart';
import 'package:dartz/dartz.dart';

class CategoriesRepository implements BaseCategoriesRepository {
  CategoriesRepository({required BaseCategoriesRemoteDataSource remote})
      : _remote = remote;

  final BaseCategoriesRemoteDataSource _remote;

  @override
  Future<Either<Failure, List<CategoryModel>>> getCategories({
    bool forceRefresh = false,
  }) async {
    final result = await _remote.fetchCategories(forceRefresh: forceRefresh);
    return result.fold(Left.new, (model) => Right(model.items));
  }
}
