import 'dart:io';

import 'package:alrasmarket/core/services/app_push_notification_service.dart';
import 'package:alrasmarket/firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

class FcmTokenService {
  FcmTokenService._();

  static final FcmTokenService instance = FcmTokenService._();

  String? _cachedToken;
  bool _initialized = false;

  /// Firebase init + token listeners only. Do NOT request Android notification
  /// permission here — Activity is not ready during [main] before [runApp].
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
      }

      if (Platform.isIOS) {
        await _requestIosPermission();
      }

      _cachedToken = await _fetchToken();

      FirebaseMessaging.instance.onTokenRefresh.listen((token) {
        _cachedToken = token;
        debugPrint('FCM token refreshed: $token');
      });

      _initialized = true;
      debugPrint('FcmTokenService initialized. token=$_cachedToken');
    } catch (e, stackTrace) {
      debugPrint('FcmTokenService initialize failed: $e');
      debugPrint('$stackTrace');
    }
  }

  /// Call after the first Flutter frame / on app resume.
  /// Uses the initialized local-notifications plugin (required on many tablets).
  Future<bool> ensurePermission() async {
    if (!_initialized) {
      await initialize();
    }

    if (Platform.isIOS) {
      await _requestIosPermission();
      _cachedToken = await _fetchToken();
      return true;
    }

    if (!Platform.isAndroid) return true;

    final granted =
        await AppPushNotificationService.instance
            .requestAndroidNotificationPermission();
    _cachedToken = await _fetchToken();
    return granted;
  }

  Future<void> _requestIosPermission() async {
    final settings = await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    debugPrint('FCM iOS permission: ${settings.authorizationStatus}');
  }

  /// Call before login/register to ensure the latest device token is sent.
  Future<String> refreshForAuth() async {
    if (!_initialized) {
      await initialize();
    }
    await ensurePermission();
    _cachedToken = await _fetchToken();
    return _cachedToken ?? '';
  }

  Future<String> getToken() async {
    if (!_initialized) {
      await initialize();
    }

    if (_cachedToken != null && _cachedToken!.isNotEmpty) {
      return _cachedToken!;
    }

    try {
      _cachedToken = await _fetchToken().timeout(
        const Duration(seconds: 8),
        onTimeout: () {
          debugPrint('FCM getToken timed out');
          return null;
        },
      );
    } catch (e, stackTrace) {
      debugPrint('FCM getToken failed: $e');
      debugPrint('$stackTrace');
      _cachedToken = null;
    }
    return _cachedToken ?? '';
  }

  Future<String?> _fetchToken() async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      debugPrint('FCM getToken result: $token');
      return token;
    } catch (e, stackTrace) {
      debugPrint('FCM getToken failed: $e');
      debugPrint('$stackTrace');
      return null;
    }
  }
}
