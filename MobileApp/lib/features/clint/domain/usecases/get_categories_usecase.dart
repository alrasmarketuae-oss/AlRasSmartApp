import 'package:alrasmarket/core/error/failure.dart';
import 'package:alrasmarket/core/usecase/base_usecase.dart';
import 'package:alrasmarket/features/clint/data/models/category_model.dart';
import 'package:alrasmarket/features/clint/domain/repository/base_categories_repository.dart';
import 'package:dartz/dartz.dart';

class GetCategoriesUseCase
    extends BaseUseCase<List<CategoryModel>, GetCategoriesParams> {
  GetCategoriesUseCase(this._repository);

  final BaseCategoriesRepository _repository;

  @override
  Future<Either<Failure, List<CategoryModel>>> call(GetCategoriesParams params) {
    return _repository.getCategories(forceRefresh: params.forceRefresh);
  }
}

class GetCategoriesParams {
  const GetCategoriesParams({this.forceRefresh = false});

  final bool forceRefresh;
}
