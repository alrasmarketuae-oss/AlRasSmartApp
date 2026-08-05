import 'dart:io';
import 'package:alrasmarket/core/serveses/auth_service.dart';
import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:alrasmarket/core/services/api_constants.dart';
import 'package:alrasmarket/core/services/dio_helper.dart';
import '../../../../core/error/failure.dart';
import '../models/account_approval_status_model.dart';
import '../models/login_response_model.dart';
import '../../domain/entities/user.dart';
import '../../domain/usecases/login_usecase.dart';
import '../../domain/usecases/register_person_usecase.dart';
import '../../domain/usecases/register_company_usecase.dart';
import '../../domain/usecases/send_email_otp_usecase.dart';
import '../../domain/usecases/verify_email_otp_usecase.dart';
import 'dart:convert';

abstract class BaseAuthRemoteDataSource {
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
    String landNumber = '',
    required String commercialRegister,
    required String taxNumber,
    String website = '',
    required String fcmToken,
    required String preferredLanguage,
  });
  Future<Either<Failure, LoginResponseModel>> verifyEmailOtp(
    VerifyEmailOtpParameters parameters,
  );
  Future<Either<Failure, AccountApprovalStatusModel>>
  checkAccountApprovalStatus({required String email});
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

class AuthRemoteDataSource implements BaseAuthRemoteDataSource {
  // Login — same endpoint for email/password ("local") and social (google, apple)
  // Body: { loginProviderName, email, password, token, fcmToken }
  @override
  Future<Either<Failure, LoginResponseModel>> login(
    LoginParameters parameters,
  ) async {
    try {
      print("login parameters: ${parameters.toJson()}");
      final response = await DioHelper.postData(
        url: ApiConstants.loginEndPoint,
        data: parameters.toJson(),
      );

      if (response?.statusCode == 200 || response?.statusCode == 201) {
        print("login response: ${response?.data}");
        final loginResponse = LoginResponseModel.fromJson(response!.data);
        if (loginResponse.isRejected == true) {
          return Left(
            ServerFailure(
              loginResponse.rejectionReason ??
                  'Your account registration was rejected.',
            ),
          );
        }
        final token = loginResponse.authToken;
        if (token != null && token.isNotEmpty) {
          return Right(loginResponse);
        }
        return const Left(ServerFailure('Token not found in response'));
      }
      print("login error: ${response?.statusMessage}");
      return Left(
        ServerFailure(
          (response?.data is Map
                  ? response?.data['message']?.toString()
                  : null) ??
              'Login failed: ${response?.statusMessage ?? 'Unknown error'}',
        ),
      );
    } on DioException catch (e) {
      print("login error: ${e.toString()}");
      String errorMessage = 'Login failed';
      if (e.response?.data != null) {
        if (e.response!.data is Map) {
          errorMessage = e.response!.data['message'] ?? errorMessage;
        } else if (e.response!.data is String) {
          errorMessage = e.response!.data;
        }
      } else {
        errorMessage = e.message ?? errorMessage;
      }
      return Left(ServerFailure(errorMessage));
    } catch (e) {
      print("login error: ${e.toString()}");
      return Left(ServerFailure('An error occurred: ${e.toString()}'));
    }
  }

  // Register Client — POST /Clients/PostClient { firstName, secondName, email, password, phoneNumber }
  // إنشاء الحساب لا يرجع token، فبعد النجاح نعمل login و نرجع LoginResponseModel
  @override
  Future<Either<Failure, LoginResponseModel>> registerPerson(
    RegisterPersonParameters parameters,
  ) async {
    try {
      final response = await DioHelper.postData(
        url: ApiConstants.registerPersonEndPoint,
        data: {
          'fullName': parameters.fullName,
          'email': parameters.email,
          'password': parameters.password,
          'fcmToken': parameters.fcmToken,
          'phoneNumber': parameters.phoneNumber,
          'preferredLanguage': parameters.preferredLanguage,
        },
      );

      if (response?.statusCode == 200 || response?.statusCode == 201) {
        print("registerClient response: ${response?.data}");
        // تسجيل الدخول للحصول على token وبيانات المستخدم
        // final loginResult = await login(
        //   LoginParameters(
        //     email: parameters.email,
        //     password: parameters.password,
        //   ),
        // );
        AuthService.instance.saveAuthData(
          personId: '',
          authToken: '',
          userRoleId: '1',
          userEmail: parameters.email,
          fullName: parameters.fullName,
          userRole: 'Buyer',
          companyAccount: false,
          verified: false,
        );
        return Right(
          LoginResponseModel(
            email: parameters.email,
            name: parameters.fullName,
            phone: parameters.phoneNumber,
            roleName: 'Buyer',
            isCompanyAccount: false,
            isVerified: false,
          ),
        );
      } else {
        print(
          "registerClient error: ${response?.statusMessage ?? 'Unknown error'}",
        );
        return Left(
          ServerFailure(
            'Registration failed: ${response?.statusMessage ?? 'Unknown error'}',
          ),
        );
      }
    } on DioException catch (e) {
      print("Registration error: ${e.message} ${e.response?.data}");
      String errorMessage = 'Registration failed';
      if (e.response?.data != null) {
        if (e.response!.data is Map) {
          errorMessage =
              e.response!.data['message'] ??
              e.response!.data['title'] ??
              errorMessage;
        } else if (e.response!.data is String) {
          errorMessage = e.response!.data;
        }
      } else {
        errorMessage = e.message ?? errorMessage;
      }
      print("Registration error4: ${errorMessage}");
      return Left(ServerFailure(errorMessage));
    } catch (e) {
      print("Registration error3: ${e.toString()}");
      return Left(ServerFailure('An error occurred: ${e.toString()}'));
    }
  }

  // Register Seller
  @override
  Future<Either<Failure, User>> registerCompany(
    RegisterCompanyParameters parameters,
  ) async {
    try {
      print("registerCompany customer account: ${parameters.isCustomer}");
      final response = await DioHelper.postData(
        url: ApiConstants.registerCompanyEndPoint,
        data: {
          'fullName': parameters.fullName,
          'companyName': parameters.companyName,
          'email': parameters.email,
          'password': parameters.password,
          'phoneNumber': parameters.phoneNumber,
          'landNumber': parameters.landNumber,
          'licenseNumber': parameters.licenseNumber,
          'fcmToken': parameters.fcmToken,
          'licencePath': parameters.licencePath,
          'companyImagePaths': parameters.companyImagePaths,
          'birthDate': parameters.birthDate,
          'commercialRegister': parameters.commercialRegister,
          'taxNumber': parameters.taxNumber,
          'website': parameters.website,
          'isCustomer': parameters.isCustomer,
          'preferredLanguage': parameters.preferredLanguage,
        },
      );

      if (response?.statusCode == 200 || response?.statusCode == 201) {
        final data = response?.data;

        AuthService.instance.saveAuthData(
          personId: '',
          authToken: '',
          userRoleId: '2',
          userEmail: parameters.email,
          fullName: parameters.fullName,
          isCustomerAcount: parameters.isCustomer,
          approved: false,
          verified: false,
          companyAccount: true,
          userRole: 'Seller',
        );
        if (data is Map<String, dynamic>) {
          final user = _mapRegisterResponseToUser(data, 'Company');
          return Right(user);
        }
        return const Left(ServerFailure('Invalid response format'));
      } else {
        return Left(
          ServerFailure(
            'Registration failed: ${response?.statusMessage ?? 'Unknown error'}',
          ),
        );
      }
    } on DioException catch (e) {
      String errorMessage = 'Registration failed';
      if (e.response?.data != null) {
        if (e.response!.data is Map) {
          errorMessage =
              e.response!.data['message'] ??
              e.response!.data['title'] ??
              errorMessage;
        } else if (e.response!.data is String) {
          errorMessage = e.response!.data;
        }
      } else {
        errorMessage = e.message ?? errorMessage;
      }
      return Left(ServerFailure(errorMessage));
    } catch (e) {
      return Left(ServerFailure('An error occurred: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, User>> registerShippingCompany({
    required String companyName,
    required String email,
    required String password,
    required String phoneNumber,
    String landNumber = '',
    required String commercialRegister,
    required String taxNumber,
    String website = '',
    required String fcmToken,
    required String preferredLanguage,
  }) async {
    try {
      final response = await DioHelper.postData(
        url: ApiConstants.registerShippingCompanyEndPoint,
        data: {
          'companyName': companyName,
          'email': email,
          'password': password,
          'phoneNumber': phoneNumber,
          if (landNumber.trim().isNotEmpty) 'landNumber': landNumber.trim(),
          'commercialRegister': commercialRegister,
          'taxNumber': taxNumber,
          'website': website,
          'fcmToken': fcmToken,
          'preferredLanguage': preferredLanguage,
        },
      );

      if (response?.statusCode == 200 || response?.statusCode == 201) {
        final data = response?.data;
        AuthService.instance.saveAuthData(
          personId: '',
          authToken: '',
          userRoleId: '5',
          userEmail: email,
          fullName: companyName,
          approved: false,
          verified: false,
          companyAccount: false,
          shippingCompanyAccount: true,
          userRole: 'ShippingCompany',
        );
        if (data is Map<String, dynamic>) {
          final user = _mapRegisterResponseToUser(data, 'ShippingCompany');
          return Right(user);
        }
        return const Left(ServerFailure('Invalid response format'));
      }
      return Left(
        ServerFailure(
          'Registration failed: ${response?.statusMessage ?? 'Unknown error'}',
        ),
      );
    } on DioException catch (e) {
      String errorMessage = 'Registration failed';
      if (e.response?.data is Map) {
        errorMessage = e.response!.data['message']?.toString() ?? errorMessage;
      } else if (e.response?.data is String) {
        errorMessage = e.response!.data;
      } else {
        errorMessage = e.message ?? errorMessage;
      }
      return Left(ServerFailure(errorMessage));
    } catch (e) {
      return Left(ServerFailure('An error occurred: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, LoginResponseModel>> verifyEmailOtp(
    VerifyEmailOtpParameters parameters,
  ) async {
    try {
      final response = await DioHelper.postData(
        url: ApiConstants.verifyEmailOtpEndPoint,
        data: {
          'email': parameters.email,
          'otp': parameters.otp,
          if (parameters.fcmToken != null && parameters.fcmToken!.isNotEmpty)
            'fcmToken': parameters.fcmToken,
        },
      );

      if (response?.statusCode == 200 || response?.statusCode == 201) {
        final data = response?.data;
        if (data is! Map<String, dynamic>) {
          return const Left(ServerFailure('Invalid OTP verification response'));
        }
        final loginResponse = LoginResponseModel.fromJson(data);
        return Right(loginResponse);
      }
      return Left(
        ServerFailure(
          (response?.data is Map
                  ? response?.data['message']?.toString()
                  : null) ??
              'OTP verification failed',
        ),
      );
    } on DioException catch (e) {
      String errorMessage = 'OTP verification failed';
      if (e.response?.data is Map) {
        errorMessage = e.response?.data['message']?.toString() ?? errorMessage;
      } else if (e.response?.data is String) {
        errorMessage = e.response!.data;
      } else {
        errorMessage = e.message ?? errorMessage;
      }
      return Left(ServerFailure(errorMessage));
    } catch (e) {
      return Left(ServerFailure('An error occurred: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, AccountApprovalStatusModel>>
  checkAccountApprovalStatus({required String email}) async {
    try {
      final response = await DioHelper.getData(
        url: ApiConstants.accountApprovalStatusEndPoint(email),
      );

      if (response?.statusCode == 200) {
        final data = response?.data;
        if (data is! Map<String, dynamic>) {
          return const Left(ServerFailure('Invalid approval status response'));
        }

        return Right(AccountApprovalStatusModel.fromJson(data));
      }

      return Left(
        ServerFailure(
          (response?.data is Map
                  ? response?.data['message']?.toString()
                  : null) ??
              'Failed to check approval status',
        ),
      );
    } on DioException catch (e) {
      String errorMessage = 'Failed to check approval status';
      if (e.response?.data is Map) {
        errorMessage = e.response?.data['message']?.toString() ?? errorMessage;
      }
      return Left(ServerFailure(errorMessage));
    } catch (e) {
      return Left(ServerFailure('An error occurred: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> sendEmailOtp(
    SendEmailOtpParameters parameters,
  ) async {
    try {
      final response = await DioHelper.postData(
        url: ApiConstants.sendEmailOtpEndPoint,
        data: {'email': parameters.email},
      );
      print("sendEmailOtp response: ${response?.data}");
      if (response?.statusCode == 200 || response?.statusCode == 201) {
        return const Right(null);
      }
      return Left(
        ServerFailure(
          (response?.data is Map
                  ? response?.data['message']?.toString()
                  : null) ??
              'Failed to resend OTP',
        ),
      );
    } on DioException catch (e) {
      String errorMessage = 'Failed to resend OTP';
      print("sendEmailOtp error: ${e.toString()}");
      if (e.response?.data is Map) {
        errorMessage = e.response?.data['message']?.toString() ?? errorMessage;
      } else if (e.response?.data is String) {
        errorMessage = e.response!.data;
      } else {
        errorMessage = e.message ?? errorMessage;
      }
      print("sendEmailOtp error4: ${errorMessage}");
      return Left(ServerFailure(errorMessage));
    } catch (e) {
      print("sendEmailOtp error3: ${e.toString()}");
      return Left(ServerFailure('An error occurred: ${e.toString()}'));
    }
  }

  // Upload Commercial License
  @override
  Future<Either<Failure, String>> uploadCompanyLicence(String filePath) async {
    try {
      final file = File(filePath);
      final formData = FormData.fromMap({
        'File': await MultipartFile.fromFile(
          file.path,
          filename: file.path.split('/').last,
        ),
      });

      final response = await DioHelper.uploadFile(
        url: ApiConstants.uploadCompanyLicenceEndPoint,
        formData: formData,
      );
      print("uploadCompanyLicence response: ${response?.data}");
      if (response?.statusCode == 200 || response?.statusCode == 201) {
        final data = response!.data;
        if (data is Map) {
          // Backend may return: { licencePath: "..." } or { imagePath: "..." }
          final fileUrl =
              data['licencePath'] ??
              data['LicencePath'] ??
              data['imagePath'] ??
              data['ImagePath'] ??
              data['ImageUrl'] ??
              data['imageUrl'] ??
              data['path'] ??
              '';
          if (fileUrl.isNotEmpty) {
            print("uploadCompanyLicence fileUrl: ${fileUrl}");
            return Right(fileUrl);
          }
        } else if (data is String) {
          return Right(data);
        }
        print("uploadCompanyLicence error2: ${data}");
        return const Left(ServerFailure('Invalid response format'));
      } else {
        print("uploadCompanyLicence error: ${response?.statusMessage}");
        return Left(
          ServerFailure(
            'Upload failed: ${response?.statusMessage ?? 'Unknown error'}',
          ),
        );
      }
    } on DioException catch (e) {
      String errorMessage = 'Upload failed';
      print("uploadCompanyLicence error3: ${e.toString()}");
      if (e.response?.data != null) {
        if (e.response!.data is Map) {
          errorMessage = e.response!.data['message'] ?? errorMessage;
        } else if (e.response!.data is String) {
          errorMessage = e.response!.data;
        }
      } else {
        errorMessage = e.message ?? errorMessage;
      }
      print("uploadCompanyLicence error4: ${errorMessage}");
      return Left(ServerFailure(errorMessage));
    } catch (e) {
      print("uploadCompanyLicence error5: ${e.toString()}");
      return Left(ServerFailure('An error occurred: ${e.toString()}'));
    }
  }

  // Upload Seller Identity
  @override
  Future<Either<Failure, String>> uploadCompanyImages(String filePath) async {
    try {
      final file = File(filePath);
      final formData = FormData.fromMap({
        'File': await MultipartFile.fromFile(
          file.path,
          filename: file.path.split('/').last,
        ),
      });

      final response = await DioHelper.uploadFile(
        url: ApiConstants.uploadCompanyImagesEndPoint,
        formData: formData,
      );

      if (response?.statusCode == 200 || response?.statusCode == 201) {
        final data = response!.data;
        if (data is Map) {
          // Backend may return: { imagePath: "...", isPrimary: true }
          final fileUrl =
              data['imagePath'] ??
              data['ImagePath'] ??
              data['licencePath'] ??
              data['LicencePath'] ??
              data['ImageUrl'] ??
              data['imageUrl'] ??
              data['path'] ??
              '';
          if (fileUrl.isNotEmpty) {
            return Right(fileUrl);
          }
        } else if (data is String) {
          return Right(data);
        }
        return const Left(ServerFailure('Invalid response format'));
      } else {
        return Left(
          ServerFailure(
            'Upload failed: ${response?.statusMessage ?? 'Unknown error'}',
          ),
        );
      }
    } on DioException catch (e) {
      String errorMessage = 'Upload failed';
      if (e.response?.data != null) {
        if (e.response!.data is Map) {
          errorMessage = e.response!.data['message'] ?? errorMessage;
        } else if (e.response!.data is String) {
          errorMessage = e.response!.data;
        }
      } else {
        errorMessage = e.message ?? errorMessage;
      }
      return Left(ServerFailure(errorMessage));
    } catch (e) {
      return Left(ServerFailure('An error occurred: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, String>> forgotPasswordRequest({
    required String email,
  }) async {
    try {
      final response = await DioHelper.postData(
        url: ApiConstants.forgotPasswordRequestEndPoint,
        data: {
          'providerName': 'Email',
          'destination': email.trim(),
        },
      );

      if (response?.statusCode == 200 || response?.statusCode == 201) {
        final data = response?.data;
        if (data is Map) {
          return Right(
            data['message']?.toString() ?? 'Password reset code sent.',
          );
        }
        return const Right('Password reset code sent.');
      }

      return Left(
        ServerFailure(
          (response?.data is Map
                  ? response?.data['message']?.toString()
                  : null) ??
              'Failed to send reset code',
        ),
      );
    } on DioException catch (e) {
      String errorMessage = 'Failed to send reset code';
      if (e.response?.data is Map) {
        errorMessage = e.response?.data['message']?.toString() ?? errorMessage;
      }
      return Left(ServerFailure(errorMessage));
    } catch (e) {
      return Left(ServerFailure('An error occurred: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, String>> forgotPasswordReset({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    try {
      final response = await DioHelper.postData(
        url: ApiConstants.forgotPasswordResetEndPoint,
        data: {
          'providerName': 'Email',
          'destination': email.trim(),
          'code': code.trim(),
          'newPassword': newPassword,
        },
      );

      if (response?.statusCode == 200 || response?.statusCode == 201) {
        final data = response?.data;
        if (data is Map) {
          return Right(data['message']?.toString() ?? 'Password reset successfully.');
        }
        return const Right('Password reset successfully.');
      }

      return Left(
        ServerFailure(
          (response?.data is Map
                  ? response?.data['message']?.toString()
                  : null) ??
              'Failed to reset password',
        ),
      );
    } on DioException catch (e) {
      String errorMessage = 'Failed to reset password';
      if (e.response?.data is Map) {
        errorMessage = e.response?.data['message']?.toString() ?? errorMessage;
      }
      return Left(ServerFailure(errorMessage));
    } catch (e) {
      return Left(ServerFailure('An error occurred: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, String>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final token = AuthService.instance.currentToken;
      if (token == null || token.isEmpty) {
        return const Left(ServerFailure('Please sign in again.'));
      }

      final response = await DioHelper.postData(
        url: ApiConstants.changePasswordEndPoint,
        token: token,
        data: {
          'currentPassword': currentPassword,
          'newPassword': newPassword,
          'CurrentPassword': currentPassword,
          'NewPassword': newPassword,
        },
      );

      if (response?.statusCode == 200 || response?.statusCode == 201) {
        final data = response?.data;
        if (data is Map) {
          return Right(
            data['message']?.toString() ?? 'Password changed successfully.',
          );
        }
        return const Right('Password changed successfully.');
      }

      return Left(
        ServerFailure(
          (response?.data is Map
                  ? response?.data['message']?.toString()
                  : null) ??
              'Failed to change password',
        ),
      );
    } on DioException catch (e) {
      String errorMessage = 'Failed to change password';
      if (e.response?.data is Map) {
        errorMessage = e.response?.data['message']?.toString() ?? errorMessage;
      }
      return Left(ServerFailure(errorMessage));
    } catch (e) {
      return Left(ServerFailure('An error occurred: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, String>> deleteAccount({
    required String password,
  }) async {
    try {
      final token = AuthService.instance.currentToken;
      if (token == null || token.isEmpty) {
        return const Left(ServerFailure('Please sign in again.'));
      }

      final response = await DioHelper.postData(
        url: ApiConstants.deleteAccountEndPoint,
        token: token,
        data: {'password': password, 'Password': password},
      );

      final status = response?.statusCode ?? 0;
      print('DELETE ACCOUNT status=$status body=${response?.data}');
      if (status >= 200 && status < 300) {
        final message = response?.data is Map
            ? response?.data['message']?.toString()
            : null;
        return Right(message ?? 'Account deleted successfully.');
      }

      return Left(ServerFailure(_deleteAccountErrorMessage(response?.data, status)));
    } on DioException catch (e) {
      print(
        'DELETE ACCOUNT DioException status=${e.response?.statusCode} '
        'body=${e.response?.data} error=${e.message}',
      );
      return Left(
        ServerFailure(
          _deleteAccountErrorMessage(
            e.response?.data,
            e.response?.statusCode ?? 0,
          ),
        ),
      );
    } catch (e) {
      print('DELETE ACCOUNT unexpected error: $e');
      return Left(ServerFailure('An error occurred: ${e.toString()}'));
    }
  }

  String _deleteAccountErrorMessage(dynamic data, int status) {
    if (data is Map) {
      final detail = data['detail']?.toString().trim();
      final message = data['message']?.toString().trim();
      if (detail != null && detail.isNotEmpty) {
        return message != null && message.isNotEmpty
            ? '$message\n$detail'
            : detail;
      }
      if (message != null && message.isNotEmpty) {
        return message;
      }
      return data.toString();
    }
    if (data != null) return data.toString();
    if (status == 401) return 'Password is incorrect.';
    return 'Failed to delete account (HTTP $status)';
  }

  // Helper method to map register response to User entity
  // Backend returns { PersonId: newClientId } or { PersonId: newSellerId }
  User _mapRegisterResponseToUser(Map<String, dynamic> data, String roleName) {
    return User(
      id:
          data['PersonId']?.toString() ??
          data['personId']?.toString() ??
          data['id']?.toString() ??
          '',
      email: '', // Not returned in register response
      fullName: '', // Not returned in register response
      phone: null,
      roleName: roleName,
      roleId: roleName == 'Client' ? '7' : '8', // Client=7, Seller=8
      token: null, // Not returned in register response
      genderId: null,
      dateOfBirth: null,
      profileImage: null,
      storeName: null,
    );
  }

  Map<String, dynamic> decodeJwtPayload(String token) {
    final parts = token.split('.');
    if (parts.length != 3) {
      throw const FormatException('Invalid JWT');
    }
    final payload = base64Url.normalize(parts[1]);
    final jsonStr = utf8.decode(base64Url.decode(payload));
    return json.decode(jsonStr) as Map<String, dynamic>;
  }
}
