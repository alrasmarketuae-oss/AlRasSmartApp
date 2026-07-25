import 'package:alrasmarket/core/error/failure.dart';
import 'package:alrasmarket/features/clint/data/datasource/home_banners_remote_data_source.dart';
import 'package:alrasmarket/features/clint/domain/entities/banner_adds.dart';
import 'package:alrasmarket/features/clint/domain/repository/base_home_banners_repository.dart';
import 'package:dartz/dartz.dart';

class HomeBannersRepository implements BaseHomeBannersRepository {
  HomeBannersRepository({required BaseHomeBannersRemoteDataSource remote})
      : _remote = remote;

  final BaseHomeBannersRemoteDataSource _remote;

  @override
  Future<Either<Failure, List<BannerAdds>>> getHomeBanners() async {
    final result = await _remote.fetchHomeBanners();
    return result.fold(Left.new, (model) => Right(model.toBannerAdds()));
  }
}
