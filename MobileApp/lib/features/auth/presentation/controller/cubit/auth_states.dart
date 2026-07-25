import 'package:equatable/equatable.dart';
import '../../../data/models/login_response_model.dart';
import '../../../domain/entities/user.dart';

abstract class AuthStates extends Equatable {
  const AuthStates();

  @override
  List<Object?> get props => [];
}

class AuthInitialState extends AuthStates {}

// Login States
class LoginLoadingState extends AuthStates {}

class LoginSuccessState extends AuthStates {
  final LoginResponseModel loginResponse;

  const LoginSuccessState(this.loginResponse);

  @override
  List<Object?> get props => [loginResponse];
}

class LoginErrorState extends AuthStates {
  final String message;

  const LoginErrorState(this.message);

  @override
  List<Object?> get props => [message];
}

// Register Client States
class RegisterClientLoadingState extends AuthStates {}

class RegisterClientSuccessState extends AuthStates {
  final LoginResponseModel loginResponse;

  const RegisterClientSuccessState(this.loginResponse);

  @override
  List<Object?> get props => [loginResponse];
}

class RegisterClientErrorState extends AuthStates {
  final String message;

  const RegisterClientErrorState(this.message);

  @override
  List<Object?> get props => [message];
}

// Register Seller States
class RegisterSellerLoadingState extends AuthStates {}

class RegisterSellerSuccessState extends AuthStates {
  final User user;

  const RegisterSellerSuccessState(this.user);

  @override
  List<Object?> get props => [user];
}

class RegisterSellerErrorState extends AuthStates {
  final String message;

  const RegisterSellerErrorState(this.message);

  @override
  List<Object?> get props => [message];
}

class VerifyOtpLoadingState extends AuthStates {}

class VerifyOtpSuccessState extends AuthStates {
  final LoginResponseModel loginResponse;

  const VerifyOtpSuccessState(this.loginResponse);

  bool get isPendingAdminApproval => loginResponse.isPendingAdminApproval;

  bool get isCompanyAccount => loginResponse.isCompanyAccount == true;

  @override
  List<Object?> get props => [loginResponse];
}

class VerifyOtpErrorState extends AuthStates {
  final String message;

  const VerifyOtpErrorState(this.message);

  @override
  List<Object?> get props => [message];
}

class AccountApprovalApprovedState extends AuthStates {
  const AccountApprovalApprovedState();
}

class ResendOtpLoadingState extends AuthStates {}

class ResendOtpSuccessState extends AuthStates {}

class ResendOtpErrorState extends AuthStates {
  final String message;

  const ResendOtpErrorState(this.message);

  @override
  List<Object?> get props => [message];
}

// Upload File States
class UploadFileLoadingState extends AuthStates {
  final String uploadType; // 'commercialLicense' or 'sellerIdentity'

  const UploadFileLoadingState(this.uploadType);

  @override
  List<Object?> get props => [uploadType];
}

class UploadFileSuccessState extends AuthStates {
  final String fileUrl;
  final String uploadType;

  const UploadFileSuccessState(this.fileUrl, this.uploadType);

  @override
  List<Object?> get props => [fileUrl, uploadType];
}

class UploadFileErrorState extends AuthStates {
  final String message;
  final String uploadType;

  const UploadFileErrorState(this.message, this.uploadType);

  @override
  List<Object?> get props => [message, uploadType];
  
}

class ForgetPasswordLoadingState extends AuthStates {}

class ForgetPasswordSuccessState extends AuthStates {
  final String message;
  ForgetPasswordSuccessState(this.message);
}

class ForgetPasswordErrorState extends AuthStates {
  final String message;
  ForgetPasswordErrorState(this.message);
}

class ResetPasswordLoadingState extends AuthStates {}

class ResetPasswordSuccessState extends AuthStates {
  final String message;
  ResetPasswordSuccessState(this.message);
}

class ResetPasswordErrorState extends AuthStates {
  final String message;
  ResetPasswordErrorState(this.message);
}

// Locale States
class ChangeLocaleState extends AuthStates {
  final String languageCode;
  const ChangeLocaleState(this.languageCode);

  @override
  List<Object?> get props => [languageCode];
}

// Delete Account States
class DeleteAccountLoadingState extends AuthStates {}

class DeleteAccountSuccessState extends AuthStates {
  final String message;
  DeleteAccountSuccessState(this.message);
}

class DeleteAccountErrorState extends AuthStates {
  final String message;
  DeleteAccountErrorState(this.message);
}

class ChangePasswordLoadingState extends AuthStates {}

class ChangePasswordSuccessState extends AuthStates {
  final String message;
  ChangePasswordSuccessState(this.message);
}

class ChangePasswordErrorState extends AuthStates {
  final String message;
  ChangePasswordErrorState(this.message);
}