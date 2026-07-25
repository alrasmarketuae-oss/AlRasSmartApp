import 'package:alrasmarket/alrasmarket.dart';
import 'dart:async';
import 'package:alrasmarket/core/cache/api_cache_store.dart';
import 'package:alrasmarket/core/helper/cach_helper.dart';
import 'package:alrasmarket/core/serveses/auth_service.dart';
import 'package:alrasmarket/core/serveses/app_chat_listener_service.dart';
import 'package:alrasmarket/core/serveses/product_search_index_service.dart';
import 'package:alrasmarket/core/services/app_push_notification_service.dart';
import 'package:alrasmarket/core/services/fcm_token_service.dart';
import 'package:alrasmarket/core/services/dio_helper.dart';
import 'package:alrasmarket/core/services_locator/services_locator.dart';
import 'package:alrasmarket/features/company/presentation/services/create_ad_publish_queue.dart';
import 'package:alrasmarket/features/auth/presentation/controller/cubit/auth_cubit.dart';
import 'package:alrasmarket/core/media/image_picker_config.dart';
import 'package:alrasmarket/core/utils/media_http_overrides.dart';
import 'package:alrasmarket/core/utils/status_bar_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  configureImagePicker();
  configureMediaHttpOverrides();
  await ScreenUtil.ensureScreenSize();
  await CachHelper.init();
  await ApiCacheStore.instance.init();
  DioHelper.init();

  // Initialize Services Locator
  ServicesLocator().init();

  await ProductSearchIndexService.instance.init();

  // Firebase + FCM (required before login/register send fcmToken)
  await FcmTokenService.instance.initialize();
  await AppPushNotificationService.instance.initialize();

  // Initialize Auth Service
  await AuthService.instance.initializeAuth();
  await AuthService.instance.validateSession();
  if (AuthService.instance.isAuthenticated) {
    unawaited(AppChatListenerService.instance.start());
  }
  await sl<AuthCubit>().syncPreferredLanguageWithBackend();

  // Resume any ad uploads that were interrupted when the app was killed.
  unawaited(CreateAdPublishQueue.instance.restoreAndResume());

  // Set default status bar style for the entire app
  StatusBarHelper.setAppDefaultStatusBar();
  runApp(const AlRasMarket());
}
