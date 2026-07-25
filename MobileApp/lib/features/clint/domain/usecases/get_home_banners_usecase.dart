import 'package:alrasmarket/core/error/failure.dart';
import 'package:alrasmarket/core/usecase/base_usecase.dart';
import 'package:alrasmarket/features/clint/domain/entities/banner_adds.dart';
import 'package:alrasmarket/features/clint/domain/repository/base_home_banners_repository.dart';
import 'package:dartz/dartz.dart';

class GetHomeBannersUseCase
    extends BaseUseCase<List<BannerAdds>, NoParams> {
  final BaseHomeBannersRepository _repository;

  GetHomeBannersUseCase(this._repository);

  @override
  Future<Either<Failure, List<BannerAdds>>> call(NoParams params) {
    return _repository.getHomeBanners();
  }
}
