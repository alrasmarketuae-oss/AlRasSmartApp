import 'dart:async';
import 'dart:io';

import 'package:alrasmarket/core/cache/api_cache_keys.dart';
import 'package:alrasmarket/core/cache/api_cache_store.dart';
import 'package:alrasmarket/core/services/api_constants.dart';
import 'package:alrasmarket/core/services/dio_helper.dart';
import 'package:alrasmarket/core/serveses/auth_service.dart';
import 'package:dio/dio.dart';

class UserProfile {
  final String fullName;
  final String email;
  final String? phoneNumber;
  final String? companyName;
  final String? commercialRegister;
  final String? taxNumber;
  final String? landNumber;
  final String? imgPath;
  final DateTime? birthDate;
  final String roleName;
  final bool isCompanyAccount;
  final bool isRejected;
  final String? rejectionReason;
  final bool hasPendingProfileChanges;

  /// False for Google/Apple accounts that never set a local password.
  /// Null when the response predates the field (e.g. a stale cache entry).
  final bool? hasPassword;
  final String? loginProviderName;
  final bool isNotificationsOn;

  const UserProfile({
    required this.fullName,
    required this.email,
    this.phoneNumber,
    this.companyName,
    this.commercialRegister,
    this.taxNumber,
    this.landNumber,
    this.imgPath,
    this.birthDate,
    required this.roleName,
    required this.isCompanyAccount,
    this.isRejected = false,
    this.rejectionReason,
    this.hasPendingProfileChanges = false,
    this.hasPassword,
    this.loginProviderName,
    this.isNotificationsOn = true,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    DateTime? birth;
    final birthRaw = json['birthDate'] ?? json['BirthDate'];
    if (birthRaw != null) {
      birth = DateTime.tryParse(birthRaw.toString());
    }

    final notificationsRaw =
        json['isNotificationsOn'] ?? json['IsNotificationsOn'];

    return UserProfile(
      fullName: (json['fullName'] ?? json['FullName'] ?? '').toString(),
      email: (json['email'] ?? json['Email'] ?? '').toString(),
      phoneNumber: (json['phoneNumber'] ?? json['PhoneNumber'])?.toString(),
      companyName: (json['companyName'] ?? json['CompanyName'])?.toString(),
      commercialRegister:
          (json['commercialRegister'] ?? json['CommercialRegister'])?.toString(),
      taxNumber: (json['taxNumber'] ?? json['TaxNumber'])?.toString(),
      landNumber: (json['landNumber'] ?? json['LandNumber'])?.toString(),
      imgPath: (json['imgPath'] ?? json['ImgPath'])?.toString(),
      birthDate: birth,
      roleName: (json['roleName'] ?? json['RoleName'] ?? '').toString(),
      isCompanyAccount:
          json['isCompanyAccount'] == true || json['IsCompanyAccount'] == true,
      isRejected: json['isRejected'] == true || json['IsRejected'] == true,
      rejectionReason:
          (json['rejectionReason'] ?? json['RejectionReason'])?.toString(),
      hasPendingProfileChanges:
          json['hasPendingProfileChanges'] == true ||
          json['HasPendingProfileChanges'] == true ||
          (json['pendingProfileChanges'] ?? json['PendingProfileChanges']) != null,
      hasPassword: (json['hasPassword'] ?? json['HasPassword']) as bool?,
      loginProviderName:
          (json['loginProviderName'] ?? json['LoginProviderName'])?.toString(),
      isNotificationsOn: notificationsRaw != false,
    );
  }

  Map<String, dynamic> toJson() => {
    'fullName': fullName,
    'email': email,
    'phoneNumber': phoneNumber,
    'companyName': companyName,
    'commercialRegister': commercialRegister,
    'taxNumber': taxNumber,
    'landNumber': landNumber,
    'imgPath': imgPath,
    'birthDate': birthDate?.toIso8601String(),
    'roleName': roleName,
    'isCompanyAccount': isCompanyAccount,
    'isRejected': isRejected,
    'rejectionReason': rejectionReason,
    'hasPendingProfileChanges': hasPendingProfileChanges,
    'hasPassword': hasPassword,
    'loginProviderName': loginProviderName,
    'isNotificationsOn': isNotificationsOn,
  };
}

class ProfileService {
  ProfileService._();
  static final ProfileService instance = ProfileService._();

  Future<UserProfile> fetchMyProfile({bool forceRefresh = false}) async {
    final userId = AuthService.instance.currentUserID ?? 'anonymous';
    final cacheKey = ApiCacheKeys.userProfile(userId);

    if (forceRefresh) {
      await ApiCacheStore.instance.remove(cacheKey);
    } else {
      final cached = await ApiCacheStore.instance.read(cacheKey);
      if (cached != null) {
        try {
          final profile = UserProfile.fromJson(
            Map<String, dynamic>.from(cached.data as Map),
          );
          _ensureNotRejected(profile);
          await _syncAuthFromProfile(profile);
          if (!cached.isFresh) {
            unawaited(_fetchProfileNetwork(cacheKey, background: true));
          }
          return profile;
        } catch (_) {
          await ApiCacheStore.instance.remove(cacheKey);
        }
      }
    }

    return _fetchProfileNetwork(cacheKey, background: false);
  }

  Future<UserProfile> _fetchProfileNetwork(
    String cacheKey, {
    required bool background,
  }) async {
    final response = await DioHelper.getData(
      url: ApiConstants.userProfileEndPoint,
      token: AuthService.instance.currentToken,
    );
    if (response?.statusCode == 401 || response?.statusCode == 403) {
      throw ProfileAccessDeniedException(
        (response?.data is Map
                ? response?.data['message']?.toString()
                : null) ??
            'Your account is not allowed to access the app.',
      );
    }
    if (response?.statusCode != 200) {
      final stale = await ApiCacheStore.instance.read(cacheKey, allowStale: true);
      if (stale != null) {
        final profile = UserProfile.fromJson(
          Map<String, dynamic>.from(stale.data as Map),
        );
        _ensureNotRejected(profile);
        return profile;
      }
      throw Exception('Failed to load profile');
    }
    final data = response?.data;
    if (data is! Map<String, dynamic>) {
      throw Exception('Invalid profile response');
    }

    await ApiCacheStore.instance.write(
      cacheKey,
      data,
      ApiCacheTtl.profile,
    );

    final profile = UserProfile.fromJson(data);
    _ensureNotRejected(profile);
    if (!background) {
      await _syncAuthFromProfile(profile);
    }
    return profile;
  }

  Future<UserProfile> updateMyProfile(Map<String, dynamic> body) async {
    final response = await DioHelper.putData(
      url: ApiConstants.userProfileEndPoint,
      data: body,
      token: AuthService.instance.currentToken,
    );
    if (response?.statusCode != 200) {
      final message = response?.data is Map
          ? response?.data['message']?.toString()
          : null;
      throw Exception(message ?? 'Failed to update profile');
    }
    final data = response?.data;
    if (data is! Map<String, dynamic>) {
      throw Exception('Invalid profile response');
    }
    final profile = UserProfile.fromJson(data);
    final userId = AuthService.instance.currentUserID;
    if (userId != null && userId.isNotEmpty) {
      await ApiCacheStore.instance.write(
        ApiCacheKeys.userProfile(userId),
        data,
        ApiCacheTtl.profile,
      );
    }
    await _syncAuthFromProfile(profile);
    return profile;
  }

  Future<bool> updateNotificationsPreference(bool isNotificationsOn) async {
    final response = await DioHelper.putData(
      url: ApiConstants.userNotificationsPreferenceEndPoint,
      data: {'isNotificationsOn': isNotificationsOn},
      token: AuthService.instance.currentToken,
    );
    if (response?.statusCode != 200) {
      final message = response?.data is Map
          ? response?.data['message']?.toString()
          : null;
      throw Exception(message ?? 'Failed to update notifications preference');
    }

    final data = response?.data;
    final enabled = data is Map
        ? (data['isNotificationsOn'] ?? data['IsNotificationsOn']) != false
        : isNotificationsOn;

    final userId = AuthService.instance.currentUserID;
    if (userId != null && userId.isNotEmpty) {
      final cacheKey = ApiCacheKeys.userProfile(userId);
      final cached = await ApiCacheStore.instance.read(cacheKey, allowStale: true);
      if (cached?.data is Map) {
        final map = Map<String, dynamic>.from(cached!.data as Map);
        map['isNotificationsOn'] = enabled;
        await ApiCacheStore.instance.write(cacheKey, map, ApiCacheTtl.profile);
      }
    }

    return enabled;
  }

  Future<UserProfile> uploadMyProfileImage(String filePath) async {
    final file = File(filePath);
    final formData = FormData.fromMap({
      'File': await MultipartFile.fromFile(
        file.path,
        filename: file.path.split(Platform.pathSeparator).last,
      ),
    });
    final response = await DioHelper.putUpload(
      url: ApiConstants.userProfileImageEndPoint,
      formData: formData,
      token: AuthService.instance.currentToken,
    );
    if (response?.statusCode != 200) {
      final message = response?.data is Map
          ? response?.data['message']?.toString()
          : null;
      throw Exception(message ?? 'Failed to upload profile image');
    }
    final data = response?.data;
    if (data is! Map<String, dynamic>) {
      throw Exception('Invalid profile response');
    }
    final profile = UserProfile.fromJson(data);
    final userId = AuthService.instance.currentUserID;
    if (userId != null && userId.isNotEmpty) {
      await ApiCacheStore.instance.write(
        ApiCacheKeys.userProfile(userId),
        data,
        ApiCacheTtl.profile,
      );
    }
    await _syncAuthFromProfile(profile);
    return profile;
  }

  void _ensureNotRejected(UserProfile profile) {
    if (profile.isRejected) {
      throw ProfileAccessDeniedException(
        profile.rejectionReason ??
            'Your account registration was rejected.',
      );
    }
  }

  Future<void> _syncAuthFromProfile(UserProfile profile) async {
    await AuthService.instance.updateProfileData(
      userEmail: profile.email,
      fullName: profile.fullName,
      userRole: profile.roleName,
      imagePath: profile.imgPath ?? '',
    );
    if (profile.phoneNumber != null) {
      await AuthService.instance.savePhone(profile.phoneNumber!);
    }
    final hasPassword = profile.hasPassword;
    if (hasPassword != null) {
      await AuthService.instance.setHasPassword(hasPassword);
    }
    await AuthService.instance.setLoginProviderName(profile.loginProviderName);
  }
}

class ProfileAccessDeniedException implements Exception {
  ProfileAccessDeniedException(this.message);
  final String message;

  @override
  String toString() => message;
}
