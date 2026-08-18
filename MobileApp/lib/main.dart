import 'package:alrasmarket/alrasmarket.dart';
import 'dart:async';
import 'package:alrasmarket/core/cache/api_cache_store.dart';
import 'package:alrasmarket/core/helper/cach_helper.dart';
import 'package:alrasmarket/core/serveses/auth_service.dart';
import 'package:alrasmarket/core/serveses/product_search_index_service.dart';
import 'package:alrasmarket/core/services/app_push_notification_service.dart';
import 'package:alrasmarket/core/services/fcm_token_service.dart';
import 'package:alrasmarket/core/services/dio_helper.dart';
import 'package:alrasmarket/core/services_locator/services_locator.dart';
import 'package:alrasmarket/features/company/presentation/services/create_ad_publish_queue.dart';
import 'package:alrasmarket/features/auth/presentation/controller/cubit/auth_cubit.dart';
import 'package:alrasmarket/core/media/image_picker_config.dart';
import 'package:alrasmarket/core/utils/media_http_overrides.dart';
import 'package:alrasmarket/core/theme/theme_controller.dart';
import 'package:alrasmarket/core/utils/status_bar_helper.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  configureImagePicker();
  if (!kIsWeb) {
    configureMediaHttpOverrides();
  }
  await ScreenUtil.ensureScreenSize();
  await CachHelper.init();
  await ThemeController.instance.load();
  try {
    await ApiCacheStore.instance.init();
  } catch (e) {
    debugPrint('ApiCacheStore init skipped: $e');
  }
  DioHelper.init();

  // Initialize Services Locator
  ServicesLocator().init();

  await ProductSearchIndexService.instance.init();

  // Firebase + FCM bootstrap only — never block splash on APNs/permission.
  await FcmTokenService.instance.initialize();
  await AppPushNotificationService.instance.initialize();

  // Local auth cache only (no network) so first frame can paint quickly.
  await AuthService.instance.initializeAuth();

  // Network session checks must not keep the native splash up on iOS.
  unawaited(_startAuthenticatedSideEffects());

  // Defer ad-upload resume so FFmpeg (if a pending video job exists) never
  // contends with splash dismiss / first home frame.
  unawaited(_resumePendingAdUploadsAfterUiReady());

  // Set default status bar style for the entire app
  StatusBarHelper.setAppDefaultStatusBar();
  runApp(const AlRasMarket());
}

Future<void> _resumePendingAdUploadsAfterUiReady() async {
  if (kIsWeb) return;
  // Wait for first frames + a short settle; FFmpeg is heavy on cold start.
  await Future<void>.delayed(const Duration(seconds: 3));
  try {
    await CreateAdPublishQueue.instance.restoreAndResume();
  } catch (e) {
    debugPrint('CreateAdPublishQueue restore skipped: $e');
  }
}

Future<void> _startAuthenticatedSideEffects() async {
  try {
    await AuthService.instance
        .validateSession()
        .timeout(const Duration(seconds: 8));
  } catch (e) {
    debugPrint('validateSession skipped at startup: $e');
  }

  if (AuthService.instance.isAuthenticated) {
    unawaited(sl<AuthCubit>().syncPreferredLanguageWithBackend());
  }
}
