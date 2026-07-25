import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/usecase/base_usecase.dart';
import '../entities/user.dart';
import '../repository/base_auth_repository.dart';

class RegisterCompanyUseCase
    extends BaseUseCase<User, RegisterCompanyParameters> {
  final BaseAuthRepository baseAuthRepository;

  RegisterCompanyUseCase(this.baseAuthRepository);

  @override
  Future<Either<Failure, User>> call(
    RegisterCompanyParameters parameters,
  ) async {
    return await baseAuthRepository.registerCompany(parameters);
  }
}

class RegisterCompanyParameters extends Equatable {
  final String fullName;
  final String companyName;
  final String email;
  final String password;
  final String phoneNumber;
  final String landNumber;
  final String licenseNumber;
  final String fcmToken;
  final String licencePath;
  final List<String> companyImagePaths;
  final String? birthDate;
  final String commercialRegister;
  final String taxNumber;
  final String website;
  final bool isCustomer;
  final String preferredLanguage;
  const RegisterCompanyParameters({
    required this.fullName,
    required this.companyName,
    required this.email,
    required this.password,
    required this.phoneNumber,
    this.landNumber = '',
    this.licenseNumber = '',
    this.fcmToken = '',
    this.licencePath = '',
    this.companyImagePaths = const [],
    this.birthDate,
    this.commercialRegister = '',
    this.taxNumber = '',
    this.website = '',
    this.isCustomer = false,
    this.preferredLanguage = 'en',
  });

  @override
  List<Object?> get props => [
    fullName,
    companyName,
    email,
    password,
    phoneNumber,
    landNumber,
    licenseNumber,
    fcmToken,
    licencePath,
    companyImagePaths,
    birthDate,
    commercialRegister,
    taxNumber,
    website,
    isCustomer,
    preferredLanguage,
  ];
}
