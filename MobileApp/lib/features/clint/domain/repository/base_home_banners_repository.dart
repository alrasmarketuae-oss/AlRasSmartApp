import 'package:alrasmarket/core/error/failure.dart';
import 'package:alrasmarket/features/clint/domain/entities/banner_adds.dart';
import 'package:dartz/dartz.dart';

abstract class BaseHomeBannersRepository {
  Future<Either<Failure, List<BannerAdds>>> getHomeBanners();
}
