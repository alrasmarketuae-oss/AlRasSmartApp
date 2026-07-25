import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/error/failure.dart';
import 'package:alrasmarket/core/usecase/base_usecase.dart';
import '../../data/models/login_response_model.dart';
import '../repository/base_auth_repository.dart';

class RegisterPersonUseCase
    extends BaseUseCase<LoginResponseModel, RegisterPersonParameters> {
  final BaseAuthRepository baseAuthRepository;

  RegisterPersonUseCase(this.baseAuthRepository);

  @override
  Future<Either<Failure, LoginResponseModel>> call(
    RegisterPersonParameters parameters,
  ) async {
    return await baseAuthRepository.registerPerson(parameters);
  }
}

class RegisterPersonParameters extends Equatable {
  final String fullName;
  final String email;
  final String password;
  final String fcmToken;
  final String phoneNumber;
  final String preferredLanguage;

  const RegisterPersonParameters({
    required this.fullName,
    required this.email,
    required this.password,
    this.fcmToken = '',
    required this.phoneNumber,
    this.preferredLanguage = 'en',
  });

  @override
  List<Object?> get props => [
    fullName,
    email,
    password,
    fcmToken,
    phoneNumber,
    preferredLanguage,
  ];
}
