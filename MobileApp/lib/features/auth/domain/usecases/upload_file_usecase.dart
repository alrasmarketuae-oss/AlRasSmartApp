import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:alrasmarket/core/error/failure.dart';
import 'package:alrasmarket/core/usecase/base_usecase.dart';
import '../repository/base_auth_repository.dart';

class UploadCommercialLicenseUseCase
    extends BaseUseCase<String, UploadFileParameters> {
  final BaseAuthRepository baseAuthRepository;

  UploadCommercialLicenseUseCase(this.baseAuthRepository);

  @override
  Future<Either<Failure, String>> call(UploadFileParameters parameters) async {
    return await baseAuthRepository.uploadCompanyLicence(parameters.filePath);
  }
}

class UploadSellerIdentityUseCase
    extends BaseUseCase<String, UploadFileParameters> {
  final BaseAuthRepository baseAuthRepository;

  UploadSellerIdentityUseCase(this.baseAuthRepository);

  @override
  Future<Either<Failure, String>> call(UploadFileParameters parameters) async {
    return await baseAuthRepository.uploadCompanyImages(parameters.filePath);
  }
}

class UploadFileParameters extends Equatable {
  final String filePath;

  const UploadFileParameters({required this.filePath});

  @override
  List<Object?> get props => [filePath];
}
