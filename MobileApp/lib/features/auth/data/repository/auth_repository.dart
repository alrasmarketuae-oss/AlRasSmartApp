import 'package:dartz/dartz.dart';
import '../../../../core/error/failure.dart';
import '../datasource/auth_remote_data_source.dart';
import '../models/account_approval_status_model.dart';
import '../models/login_response_model.dart';
import '../../domain/entities/user.dart';
import '../../domain/repository/base_auth_repository.dart';
import '../../domain/usecases/login_usecase.dart';
import '../../domain/usecases/register_person_usecase.dart';
import '../../domain/usecases/register_company_usecase.dart';
import '../../domain/usecases/send_email_otp_usecase.dart';
import '../../domain/usecases/verify_email_otp_usecase.dart';

class AuthRepository implements BaseAuthRepository {
  final BaseAuthRemoteDataSource baseAuthRemoteDataSource;

  AuthRepository({required this.baseAuthRemoteDataSource});

  @override
  Future<Either<Failure, LoginResponseModel>> login(
    LoginParameters parameters,
  ) async {
    return await baseAuthRemoteDataSource.login(parameters);
  }

  @override
  Future<Either<Failure, LoginResponseModel>> registerPerson(
    RegisterPersonParameters parameters,
  ) async {
    return await baseAuthRemoteDataSource.registerPerson(parameters);
  }

  @override
  Future<Either<Failure, User>> registerCompany(
    RegisterCompanyParameters parameters,
  ) async {
    return await baseAuthRemoteDataSource.registerCompany(parameters);
  }

  @override
  Future<Either<Failure, User>> registerShippingCompany({
    required String companyName,
    required String email,
    required String password,
    required String phoneNumber,
    required String commercialRegister,
    required String taxNumber,
    String website = '',
    required String fcmToken,
    required String preferredLanguage,
  }) {
    return baseAuthRemoteDataSource.registerShippingCompany(
      companyName: companyName,
      email: email,
      password: password,
      phoneNumber: phoneNumber,
      commercialRegister: commercialRegister,
      taxNumber: taxNumber,
      website: website,
      fcmToken: fcmToken,
      preferredLanguage: preferredLanguage,
    );
  }

  @override
  Future<Either<Failure, LoginResponseModel>> verifyEmailOtp(
    VerifyEmailOtpParameters parameters,
  ) async {
    return await baseAuthRemoteDataSource.verifyEmailOtp(parameters);
  }

  @override
  Future<Either<Failure, AccountApprovalStatusModel>> checkAccountApprovalStatus({
    required String email,
  }) async {
    return baseAuthRemoteDataSource.checkAccountApprovalStatus(email: email);
  }

  @override
  Future<Either<Failure, void>> sendEmailOtp(SendEmailOtpParameters parameters) async {
    return await baseAuthRemoteDataSource.sendEmailOtp(parameters);
  }

  @override
  Future<Either<Failure, String>> uploadCompanyLicence(String filePath) async {
    return await baseAuthRemoteDataSource.uploadCompanyLicence(filePath);
  }

  @override
  Future<Either<Failure, String>> uploadCompanyImages(String filePath) async {
    return await baseAuthRemoteDataSource.uploadCompanyImages(filePath);
  }

  @override
  Future<Either<Failure, String>> forgotPasswordRequest({
    required String email,
  }) async {
    return baseAuthRemoteDataSource.forgotPasswordRequest(email: email);
  }

  @override
  Future<Either<Failure, String>> forgotPasswordReset({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    return baseAuthRemoteDataSource.forgotPasswordReset(
      email: email,
      code: code,
      newPassword: newPassword,
    );
  }

  @override
  Future<Either<Failure, String>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    return baseAuthRemoteDataSource.changePassword(
      currentPassword: currentPassword,
      newPassword: newPassword,
    );
  }

  @override
  Future<Either<Failure, String>> deleteAccount({required String password}) async {
    return baseAuthRemoteDataSource.deleteAccount(password: password);
  }
}
