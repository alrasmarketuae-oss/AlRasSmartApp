import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/error/failure.dart';
import 'package:alrasmarket/core/usecase/base_usecase.dart';
import '../../data/models/login_response_model.dart';
import '../repository/base_auth_repository.dart';

class LoginUseCase extends BaseUseCase<LoginResponseModel, LoginParameters> {
  final BaseAuthRepository baseAuthRepository;

  LoginUseCase(this.baseAuthRepository);

  @override
  Future<Either<Failure, LoginResponseModel>> call(
    LoginParameters parameters,
  ) async {
    return await baseAuthRepository.login(parameters);
  }
}

class LoginParameters extends Equatable {
  final String email;
  final String password;

  /// e.g. "local" (email/password), "google", "apple"
  final String loginProviderName;

  /// Social id token (Google/Apple). Empty string if not used.
  final String token;

  /// Firebase Cloud Messaging token (push notifications).
  final String fcmToken;

  /// App language sent to backend for localized notifications (en/ar).
  final String preferredLanguage;

  /// Optional display name (Apple given+family name on first authorization).
  final String fullName;

  const LoginParameters({
    required this.email,
    required this.password,
    this.loginProviderName = 'local',
    this.token = '',
    this.fcmToken = '',
    this.preferredLanguage = 'en',
    this.fullName = '',
  });

  Map<String, dynamic> toJson() => {
    'loginProviderName': loginProviderName,
    'email': email,
    'password': password,
    'token': token,
    'fcmToken': fcmToken,
    'preferredLanguage': preferredLanguage,
    if (fullName.isNotEmpty) 'fullName': fullName,
  };

  @override
  List<Object?> get props => [
    email,
    password,
    loginProviderName,
    token,
    fcmToken,
    preferredLanguage,
    fullName,
  ];
}
