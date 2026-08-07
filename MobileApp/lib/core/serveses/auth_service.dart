import 'dart:async';

import 'package:flutter/material.dart';
import '../../../core/cache/api_cache_store.dart';
import '../../../core/helper/cach_helper.dart';
import '../../../core/serveses/app_chat_listener_service.dart';
import '../../../core/serveses/cached_constants.dart';
import '../../../core/services/api_constants.dart';
import '../../../core/services/biometric_auth_service.dart';
import '../../../core/services/dio_helper.dart';
import '../../../core/services/fcm_token_service.dart';
import '../../../core/serveses/notifications_service.dart';

/// Centralized authentication service for managing user authentication state
class AuthService {
  static AuthService? _instance;
  static AuthService get instance => _instance ??= AuthService._();

  AuthService._();

  /// Bumped whenever profile image changes so UI can refresh cached avatars.
  final ValueNotifier<int> profileImageRevision = ValueNotifier(0);

  String? get currentProfileImageUrl {
    final path = userImagePath?.trim();
    if (path == null || path.isEmpty) return null;
    final resolved = ApiConstants.resolveMediaUrl(path);
    if (resolved.isEmpty) return null;
    return '$resolved?v=${profileImageRevision.value}';
  }

  /// Check if user is authenticated
  bool get isAuthenticated => token != null && token!.isNotEmpty;

  /// Guest browsing (no token) — category catalog home, no prices.
  bool get isGuest => !isAuthenticated;

  /// Get current user ID (personId)
  String? get currentUserID => id;

  /// Get current user token
  String? get currentToken => token;

  /// Get current user name (fullName)
  String? get currentUserName => name;

  /// Get current user email
  String? get currentUserEmail => email;

  /// Get current user phone number
  String? get currentUserPhone => phone;

  String? phone;

  /// Null until `/users/me` has been read once. False for Google/Apple accounts
  /// that never set a local password — they must not be asked for a current one.
  bool? hasPassword;

  /// `Local`, `Google`, `Apple`, ... as reported by the profile endpoint.
  String? loginProviderName;

  /// Get current user role name
  String? get currentUserRoleName => roleName;
  String? get currentUserImagePath => userImagePath;

  String? get currentUserRoleId => roleId;
  bool get currentUserIsApproved => isApproved ?? false;
  bool get currentUserIsCustomer => isCustomer ?? false;
  bool get currentUserIsCompanyAccount => isCompanyAccount == true;

  /// Person account (IsCustomer=false, not a company account).
  /// Guests are not personal customers — they browse category catalog only.
  bool get isPersonalCustomerAccount =>
      isAuthenticated && isCompanyAccount != true;

  /// UAE mobile numbers start with +971 / 971.
  bool get isUaePhoneNumber {
    final raw = (phone ?? '').replaceAll(RegExp(r'[\s\-]'), '');
    if (raw.isEmpty) return false;
    final digits = raw.replaceAll(RegExp(r'[^\d]'), '');
    return digits.startsWith('971') || raw.startsWith('+971');
  }

  /// Company buyer account (IsCustomer=true on login).
  bool get isCompanyCustomerAccount =>
      isCompanyAccount == true && currentUserIsCustomer;

  /// Supplier / seller company account (IsCustomer=false, company account).
  bool get isSupplierAccount =>
      isCompanyAccount == true && !currentUserIsCustomer;

  /// Initialize authentication service - loads cached data
  Future<void> initializeAuth() async {
    try {
      // Load cached authentication data
      // Map personId to id
      final personId = CachHelper.getData('personId');
      id = personId?.toString();

      token = CachHelper.getData('token')?.toString();

      // Map fullName to name
      final fullName = CachHelper.getData('fullName');
      name = fullName?.toString();

      email = CachHelper.getData('email')?.toString();
      phone = CachHelper.getData('phone')?.toString();
      userImagePath = CachHelper.getData('userImagePath')?.toString();
      final revision = CachHelper.getData('userImageRevision');
      profileImageRevision.value = revision is int
          ? revision
          : int.tryParse(revision?.toString() ?? '') ?? 0;
      final isApprovedData = CachHelper.getData('isApproved') as bool?;
      isApproved = isApprovedData;
      final isCustomerData = CachHelper.getData('isCustomer') as bool?;
      isCustomer = isCustomerData;
      final isVerifiedData = CachHelper.getData('isVerified') as bool?;
      isVerified = isVerifiedData;
      final isCompanyAccountData =
          CachHelper.getData('isCompanyAccount') as bool?;
      isCompanyAccount = isCompanyAccountData;
      final isShippingCompanyAccountData =
          CachHelper.getData('isShippingCompanyAccount') as bool?;
      isShippingCompanyAccount = isShippingCompanyAccountData;

      hasPassword = CachHelper.getData('hasPassword') as bool?;
      loginProviderName = CachHelper.getData('loginProviderName')?.toString();

      final role = CachHelper.getData('role');
      roleName = role?.toString();
      final rId = CachHelper.getData('roleId')?.toString();
      roleId = rId;

      // Push token rotations reach the backend without waiting for a new login.
      FcmTokenService.instance.onTokenRefreshed =
          (refreshed) => unawaited(registerFcmToken(fcmToken: refreshed));

      // Load language settings
      lang = CachHelper.getData('languageCode')?.toString() ?? 'ar';
      isArabic = lang == 'ar';

      debugPrint(
        'AuthService initialized - id: $id, name: $name, email: $email, roleName: $roleName, isApproved: $isApproved, isCustomer: $isCustomer, isVerified: $isVerified',
      );
    } catch (e) {
      debugPrint('Error initializing auth: $e');
    }
  }

  /// Save authentication data after successful login
  /// Uses only: token, personId, email, fullName, role
  Future<void> saveAuthData({
    required String personId,
    required String authToken,
    String? userEmail,
    String? fullName,
    String? userRole,
    required String userRoleId,
    bool? companyWaiting,
    bool? approved,
    bool? isCustomerAcount,
    bool? verified,
    bool? companyAccount,
    bool? shippingCompanyAccount,
    String? userPhone,
    String? imagePath,
    bool clearSessionToken = false,
  }) async {
    debugPrint(
      'Saving auth data - personId: $personId, email: $userEmail, fullName: $fullName, role: $userRole, roleId: $userRoleId, token: $authToken',
    );

    try {
      // Save personId (mapped to 'personId' in cache, 'id' in cached_constants)
      if (personId.isNotEmpty) {
        await CachHelper.saveData(key: 'personId', value: personId);
        id = personId;
      }

      if (authToken.isNotEmpty) {
        await CachHelper.saveData(key: 'token', value: authToken);
        token = authToken;
      } else if (clearSessionToken) {
        await CachHelper.removeData('token');
        token = null;
        await AppChatListenerService.instance.stop();
      }

      // Save email
      if (userEmail != null) {
        await CachHelper.saveData(key: 'email', value: userEmail);
        // Update global email variable from cached_constants
        email = userEmail;
      }

      // Save fullName (mapped to 'fullName' in cache, 'name' in cached_constants)
      if (fullName != null) {
        await CachHelper.saveData(key: 'fullName', value: fullName);
        name = fullName;
      }

      // Save role (mapped to 'role' in cache, 'roleName' in cached_constants)
      if (userRole != null) {
        await CachHelper.saveData(key: 'role', value: userRole);
        roleName = userRole;
      }

      await CachHelper.saveData(key: 'roleId', value: userRoleId);
      roleId = userRoleId;

      if (companyWaiting != null) {
        await CachHelper.saveData(
          key: 'isCompanyWaiting',
          value: companyWaiting,
        );
      }
      if (approved != null) {
        await CachHelper.saveData(key: 'isApproved', value: approved);
        isApproved = approved;
      }
      // Always persist customer flag (default false) so MyAds gating stays reliable.
      final resolvedIsCustomer = isCustomerAcount ?? false;
      await CachHelper.saveData(key: 'isCustomer', value: resolvedIsCustomer);
      isCustomer = resolvedIsCustomer;
      if (verified != null) {
        await CachHelper.saveData(key: 'isVerified', value: verified);
        isVerified = verified;
      }
      if (companyAccount != null) {
        await CachHelper.saveData(
          key: 'isCompanyAccount',
          value: companyAccount,
        );
        isCompanyAccount = companyAccount;
      }
      if (shippingCompanyAccount != null) {
        await CachHelper.saveData(
          key: 'isShippingCompanyAccount',
          value: shippingCompanyAccount,
        );
        isShippingCompanyAccount = shippingCompanyAccount;
      }
      if (userPhone != null && userPhone.isNotEmpty) {
        await savePhone(userPhone);
      }
      if (imagePath != null) {
        await saveProfileImagePath(imagePath);
      }
    } catch (e) {
      debugPrint('Error saving auth data: $e');
      rethrow;
    }

    // Every login funnels through here, so this is where the device token gets
    // re-pointed at the account that just signed in.
    if (isAuthenticated) {
      unawaited(registerFcmToken());
    }
  }

  /// Binds the device push token to the signed-in account. Safe to call
  /// repeatedly — the backend releases the token from any previous owner.
  Future<void> registerFcmToken({String? fcmToken}) async {
    final authToken = currentToken;
    if (authToken == null || authToken.trim().isEmpty) return;

    try {
      final deviceToken =
          fcmToken ?? await FcmTokenService.instance.getToken();
      if (deviceToken.trim().isEmpty) {
        debugPrint('registerFcmToken skipped: no device token');
        return;
      }
      await DioHelper.postData(
        url: ApiConstants.updateFcmTokenEndPoint,
        data: {'fcmToken': deviceToken.trim()},
        token: authToken,
      );
      debugPrint('FCM token registered for user $id');
    } catch (e) {
      debugPrint('registerFcmToken skipped: $e');
    }
  }

  Future<void> setHasPassword(bool value) async {
    hasPassword = value;
    await CachHelper.saveData(key: 'hasPassword', value: value);
  }

  Future<void> setLoginProviderName(String? provider) async {
    final normalized = provider?.trim();
    if (normalized == null || normalized.isEmpty) return;
    loginProviderName = normalized;
    await CachHelper.saveData(key: 'loginProviderName', value: normalized);
  }

  Future<void> setCompanyWaiting(bool waiting) async {
    await CachHelper.saveData(key: 'isCompanyWaiting', value: waiting);
  }

  Future<void> savePhone(String userPhone) async {
    await CachHelper.saveData(key: 'phone', value: userPhone);
    phone = userPhone;
  }

  Future<void> saveProfileImagePath(String path) async {
    await CachHelper.saveData(key: 'userImagePath', value: path);
    userImagePath = path;
    profileImageRevision.value++;
    await CachHelper.saveData(
      key: 'userImageRevision',
      value: profileImageRevision.value,
    );
  }

  /// Update user profile data
  /// Uses only: email, fullName, role
  Future<void> updateProfileData({
    String? userEmail,
    String? fullName,
    String? userRole,
    String? imagePath,
  }) async {
    try {
      if (userEmail != null) {
        await CachHelper.saveData(key: 'email', value: userEmail);
        // Update global email variable from cached_constants
        email = userEmail;
      }
      if (fullName != null) {
        await CachHelper.saveData(key: 'fullName', value: fullName);
        name = fullName;
      }
      if (userRole != null) {
        await CachHelper.saveData(key: 'role', value: userRole);
        roleName = userRole;
      }
      if (imagePath != null) {
        await saveProfileImagePath(imagePath);
      }
    } catch (e) {
      debugPrint('Error updating profile data: $e');
      rethrow;
    }
  }

  /// Check if a route requires authentication
  bool requiresAuthentication(String? routeName) {
    const protectedRoutes = [
      '/homeView',
      '/ProfileView',
      '/EditProfileView',
      '/SettingsView',
      '/ManageAdsView',
      '/PostAdsView',
    ];
    return protectedRoutes.contains(routeName);
  }

  /// Check if a route requires admin privileges
  bool requiresAdmin(String? routeName) {
    const adminRoutes = ['/admin-dashboard', '/ManageAdsView'];
    return adminRoutes.contains(routeName);
  }

  /// Clear all authentication data
  Future<void> clearAuthData() async {
    NotificationsService.instance.resetForLogout();
    id = null;
    token = null;
    name = null;
    email = null;
    roleName = null;
    roleId = null;
    isApproved = null;
    isCustomer = null;
    isVerified = null;
    isCompanyAccount = null;
    phone = null;
    userImagePath = null;
    hasPassword = null;
    loginProviderName = null;
    profileImageRevision.value = 0;

    // Remove only the auth-related keys
    await CachHelper.removeData('personId');
    await CachHelper.removeData('token');
    await CachHelper.removeData('email');
    await CachHelper.removeData('fullName');
    await CachHelper.removeData('role');
    await CachHelper.removeData('roleId');
    await CachHelper.removeData('isCompanyWaiting');
    await CachHelper.removeData('isApproved');
    await CachHelper.removeData('isCustomer');
    await CachHelper.removeData('isVerified');
    await CachHelper.removeData('isCompanyAccount');
    await CachHelper.removeData('phone');
    await CachHelper.removeData('userImagePath');
    await CachHelper.removeData('userImageRevision');
    await CachHelper.removeData('hasPassword');
    await CachHelper.removeData('loginProviderName');

    debugPrint('Auth data cleared');
  }

  // Logout — keeps a biometric session snapshot when Face ID / fingerprint is on.
  Future<void> logout() async {
    await BiometricAuthService.instance.stashSessionBeforeLogout();
    await _clearFcmTokenOnServer();
    await AppChatListenerService.instance.stop();
    await ApiCacheStore.instance.invalidateUserData();
    await clearAuthData();
    debugPrint('User logged out');
  }

  Future<void> _clearFcmTokenOnServer() async {
    final token = currentToken;
    if (token == null || token.trim().isEmpty) return;
    try {
      await DioHelper.postData(
        url: ApiConstants.clearFcmTokenEndPoint,
        data: const {},
        token: token,
      );
    } catch (e) {
      debugPrint('clearFcmToken skipped: $e');
    }
  }

  /// Validates cached session against the API (rejected/suspended users).
  Future<bool> validateSession() async {
    if (!isAuthenticated) return true;

    try {
      final response = await DioHelper.getData(
        url: ApiConstants.userProfileEndPoint,
        token: currentToken,
      );
      final status = response?.statusCode ?? 0;
      if (status == 401 || status == 403) {
        await clearAuthData();
        return false;
      }
      if (status == 200 && response?.data is Map) {
        final data = response!.data as Map;
        if (data['isRejected'] == true || data['IsRejected'] == true) {
          await clearAuthData();
          return false;
        }
        final passwordFlag = data['hasPassword'] ?? data['HasPassword'];
        if (passwordFlag is bool) {
          await setHasPassword(passwordFlag);
        }
        await setLoginProviderName(
          (data['loginProviderName'] ?? data['LoginProviderName'])?.toString(),
        );
      }

      // Restored sessions never hit the login endpoint, so refresh the token here.
      unawaited(registerFcmToken());
      return true;
    } catch (e) {
      debugPrint('Session validation skipped: $e');
      return true;
    }
  }
}
