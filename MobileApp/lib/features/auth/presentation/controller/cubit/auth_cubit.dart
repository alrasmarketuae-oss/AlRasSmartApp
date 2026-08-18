import 'dart:async';
import 'package:alrasmarket/core/serveses/pending_profile_image_uploader.dart';
import 'package:alrasmarket/core/serveses/cached_constants.dart';
import 'package:alrasmarket/core/router/where_to_go.dart';
import 'package:alrasmarket/core/router/app_router.dart';
import 'package:alrasmarket/core/services_locator/services_locator.dart';
import 'package:alrasmarket/features/clint/presentation/controller/cubit/clint_cubit.dart';
import 'package:alrasmarket/features/clint/domain/usecases/address_usecases.dart';
import 'package:alrasmarket/features/clint/presentation/widgets/add_address_dialog.dart';
import 'package:alrasmarket/features/auth/data/pending_registration_address.dart';
import 'package:alrasmarket/features/company/presentation/controller/cubit/company_cubit.dart';
import 'package:alrasmarket/features/person/presentation/controller/cubit/person_cubit.dart';
import 'package:alrasmarket/features/shipping_company/presentation/controller/cubit/shipping_company_cubit.dart';
import 'package:alrasmarket/features/auth/presentation/controller/cubit/auth_states.dart';
import 'package:alrasmarket/core/services/fcm_token_service.dart';
import 'package:alrasmarket/core/services/biometric_auth_service.dart';
import 'package:alrasmarket/core/serveses/auth_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:alrasmarket/core/helper/cach_helper.dart';
import 'package:alrasmarket/core/serveses/user_preferences_service.dart';
import '../../../domain/repository/base_auth_repository.dart';
import '../../../domain/usecases/login_usecase.dart';
import '../../../domain/usecases/register_person_usecase.dart';
import '../../../domain/usecases/register_company_usecase.dart';
import '../../../domain/usecases/send_email_otp_usecase.dart';
import '../../../domain/usecases/upload_file_usecase.dart';
import '../../../domain/usecases/verify_email_otp_usecase.dart';
import '../../../data/models/login_response_model.dart';

/// Google Sign-In: Web client ID from Firebase (google-services.json client_type 3)
const String _kGoogleServerClientId =
    '592516755028-omkgbtoesqbj89g1ds07h6jqu4r7979i.apps.googleusercontent.com';

/// iOS client ID from google-services.json (client_type 2)
const String _kGoogleIosClientId =
    '592516755028-8482cm2q52e83uv9h8t9a2oh6jjtoaab.apps.googleusercontent.com';

class AuthCubit extends Cubit<AuthStates> {
  final LoginUseCase loginUseCase;
  final RegisterPersonUseCase registerClientUseCase;
  final RegisterCompanyUseCase registerSellerUseCase;
  final VerifyEmailOtpUseCase verifyEmailOtpUseCase;
  final SendEmailOtpUseCase sendEmailOtpUseCase;
  final UploadCommercialLicenseUseCase uploadCommercialLicenseUseCase;
  final UploadSellerIdentityUseCase uploadSellerIdentityUseCase;
  final BaseAuthRepository authRepository;

  AuthCubit({
    required this.loginUseCase,
    required this.registerClientUseCase,
    required this.registerSellerUseCase,
    required this.verifyEmailOtpUseCase,
    required this.sendEmailOtpUseCase,
    required this.uploadCommercialLicenseUseCase,
    required this.uploadSellerIdentityUseCase,
    required this.authRepository,
  }) : super(AuthInitialState());

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
    serverClientId: _kGoogleServerClientId,
    clientId: kIsWeb
        ? _kGoogleServerClientId
        : (defaultTargetPlatform == TargetPlatform.iOS
            ? _kGoogleIosClientId
            : null),
  );

  static AuthCubit get(context) => BlocProvider.of(context);

  static String _normalizeLanguageCode(String? code) {
    final value = (code ?? 'en').toLowerCase();
    return value == 'ar' ? 'ar' : 'en';
  }

  static Locale _readInitialLocale() {
    final cached =
        CachHelper.getData('languageCode')?.toString() ??
        CachHelper.getData('locale')?.toString();
    return Locale(_normalizeLanguageCode(cached), '');
  }

  String get _currentLanguageCode => _normalizeLanguageCode(locale.languageCode);

  Future<String> _getFcmToken() async {
    try {
      final token = await FcmTokenService.instance.refreshForAuth().timeout(
        const Duration(seconds: 12),
        onTimeout: () => '',
      );
      debugPrint('getFcmToken token: $token');
      return token;
    } catch (e) {
      debugPrint('getFcmToken failed: $e');
      return '';
    }
  }

  Future<void> _saveLoginData(
    LoginResponseModel loginResponse,
    String emailFallback,
  ) async {
    final personId = loginResponse.personId;
    final authToken = loginResponse.authToken;

    if (authToken != null &&
        authToken.isNotEmpty &&
        personId != null &&
        personId.isNotEmpty) {
      await AuthService.instance.saveAuthData(
        personId: personId,
        authToken: authToken,
        userEmail: loginResponse.email ?? emailFallback,
        fullName: loginResponse.fullName,
        userRole: loginResponse.role,
        userRoleId: loginResponse.roleId ?? '',
        companyWaiting: loginResponse.isPendingAdminApproval,
        approved: loginResponse.isApproved,
        isCustomerAcount: loginResponse.isCustomer,
        verified: loginResponse.isVerified,
        companyAccount: loginResponse.isCompanyAccount,
        shippingCompanyAccount: loginResponse.isShippingCompanyAccount,
        userPhone: loginResponse.phone,
      );
    }
  }

  Future<void> _handleLoginSuccess(
    LoginResponseModel loginResponse,
    String emailFallback, {
    String? loginProviderName,
    String? password,
  }) async {
    final token = loginResponse.authToken;
    if (token == null || token.isEmpty) {
      // Backend must not issue tokens for unverified/unapproved accounts.
      if (loginResponse.isPendingAdminApproval) {
        await AuthService.instance.saveAuthData(
          personId: loginResponse.personId ?? '',
          authToken: '',
          userEmail: loginResponse.email ?? emailFallback,
          fullName: loginResponse.fullName,
          userRole: loginResponse.role,
          userRoleId: '',
          companyWaiting: true,
          approved: false,
          isCustomerAcount: loginResponse.isCustomer,
          verified: true,
          companyAccount: loginResponse.isCompanyAccount,
          shippingCompanyAccount: loginResponse.isShippingCompanyAccount,
          userPhone: loginResponse.phone,
          clearSessionToken: true,
        );
        emit(LoginErrorState(
          'Your company account has not been approved yet. It is pending admin approval.',
        ));
        return;
      }

      if (loginResponse.isVerified != true) {
        emit(LoginErrorState('Please verify your email before logging in.'));
        return;
      }

      emit(const LoginErrorState('Token not found in response'));
      return;
    }

    await _saveLoginData(loginResponse, emailFallback);
    unawaited(BiometricAuthService.instance.refreshSnapshotIfEnabled());

    final isSocialLogin =
        loginProviderName == 'google' || loginProviderName == 'apple';

    if (loginResponse.isVerified != true && !isSocialLogin) {
      final userEmail = loginResponse.email ?? emailFallback;
      if (userEmail.isNotEmpty) {
        try {
          final otpResult = await sendEmailOtpUseCase(
            SendEmailOtpParameters(email: userEmail),
          ).timeout(const Duration(seconds: 20));
          final otpError =
              otpResult.fold((failure) => failure.message, (_) => null);
          if (otpError != null) {
            emit(LoginErrorState(otpError));
            return;
          }
        } on TimeoutException {
          emit(
            LoginErrorState(
              'Could not send verification code. Please try again.',
            ),
          );
          return;
        }
      }
    }

    emit(LoginSuccessState(loginResponse));
    await syncPreferredLanguageWithBackend();
  }

  // Login — same API for email/password ("local") and social ("google", "apple")
  Future<void> login({
    required String email,
    required String password,
    String loginProviderName = 'local',
    String token = '',
    String fullName = '',
  }) async {
    emit(LoginLoadingState());
    final fcmToken = await _getFcmToken();
    debugPrint('login fcmToken: $fcmToken');

    try {
      final result = await loginUseCase(
        LoginParameters(
          email: email,
          password: password,
          loginProviderName: loginProviderName,
          token: token,
          fcmToken: fcmToken,
          preferredLanguage: _currentLanguageCode,
          fullName: fullName,
        ),
      ).timeout(const Duration(seconds: 30));

      await result.fold(
        (failure) async {
          final msg = failure.message;
          if (isPendingApprovalMessage(msg)) {
            await AuthService.instance.saveAuthData(
              personId: AuthService.instance.currentUserID ?? '',
              authToken: '',
              userEmail: email,
              userRoleId: '',
              companyWaiting: true,
              approved: false,
              verified: true,
              companyAccount: true,
              clearSessionToken: true,
            );
          } else if (isVerifyEmailMessage(msg)) {
            await AuthService.instance.saveAuthData(
              personId: AuthService.instance.currentUserID ?? '',
              authToken: '',
              userEmail: email,
              userRoleId: '',
              companyWaiting: false,
              approved: false,
              verified: false,
              clearSessionToken: true,
            );
          }
          emit(LoginErrorState(msg));
        },
        (loginResponse) async => _handleLoginSuccess(
          loginResponse,
          email,
          loginProviderName: loginProviderName,
          password: password,
        ),
      );
    } on TimeoutException {
      emit(
        LoginErrorState(
          'Login timed out. Check your connection and try again.',
        ),
      );
    }
  }

  Future<void> loginWithGoogle() async {
    try {
      emit(LoginLoadingState());

      // Drop any cached Google session first, otherwise the plugin reuses the
      // last account and the chooser never appears.
      try {
        await _googleSignIn.signOut().timeout(
          const Duration(seconds: 10),
          onTimeout: () => null,
        );
      } catch (e) {
        debugPrint('Google signOut before sign-in error: $e');
      }

      final account = await _googleSignIn.signIn().timeout(
        const Duration(seconds: 90),
        onTimeout: () => null,
      );

      if (account == null) {
        emit(AuthInitialState());
        return;
      }

      final auth = await account.authentication.timeout(
        const Duration(seconds: 20),
        onTimeout: () =>
            throw TimeoutException('Google authentication timed out'),
      );

      if (auth.idToken == null || auth.idToken!.isEmpty) {
        debugPrint(
          'Google Sign-In error: Failed to get authentication token. accessToken=${auth.accessToken}',
        );
        emit(LoginErrorState('Failed to get authentication token.'));
        return;
      }

      final fcmToken = await _getFcmToken();
      final result = await loginUseCase(
        LoginParameters(
          email: account.email,
          password: '',
          loginProviderName: 'google',
          token: auth.idToken!,
          fcmToken: fcmToken,
          preferredLanguage: _currentLanguageCode,
        ),
      ).timeout(const Duration(seconds: 30));

      await result.fold(
        (failure) async {
          emit(LoginErrorState(failure.message));
          try {
            await _googleSignIn.signOut();
          } catch (e) {
            debugPrint('Google Sign-In signOut after API error: $e');
          }
        },
        (loginResponse) async => _handleLoginSuccess(
          loginResponse,
          account.email,
          loginProviderName: 'google',
        ),
      );
    } on TimeoutException catch (e) {
      emit(
        LoginErrorState(
          e.message?.isNotEmpty == true
              ? e.message!
              : 'Google Sign-In timed out. Please try again.',
        ),
      );
    } on Exception catch (e, stackTrace) {
      debugPrint('Google Sign-In error: $e');
      debugPrint('Google Sign-In stackTrace: $stackTrace');
      String errorMessage = 'Google Sign-In failed';
      final msg = e.toString();
      if (msg.contains('ApiException: 10')) {
        errorMessage = 'Google Sign-In configuration error.';
      } else if (msg.contains('ApiException: 12500')) {
        errorMessage = 'Google Sign-In identity mismatch error.';
      } else if (msg.contains('network_error') ||
          msg.contains('NetworkError')) {
        errorMessage =
            'Network error during Google Sign-In. Please try again.';
      } else {
        errorMessage = msg.isNotEmpty ? msg : errorMessage;
      }
      emit(LoginErrorState(errorMessage));
    }
  }

  Future<void> loginWithApple() async {
    try {
      emit(LoginLoadingState());
      if (kIsWeb || defaultTargetPlatform != TargetPlatform.iOS) {
        emit(LoginErrorState('Apple Sign-In is only available on iOS devices'));
        return;
      }

      final isAvailable = await SignInWithApple.isAvailable();
      if (!isAvailable) {
        emit(LoginErrorState('Apple Sign-In is not available on this device.'));
        return;
      }

      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      if (credential.identityToken == null ||
          credential.identityToken!.isEmpty) {
        emit(LoginErrorState('Failed to get authentication token.'));
        return;
      }

      final given = credential.givenName?.trim() ?? '';
      final family = credential.familyName?.trim() ?? '';
      final appleFullName = [given, family]
          .where((part) => part.isNotEmpty)
          .join(' ');

      await login(
        email: credential.email ?? '',
        password: '',
        loginProviderName: 'apple',
        token: credential.identityToken!,
        fullName: appleFullName,
      );
    } on SignInWithAppleAuthorizationException catch (e) {
      if (e.code == AuthorizationErrorCode.canceled) {
        emit(AuthInitialState());
        return;
      }
      emit(LoginErrorState('Apple Sign-In failed.'));
    } on Exception catch (e) {
      emit(LoginErrorState('An unexpected error occurred: ${e.toString()}'));
    }
  }

  // Locale
  Locale locale = _readInitialLocale();

  void setLocale() {
    final next = locale.languageCode == 'ar' ? 'en' : 'ar';
    setLocaleTo(next);
  }

  void setLocaleTo(String languageCode) {
    final normalized = _normalizeLanguageCode(languageCode);
    if (locale.languageCode == normalized) return;

    locale = Locale(normalized, '');
    lang = normalized;
    CachHelper.saveData(key: 'locale', value: normalized);
    CachHelper.saveData(key: 'languageCode', value: normalized);
    emit(ChangeLocaleState(normalized));
    unawaited(syncPreferredLanguageWithBackend());
  }

  /// Keeps backend [PreferredLanguage] aligned with the app UI language.
  Future<void> syncPreferredLanguageWithBackend() async {
    final token = AuthService.instance.currentToken;
    if (token == null || token.isEmpty) return;

    await UserPreferencesService.instance.updatePreferredLanguage(
      languageCode: _currentLanguageCode,
      token: token,
    );
  }

  // Register Person
  Future<void> registerPerson({
    required String fullName,
    required String email,
    required String password,
    required String phoneNumber,
  }) async {
    emit(RegisterClientLoadingState());
    final fcmToken = await _getFcmToken();
    print("registerPerson fcmToken: ${fcmToken}");
    final result = await registerClientUseCase(
      RegisterPersonParameters(
        fullName: fullName,
        email: email,
        password: password,
        fcmToken: fcmToken,
        phoneNumber: phoneNumber,
        preferredLanguage: _currentLanguageCode,
      ),
    );

    result.fold((failure) => emit(RegisterClientErrorState(failure.message)), (
      loginResponse,
    ) async {
      emit(RegisterClientSuccessState(loginResponse));
    });
  }

  // Register Company
  Future<void> registerCompany({
    required String fullName,
    required String companyName,
    required String email,
    required String password,
    required String phoneNumber,
    String landNumber = '',
    String licenseNumber = '',
    String licencePath = '',
    List<String> companyImagePaths = const [],
    String? birthDate,
    String commercialRegister = '',
    String taxNumber = '',
    String website = '',
    bool isCustomerCompany = false,
    
  }) async {
    emit(RegisterSellerLoadingState());
    print("registerCompany isCustomerCompany: $isCustomerCompany");
    final fcmToken = await _getFcmToken();
    final result = await registerSellerUseCase(
      RegisterCompanyParameters(
        fullName: fullName,
        companyName: companyName,
        email: email,
        password: password,
        phoneNumber: phoneNumber,
        landNumber: landNumber,
        licenseNumber: licenseNumber,
        fcmToken: fcmToken,
        licencePath: licencePath,
        companyImagePaths: companyImagePaths,
        birthDate: birthDate,
        commercialRegister: commercialRegister,
        taxNumber: taxNumber,
        website: website,
        isCustomer: isCustomerCompany,
        preferredLanguage: _currentLanguageCode,
      ),
    );

    result.fold(
      (failure) => emit(RegisterSellerErrorState(failure.message)),
      (user) => emit(RegisterSellerSuccessState(user)),
    );
  }

  Future<void> registerShippingCompany({
    required String companyName,
    required String email,
    required String password,
    required String phoneNumber,
    String landNumber = '',
    required String commercialRegister,
    required String taxNumber,
    String website = '',
  }) async {
    emit(RegisterSellerLoadingState());
    final fcmToken = await _getFcmToken();
    final result = await authRepository.registerShippingCompany(
      companyName: companyName,
      email: email,
      password: password,
      phoneNumber: phoneNumber,
      landNumber: landNumber,
      commercialRegister: commercialRegister,
      taxNumber: taxNumber,
      website: website,
      fcmToken: fcmToken,
      preferredLanguage: _currentLanguageCode,
    );

    result.fold(
      (failure) => emit(RegisterSellerErrorState(failure.message)),
      (user) => emit(RegisterSellerSuccessState(user)),
    );
  }

  Future<void> verifyEmailOtp({
    required String email,
    required String otp,
   
  }) async {
    emit(VerifyOtpLoadingState());
    final fcmToken = await _getFcmToken();
    final result = await verifyEmailOtpUseCase(
      VerifyEmailOtpParameters(
        email: email,
        otp: otp,
        fcmToken: fcmToken,
      ),
    );
    result.fold((failure) => emit(VerifyOtpErrorState(failure.message)), (
      loginResponse,
    ) async {
      final token = loginResponse.authToken ?? '';
      final pending = loginResponse.isPendingAdminApproval;

      await AuthService.instance.saveAuthData(
        personId:
            loginResponse.personId ??
            AuthService.instance.currentUserID ??
            '',
        authToken: token,
        userEmail: loginResponse.email ?? email,
        fullName: loginResponse.fullName,
        userRole: loginResponse.role,
        userRoleId: AuthService.instance.currentUserRoleId ?? '',
        companyWaiting: pending,
        approved: loginResponse.isApproved,
        isCustomerAcount: loginResponse.isCustomer,
        verified: loginResponse.isVerified ?? true,
        companyAccount: loginResponse.isCompanyAccount,
        shippingCompanyAccount: loginResponse.isShippingCompanyAccount,
        clearSessionToken: token.isEmpty,
      );

      if (pending || token.isEmpty) {
        // Verified but waiting for admin — no API session until approved.
        emit(VerifyOtpSuccessState(loginResponse));
        return;
      }

      emit(VerifyOtpSuccessState(loginResponse));
    });
  }

  Future<void> checkAccountApprovalStatus({required String email}) async {
    final result = await authRepository.checkAccountApprovalStatus(
      email: email,
    );
    result.fold((_) {}, (status) async {
      if (status.isApproved) {
        await AuthService.instance.setCompanyWaiting(false);
        final token = status.token ?? AuthService.instance.currentToken ?? '';
        await AuthService.instance.saveAuthData(
          personId: status.id ?? AuthService.instance.currentUserID ?? '',
          authToken: token,
          userRoleId: AuthService.instance.currentUserRoleId ?? '',
          userEmail: status.email ?? email,
          fullName: status.name ?? AuthService.instance.currentUserName,
          userRole: status.roleName ?? AuthService.instance.currentUserRoleName,
          companyWaiting: false,
          approved: true,
          verified: status.isVerified,
          companyAccount: status.isCompanyAccount,
          shippingCompanyAccount: status.isShippingCompanyAccount ||
              isShippingCompanyAccount == true ||
              status.roleName == 'ShippingCompany',
          isCustomerAcount: status.isCustomer,
          userPhone: status.phone,
        );
        emit(const AccountApprovalApprovedState());
      }
    });
  }

  static bool isPendingApprovalMessage(String message) {
    final normalized = message.toLowerCase();
    return normalized.contains('not been approved') ||
        normalized.contains('pending admin approval') ||
        normalized.contains('pending approval') ||
        message.contains('قيد موافقة') ||
        message.contains('لم تتم الموافقة');
  }

  static bool isVerifyEmailMessage(String message) {
    final normalized = message.toLowerCase();
    return normalized.contains('verify your email') ||
        normalized.contains('verify email') ||
        message.contains('تحقق') ||
        message.contains('فعّل بريد') ||
        message.contains('فعّل البريد');
  }

  static void navigateAfterAuthSuccess(
    BuildContext context,
    LoginResponseModel response,
  ) {
    unawaited(PendingProfileImageUploader.uploadIfPending());
    _resetHomeTabs();
    final destination = whereToGo();
    context.go(destination);

    final isHome = destination == AppRoutes.kPersonHomeView ||
        destination == AppRoutes.kClientHomeView ||
        destination == AppRoutes.kCompanyHomeView ||
        destination == AppRoutes.kShippingCompanyHomeView;

    if (!isHome) return;

    final clintCubit = sl<ClintCubit>();
    if (!clintCubit.isClosed) {
      final isPerson = response.isCompanyAccount != true;
      unawaited(clintCubit.reloadHomeAfterAuth(isPerson: isPerson));
    }

    unawaited(_ensureInitialAddressIfMissing());
  }

  /// Restores navigation after Face ID / fingerprint unlock (no LoginResponse).
  static void navigateAfterBiometricUnlock(BuildContext context) {
    _resetHomeTabs();
    final destination = whereToGo();
    context.go(destination);

    final isHome = destination == AppRoutes.kPersonHomeView ||
        destination == AppRoutes.kClientHomeView ||
        destination == AppRoutes.kCompanyHomeView ||
        destination == AppRoutes.kShippingCompanyHomeView;
    if (!isHome) return;

    final clintCubit = sl<ClintCubit>();
    if (!clintCubit.isClosed) {
      final isPerson = AuthService.instance.currentUserIsCompanyAccount != true;
      unawaited(clintCubit.reloadHomeAfterAuth(isPerson: isPerson));
    }
    unawaited(_ensureInitialAddressIfMissing());
  }

  static Future<void> _ensureInitialAddressIfMissing() async {
    final token = AuthService.instance.currentToken;
    if (token == null || token.isEmpty) return;

    final pending = PendingRegistrationAddress.take();
    if (pending != null) {
      await sl<CreateClientAddressUseCase>()(token: token, request: pending);
      return;
    }

    final addressesResult = await sl<GetClientAddressesUseCase>()(token: token);
    final hasNoAddress = addressesResult.fold((_) => false, (items) => items.isEmpty);
    if (!hasNoAddress) return;

    await Future<void>.delayed(const Duration(milliseconds: 250));
    if (AppRoutes.navigatorKey.currentContext == null) return;
    await AddAddressDialog.show(AppRoutes.navigatorKey.currentContext!);
  }

  static void _resetHomeTabs() {
    final companyCubit = sl<CompanyCubit>();
    if (!companyCubit.isClosed) {
      companyCubit.setTab(0);
    }

    final clintCubit = sl<ClintCubit>();
    if (!clintCubit.isClosed) {
      clintCubit.setTab(0);
    }

    final personCubit = sl<PersonCubit>();
    if (!personCubit.isClosed) {
      personCubit.setTab(0);
    }

    final shippingCubit = sl<ShippingCompanyCubit>();
    if (!shippingCubit.isClosed) {
      shippingCubit.setTab(0);
    }
  }

  Future<void> forgotPassword({required String email}) async {
    emit(ForgetPasswordLoadingState());
    final result = await authRepository.forgotPasswordRequest(email: email);
    result.fold(
      (failure) => emit(ForgetPasswordErrorState(failure.message)),
      (message) => emit(ForgetPasswordSuccessState(message)),
    );
  }

  Future<void> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    emit(ResetPasswordLoadingState());
    final result = await authRepository.forgotPasswordReset(
      email: email,
      code: code,
      newPassword: newPassword,
    );
    result.fold(
      (failure) => emit(ResetPasswordErrorState(failure.message)),
      (message) => emit(ResetPasswordSuccessState(message)),
    );
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    emit(ChangePasswordLoadingState());
    final result = await authRepository.changePassword(
      currentPassword: currentPassword,
      newPassword: newPassword,
    );
    result.fold(
      (failure) => emit(ChangePasswordErrorState(failure.message)),
      (message) => emit(ChangePasswordSuccessState(message)),
    );
  }

  Future<void> resendEmailOtp({required String email}) async {
    emit(ResendOtpLoadingState());
    final result = await sendEmailOtpUseCase(
      SendEmailOtpParameters(email: email),
    );
    result.fold(
      (failure) => emit(ResendOtpErrorState(failure.message)),
      (_) => emit(ResendOtpSuccessState()),
    );
  }

  // Upload Commercial License
  Future<String?> uploadCompanyLicence(String filePath) async {
    emit(UploadFileLoadingState('companyLicence'));
    final result = await uploadCommercialLicenseUseCase(
      UploadFileParameters(filePath: filePath),
    );

    return result.fold(
      (failure) {
        emit(UploadFileErrorState(failure.message, 'companyLicence'));
        return null;
      },
      (fileUrl) {
        print("uploadCompanyLicence fileUrl: ${fileUrl}");
        emit(UploadFileSuccessState(fileUrl, 'companyLicence'));
        return fileUrl;
      },
    );
  }

  // Upload Seller Identity
  Future<String?> uploadCompanyImages(String filePath) async {
    emit(UploadFileLoadingState('companyImages'));
    final result = await uploadSellerIdentityUseCase(
      UploadFileParameters(filePath: filePath),
    );

    return result.fold(
      (failure) {
        print("uploadCompanyImages failure: ${failure.message}");
        emit(UploadFileErrorState(failure.message, 'companyImages'));
        return null;
      },
      (fileUrl) {
        print("uploadCompanyImages fileUrl: ${fileUrl}");
        emit(UploadFileSuccessState(fileUrl, 'companyImages'));
        return fileUrl;
      },
    );
  }

  // Logout
  Future<void> logout() async {
    // Clear authentication data using AuthService
    await AuthService.instance.logout();
    final clintCubit = sl<ClintCubit>();
    if (!clintCubit.isClosed) {
      clintCubit.clearHomeCatalogMemory();
      clintCubit.setTab(0);
    }

    emit(AuthInitialState());
  }

  // Delete Account
  Future<void> deleteAccount({required String password}) async {
    emit(DeleteAccountLoadingState());

    final response = await authRepository.deleteAccount(password: password);
    response.fold(
      (failure) {
        emit(DeleteAccountErrorState(failure.message));
      },
      (message) async {
        await BiometricAuthService.instance.disable();
        await AuthService.instance.logout();
        emit(DeleteAccountSuccessState(message));
      },
    );
  }

  // Check if user is logged in
  bool isLoggedIn() {
    final token = CachHelper.getData('token');
    return token != null && token.toString().isNotEmpty;
  }

  // Get saved token
  String? getToken() {
    final token = CachHelper.getData('token');
    return token?.toString();
  }
}
