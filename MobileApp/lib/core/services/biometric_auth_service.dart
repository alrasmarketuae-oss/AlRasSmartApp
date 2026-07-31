import 'dart:convert';

import 'package:alrasmarket/core/helper/cach_helper.dart';
import 'package:alrasmarket/core/serveses/auth_service.dart';
import 'package:alrasmarket/core/serveses/cached_constants.dart' as cache;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';

/// Face ID / fingerprint unlock for accounts that already signed in once.
///
/// Does not replace email/Google/Apple signup — it only restores a previously
/// saved session after a successful local biometric check.
class BiometricAuthService {
  BiometricAuthService._();
  static final BiometricAuthService instance = BiometricAuthService._();

  static const _enabledKey = 'biometric_unlock_enabled';
  static const _sessionKey = 'biometric_session_v1';
  static const _promptedPrefix = 'biometric_prompted_';

  static const _secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  final LocalAuthentication _auth = LocalAuthentication();

  Future<bool> get isDeviceSupported async {
    try {
      final canCheck = await _auth.canCheckBiometrics;
      final isSupported = await _auth.isDeviceSupported();
      return canCheck || isSupported;
    } catch (_) {
      return false;
    }
  }

  Future<bool> get hasEnrolledBiometrics async {
    try {
      final types = await _auth.getAvailableBiometrics();
      return types.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  bool get isEnabled => CachHelper.getData(_enabledKey) == true;

  String? get _currentAccountPromptKey {
    final userId = AuthService.instance.currentUserID?.trim().toLowerCase();
    if (userId == null || userId.isEmpty) return null;
    return '$_promptedPrefix$userId';
  }

  /// Prompt only once for each account on this app installation.
  bool get wasPromptedForCurrentAccount {
    final key = _currentAccountPromptKey;
    return key != null && CachHelper.getData(key) == true;
  }

  Future<void> markCurrentAccountPrompted() async {
    final key = _currentAccountPromptKey;
    if (key == null) return;
    await CachHelper.saveData(key: key, value: true);
  }

  /// True when a previous account opted in and a session snapshot still exists.
  Future<bool> get canOfferUnlock async {
    if (!isEnabled) return false;
    if (!await isDeviceSupported) return false;
    final snapshot = await _secureStorage.read(key: _sessionKey);
    return snapshot != null && snapshot.trim().isNotEmpty;
  }

  Future<String?> get savedAccountEmail async {
    final raw = await _secureStorage.read(key: _sessionKey);
    if (raw == null || raw.isEmpty) return null;
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return map['email']?.toString();
    } catch (_) {
      return null;
    }
  }

  /// Prefer Face ID wording on iOS when strong biometrics are available.
  Future<String> preferredLabel({
    required String faceId,
    required String fingerprint,
    required String generic,
  }) async {
    try {
      final types = await _auth.getAvailableBiometrics();
      if (types.contains(BiometricType.face)) return faceId;
      if (types.contains(BiometricType.fingerprint) ||
          types.contains(BiometricType.strong) ||
          types.contains(BiometricType.weak)) {
        return fingerprint;
      }
    } catch (_) {}
    return generic;
  }

  Future<bool> authenticate({required String localizedReason}) async {
    try {
      return await _auth.authenticate(
        localizedReason: localizedReason,
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
          useErrorDialogs: true,
        ),
      );
    } on PlatformException catch (e) {
      debugPrint('Biometric authenticate error: ${e.code} ${e.message}');
      return false;
    } catch (e) {
      debugPrint('Biometric authenticate error: $e');
      return false;
    }
  }

  /// Turns biometric unlock on for the currently signed-in account.
  Future<bool> enableForCurrentSession({required String reason}) async {
    final auth = AuthService.instance;
    if (!auth.isAuthenticated) return false;
    if (!await isDeviceSupported) return false;
    if (!await hasEnrolledBiometrics) return false;

    final ok = await authenticate(localizedReason: reason);
    if (!ok) return false;

    await _writeSessionSnapshot();
    await CachHelper.saveData(key: _enabledKey, value: true);
    return true;
  }

  Future<void> disable() async {
    await CachHelper.saveData(key: _enabledKey, value: false);
    await _secureStorage.delete(key: _sessionKey);
  }

  /// Keep the snapshot fresh while biometric unlock stays enabled.
  Future<void> refreshSnapshotIfEnabled() async {
    if (!isEnabled) return;
    if (!AuthService.instance.isAuthenticated) return;
    await _writeSessionSnapshot();
  }

  /// Called from logout: persist the live session before clearing it.
  Future<void> stashSessionBeforeLogout() async {
    if (!isEnabled) return;
    if (!AuthService.instance.isAuthenticated) return;
    await _writeSessionSnapshot();
  }

  /// Biometric success → restore the saved session into [AuthService].
  Future<bool> unlockAndRestoreSession({required String reason}) async {
    if (!await canOfferUnlock) return false;

    final ok = await authenticate(localizedReason: reason);
    if (!ok) return false;

    final raw = await _secureStorage.read(key: _sessionKey);
    if (raw == null || raw.isEmpty) return false;

    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      final personId = map['personId']?.toString() ?? '';
      final authToken = map['token']?.toString() ?? '';
      if (personId.isEmpty || authToken.isEmpty) return false;

      await AuthService.instance.saveAuthData(
        personId: personId,
        authToken: authToken,
        userEmail: map['email']?.toString(),
        fullName: map['fullName']?.toString(),
        userRole: map['role']?.toString(),
        userRoleId: map['roleId']?.toString() ?? '',
        approved: map['isApproved'] as bool?,
        isCustomerAcount: map['isCustomer'] as bool?,
        verified: map['isVerified'] as bool?,
        companyAccount: map['isCompanyAccount'] as bool?,
        shippingCompanyAccount: map['isShippingCompanyAccount'] as bool?,
        userPhone: map['phone']?.toString(),
        imagePath: map['userImagePath']?.toString(),
      );

      final hasPassword = map['hasPassword'];
      if (hasPassword is bool) {
        await AuthService.instance.setHasPassword(hasPassword);
      }
      final provider = map['loginProviderName']?.toString();
      if (provider != null && provider.isNotEmpty) {
        await AuthService.instance.setLoginProviderName(provider);
      }

      await AuthService.instance.setChatKeyWrapFromCredentials(
        email: AuthService.instance.currentUserEmail,
        userId: AuthService.instance.currentUserID,
      );

      return AuthService.instance.isAuthenticated;
    } catch (e) {
      debugPrint('Biometric restore failed: $e');
      return false;
    }
  }

  Future<void> _writeSessionSnapshot() async {
    final auth = AuthService.instance;
    final token = auth.currentToken;
    final personId = auth.currentUserID;
    if (token == null || token.isEmpty || personId == null || personId.isEmpty) {
      return;
    }

    final payload = <String, dynamic>{
      'personId': personId,
      'token': token,
      'email': auth.currentUserEmail,
      'fullName': auth.currentUserName,
      'role': auth.currentUserRoleName,
      'roleId': auth.currentUserRoleId,
      'isApproved': cache.isApproved,
      'isCustomer': cache.isCustomer,
      'isVerified': cache.isVerified,
      'isCompanyAccount': cache.isCompanyAccount,
      'isShippingCompanyAccount': cache.isShippingCompanyAccount,
      'phone': auth.currentUserPhone,
      'userImagePath': auth.currentUserImagePath,
      'hasPassword': auth.hasPassword,
      'loginProviderName': auth.loginProviderName,
    };

    await _secureStorage.write(key: _sessionKey, value: jsonEncode(payload));
  }
}
