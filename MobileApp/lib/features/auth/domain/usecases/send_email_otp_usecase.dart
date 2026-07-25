import 'package:alrasmarket/core/usecase/base_usecase.dart';
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failure.dart';
import '../repository/base_auth_repository.dart';

class SendEmailOtpUseCase extends BaseUseCase<void, SendEmailOtpParameters> {
  final BaseAuthRepository baseAuthRepository;

  SendEmailOtpUseCase(this.baseAuthRepository);

  @override
  Future<Either<Failure, void>> call(SendEmailOtpParameters parameters) async {
    return baseAuthRepository.sendEmailOtp(parameters);
  }
}

class SendEmailOtpParameters extends Equatable {
  final String email;

  const SendEmailOtpParameters({required this.email});

  @override
  List<Object?> get props => [email];
}
