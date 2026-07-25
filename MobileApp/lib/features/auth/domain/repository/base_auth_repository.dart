import 'package:alrasmarket/features/auth/data/models/account_approval_status_model.dart';
import 'package:alrasmarket/features/auth/data/models/login_response_model.dart';
import 'package:dartz/dartz.dart';
import 'package:alrasmarket/core/error/failure.dart';
import '../entities/user.dart';
import '../usecases/login_usecase.dart';
import '../usecases/register_person_usecase.dart';
import '../usecases/register_company_usecase.dart';
import '../usecases/send_email_otp_usecase.dart';
import '../usecases/verify_email_otp_usecase.dart';

abstract class BaseAuthRepository {
  Future<Either<Failure, LoginResponseModel>> login(LoginParameters parameters);
  Future<Either<Failure, LoginResponseModel>> registerPerson(
    RegisterPersonParameters parameters,
  );
  Future<Either<Failure, User>> registerCompany(
    RegisterCompanyParameters parameters,
  );
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
  });
  Future<Either<Failure, LoginResponseModel>> verifyEmailOtp(
    VerifyEmailOtpParameters parameters,
  );
  Future<Either<Failure, AccountApprovalStatusModel>> checkAccountApprovalStatus({
    required String email,
  });
  Future<Either<Failure, void>> sendEmailOtp(SendEmailOtpParameters parameters);
  Future<Either<Failure, String>> uploadCompanyLicence(String filePath);
  Future<Either<Failure, String>> uploadCompanyImages(String filePath);
  Future<Either<Failure, String>> forgotPasswordRequest({required String email});
  Future<Either<Failure, String>> forgotPasswordReset({
    required String email,
    required String code,
    required String newPassword,
  });
  Future<Either<Failure, String>> changePassword({
    required String currentPassword,
    required String newPassword,
  });
  Future<Either<Failure, String>> deleteAccount({required String password});
}
