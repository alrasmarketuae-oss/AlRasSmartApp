import 'dart:async';
import 'dart:ui';

import 'package:alrasmarket/core/cache/api_cache_store.dart';
import 'package:alrasmarket/core/helper/cach_helper.dart';
import 'package:alrasmarket/core/services/dio_helper.dart';
import 'package:alrasmarket/core/services_locator/services_locator.dart';
import 'package:alrasmarket/features/company/data/datasource/product_remote_data_source.dart';
import 'package:alrasmarket/features/company/data/repository/product_repository.dart';
import 'package:alrasmarket/features/company/domain/repository/base_product_repository.dart';
import 'package:alrasmarket/features/company/domain/usecases/create_ad_usecases.dart';
import 'package:alrasmarket/features/company/presentation/services/create_ad_publish_queue.dart';
import 'package:alrasmarket/features/company/presentation/services/create_ad_publish_store.dart';
import 'package:alrasmarket/generated/l10n.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';

/// Keeps create-ad compress/upload alive after the user leaves or swipes the app.
///
/// All heavy work (compress + API) runs in this FG isolate so leaving the UI
/// does not cancel an in-flight main-isolate drain holding the disk lock.
class CreateAdPublishForeground {
  CreateAdPublishForeground._();

  static const _serviceId = 2741;
  static bool _initialized = false;
  static bool _listening = false;

  static Future<void> init() async {
    if (_initialized) return;
    FlutterForegroundTask.initCommunicationPort();
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'create_ad_upload',
        channelName: 'Ad uploads',
        channelDescription: 'Shows while an ad is compressing and uploading',
        onlyAlertOnce: true,
      ),
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: true,
        playSound: false,
      ),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.repeat(3000),
        autoRunOnBoot: false,
        autoRunOnMyPackageReplaced: false,
        allowWakeLock: true,
        allowWifiLock: true,
        stopWithTask: false,
      ),
    );
    _initialized = true;
  }

  static void listenForTaskData() {
    if (_listening) return;
    _listening = true;
    FlutterForegroundTask.addTaskDataCallback(_onTaskData);
  }

  static void _onTaskData(Object data) {
    if (data is! Map) return;
    final type = data['type']?.toString();
    final message = data['message']?.toString();
    if (type == 'error' && message != null && message.isNotEmpty) {
      CreateAdPublishQueue.instance.showUiError(message);
    }
  }

  /// Persist is already done — start FG worker that owns compress+upload.
  static Future<void> ensureStarted() async {
    await init();
    try {
      await FlutterForegroundTask.requestNotificationPermission();
    } catch (_) {}

    if (await FlutterForegroundTask.isRunningService) {
      await FlutterForegroundTask.updateService(
        notificationTitle: _title(),
        notificationText: _text(),
      );
      FlutterForegroundTask.sendDataToTask('drain');
      return;
    }

    final result = await FlutterForegroundTask.startService(
      serviceId: _serviceId,
      notificationTitle: _title(),
      notificationText: _text(),
      callback: createAdPublishFgCallback,
      serviceTypes: const [ForegroundServiceTypes.dataSync],
    );
    debugPrint('[CreateAdPublishFG] startService => $result');
  }

  /// Update the FG notification from the main isolate while media uploads.
  static Future<void> updateProgress(String text) async {
    try {
      if (!await FlutterForegroundTask.isRunningService) return;
      await FlutterForegroundTask.updateService(
        notificationTitle: _title(),
        notificationText: text,
      );
    } catch (e) {
      debugPrint('[CreateAdPublishFG] updateProgress skipped: $e');
    }
  }

  static Future<void> stopIfIdle() async {
    final pending = await CreateAdPublishStore.instance.count();
    if (pending > 0) return;
    if (await FlutterForegroundTask.isRunningService) {
      await FlutterForegroundTask.stopService();
    }
  }

  static String _title() {
    try {
      return S.current.adUploadNotificationTitle;
    } catch (_) {
      return 'Uploading ad';
    }
  }

  static String _text() {
    try {
      return S.current.adUploadNotificationText;
    } catch (_) {
      return 'Compressing and uploading in the background';
    }
  }

  /// Lightweight DI for the FG isolate — avoids full app ServicesLocator failures.
  static void registerMinimalUploadDependencies() {
    if (!sl.isRegistered<BaseProductRemoteDataSource>()) {
      sl.registerLazySingleton<BaseProductRemoteDataSource>(
        () => ProductRemoteDataSource(),
      );
    }
    if (!sl.isRegistered<BaseProductRepository>()) {
      sl.registerLazySingleton<BaseProductRepository>(
        () => ProductRepository(remote: sl()),
      );
    }
    if (!sl.isRegistered<CreateProductUseCase>()) {
      sl.registerLazySingleton(() => CreateProductUseCase(sl()));
    }
    if (!sl.isRegistered<UpdateProductUseCase>()) {
      sl.registerLazySingleton(() => UpdateProductUseCase(sl()));
    }
    if (!sl.isRegistered<UploadProductImagesUseCase>()) {
      sl.registerLazySingleton(() => UploadProductImagesUseCase(sl()));
    }
    if (!sl.isRegistered<UploadProductDocumentsUseCase>()) {
      sl.registerLazySingleton(() => UploadProductDocumentsUseCase(sl()));
    }
    if (!sl.isRegistered<UploadProductVideoUseCase>()) {
      sl.registerLazySingleton(() => UploadProductVideoUseCase(sl()));
    }
    if (!sl.isRegistered<SubmitProductForAdminReviewUseCase>()) {
      sl.registerLazySingleton(() => SubmitProductForAdminReviewUseCase(sl()));
    }
  }
}

@pragma('vm:entry-point')
void createAdPublishFgCallback() {
  FlutterForegroundTask.setTaskHandler(CreateAdPublishTaskHandler());
}

class CreateAdPublishTaskHandler extends TaskHandler {
  bool _bootstrapped = false;
  bool _draining = false;
  Timer? _heartbeat;

  Future<void> _bootstrap() async {
    if (_bootstrapped) return;
    WidgetsFlutterBinding.ensureInitialized();
    DartPluginRegistrant.ensureInitialized();
    await CachHelper.init();
    await ApiCacheStore.instance.init();
    DioHelper.init();
    CreateAdPublishForeground.registerMinimalUploadDependencies();
    final lang = CachHelper.getData('languageCode')?.toString() ?? 'ar';
    try {
      await S.load(Locale(lang));
    } catch (_) {}
    _bootstrapped = true;
    debugPrint('[CreateAdPublishFG] bootstrap ok');
  }

  void _startHeartbeat() {
    _heartbeat?.cancel();
    _heartbeat = Timer.periodic(const Duration(seconds: 8), (_) {
      unawaited(CreateAdPublishStore.instance.heartbeatProcessingLock());
    });
  }

  void _stopHeartbeat() {
    _heartbeat?.cancel();
    _heartbeat = null;
  }

  Future<void> _drain() async {
    if (_draining) return;
    _draining = true;
    _startHeartbeat();
    try {
      await _bootstrap();
      await CreateAdPublishQueue.instance.drainFromDisk(
        onProgress: (remaining) async {
          await CreateAdPublishStore.instance.heartbeatProcessingLock();
          await FlutterForegroundTask.updateService(
            notificationTitle: CreateAdPublishForeground._title(),
            notificationText: remaining <= 1
                ? CreateAdPublishForeground._text()
                : '${CreateAdPublishForeground._text()} ($remaining)',
          );
        },
      );
    } catch (e, st) {
      debugPrint('[CreateAdPublishFG] drain failed: $e\n$st');
      try {
        await FlutterForegroundTask.updateService(
          notificationTitle: CreateAdPublishForeground._title(),
          notificationText: 'Upload paused — reopen the app to retry',
        );
      } catch (_) {}
    } finally {
      _stopHeartbeat();
      _draining = false;
      final pending = await CreateAdPublishStore.instance.count();
      if (pending == 0) {
        await FlutterForegroundTask.stopService();
      }
    }
  }

  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    debugPrint('[CreateAdPublishFG] onStart');
    // Give the main isolate a head start so it owns compress/upload
    // (FFmpeg plugins are unreliable in the FG callback isolate).
    await Future<void>.delayed(const Duration(seconds: 3));
    await _drain();
  }

  @override
  void onRepeatEvent(DateTime timestamp) {
    unawaited(_drain());
  }

  @override
  Future<void> onDestroy(DateTime timestamp, bool isTimeout) async {
    _stopHeartbeat();
    await CreateAdPublishStore.instance.releaseProcessingLock();
  }

  @override
  void onReceiveData(Object data) {
    if (data == 'drain') {
      unawaited(_drain());
    }
  }
}
