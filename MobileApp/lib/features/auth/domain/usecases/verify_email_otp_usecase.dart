import 'package:alrasmarket/core/usecase/base_usecase.dart';
import 'package:alrasmarket/features/auth/data/models/login_response_model.dart';
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failure.dart';
import '../repository/base_auth_repository.dart';

class VerifyEmailOtpUseCase extends BaseUseCase<LoginResponseModel, VerifyEmailOtpParameters> {
  final BaseAuthRepository baseAuthRepository;

  VerifyEmailOtpUseCase(this.baseAuthRepository);

  @override
  Future<Either<Failure, LoginResponseModel>> call(VerifyEmailOtpParameters parameters) async {
    return baseAuthRepository.verifyEmailOtp(parameters);
  }
}

class VerifyEmailOtpParameters extends Equatable {
  final String email;
  final String otp;

  final String? fcmToken;
  const VerifyEmailOtpParameters({
    required this.email,
    required this.otp,
 
    this.fcmToken,
  });

  @override
  List<Object?> get props => [email, otp, fcmToken];
}
