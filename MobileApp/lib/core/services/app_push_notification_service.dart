import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:alrasmarket/core/router/app_router.dart';
import 'package:alrasmarket/core/services/notification_alert_sound.dart';
import 'package:alrasmarket/core/serveses/catalog_sync_service.dart';
import 'package:alrasmarket/core/serveses/notifications_service.dart';
import 'package:alrasmarket/core/serveses/profile_service.dart';
import 'package:alrasmarket/core/services_locator/services_locator.dart';
import 'package:alrasmarket/core/ui/widgets/feedback/in_app_notification_service.dart';
import 'package:alrasmarket/features/clint/data/models/app_notification_model.dart';
import 'package:alrasmarket/features/clint/presentation/controller/cubit/clint_cubit.dart';
import 'package:alrasmarket/features/clint/presentation/helpers/notification_navigation_helper.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart' hide Priority;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('Background FCM: ${message.data}');
}

class AppPushNotificationService {
  AppPushNotificationService._();

  static final AppPushNotificationService instance =
      AppPushNotificationService._();

  /// Channel id must match FCM `android.notification.channel_id`.
  static const androidChannelId = 'app_alerts';
  static const _androidChannelName = 'App alerts';
  static const _androidChannelDescription =
      'Messages, orders, and other alerts';
  static const _androidSoundName = 'notification_ding';

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;
  bool _androidPermissionPromptCompleted = false;
  Map<String, dynamic>? _pendingNavigationData;
  bool _pendingNavigationHandled = false;
  String? _lastAlertKey;
  DateTime? _lastAlertAt;

  Future<void> initialize() async {
    if (_initialized) return;

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();
    await _localNotifications.initialize(
      const InitializationSettings(android: androidInit, iOS: iosInit),
      onDidReceiveNotificationResponse: _onLocalNotificationTap,
    );

    final androidPlugin =
        _localNotifications
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();
    // Do not request permission here — main() runs before Activity is ready.
    // Use [requestAndroidNotificationPermission] after the first frame / on resume.
    await androidPlugin?.createNotificationChannel(
      const AndroidNotificationChannel(
        androidChannelId,
        _androidChannelName,
        description: _androidChannelDescription,
        importance: Importance.high,
        playSound: true,
        sound: RawResourceAndroidNotificationSound(_androidSoundName),
      ),
    );

    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    FirebaseMessaging.onMessage.listen(_onForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_onNotificationOpened);

    // iOS: show system banner while app is foreground (matches Android tray UX).
    if (Platform.isIOS) {
      await FirebaseMessaging.instance
          .setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );
    }

    try {
      final initialMessage = await FirebaseMessaging.instance
          .getInitialMessage()
          .timeout(const Duration(seconds: 3));
      if (initialMessage != null) {
        _pendingNavigationData = initialMessage.data;
      }
    } catch (e) {
      debugPrint('getInitialMessage skipped: $e');
    }

    // Cold-start tap on a local notification (common on iOS).
    try {
      final launch = await _localNotifications
          .getNotificationAppLaunchDetails()
          .timeout(const Duration(seconds: 3));
      final response = launch?.notificationResponse;
      if (launch?.didNotificationLaunchApp == true &&
          response?.payload != null &&
          response!.payload!.isNotEmpty &&
          _pendingNavigationData == null) {
        final decoded = jsonDecode(response.payload!) as Map<String, dynamic>;
        _pendingNavigationData = decoded;
      }
    } catch (e) {
      debugPrint('getNotificationAppLaunchDetails skipped: $e');
    }

    _initialized = true;
    debugPrint('AppPushNotificationService initialized');
  }

  /// Android 13+ POST_NOTIFICATIONS dialog. Must use the initialized plugin and a
  /// resumed Activity (phones often work earlier; tablets need resume + retries).
  Future<bool> requestAndroidNotificationPermission({
    int maxAttempts = 4,
  }) async {
    if (!_initialized) {
      await initialize();
    }

    if (!Platform.isAndroid) {
      return true;
    }

    if (_androidPermissionPromptCompleted) {
      return true;
    }

    final android = _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    if (android == null) {
      debugPrint('FCM: Android local-notifications plugin unavailable');
      return false;
    }

    for (var attempt = 1; attempt <= maxAttempts; attempt++) {
      try {
        final enabled = await android.areNotificationsEnabled();
        debugPrint(
          'FCM Android notifications enabled (attempt $attempt): $enabled',
        );
        if (enabled == true) {
          _androidPermissionPromptCompleted = true;
          return true;
        }

        // Wait longer on later attempts — tablets often resume Activity late.
        await Future<void>.delayed(
          Duration(milliseconds: 350 * attempt),
        );

        final granted = await android.requestNotificationsPermission();
        debugPrint(
          'FCM Android permission dialog result (attempt $attempt): $granted',
        );

        // Keep Firebase in sync with the OS permission state.
        final settings = await FirebaseMessaging.instance.requestPermission(
          alert: true,
          badge: true,
          sound: true,
        );
        debugPrint(
          'FCM Firebase authorization (attempt $attempt): '
          '${settings.authorizationStatus}',
        );

        final enabledAfter = await android.areNotificationsEnabled();
        if (granted == true ||
            enabledAfter == true ||
            settings.authorizationStatus == AuthorizationStatus.authorized ||
            settings.authorizationStatus == AuthorizationStatus.provisional) {
          _androidPermissionPromptCompleted = true;
          return true;
        }

        // granted == null usually means Activity was not ready — retry.
        if (granted == false) {
          // User denied — do not keep prompting this session.
          _androidPermissionPromptCompleted = true;
          return false;
        }
      } catch (e, st) {
        debugPrint('FCM permission attempt $attempt failed: $e');
        debugPrint('$st');
      }
    }

    return false;
  }

  /// Shows a system notification and in-app banner while the app is open.
  Future<void> showForegroundAlert({
    required String title,
    required String body,
    Map<String, dynamic> data = const {},
    VoidCallback? onTap,
    bool showInAppBanner = true,
  }) async {
    if (_isDuplicateAlert(title, body, data)) return;

    // Same ding as the admin web dashboard (foreground path).
    unawaited(NotificationAlertSound.instance.playOnce());

    if (showInAppBanner) {
      _runWhenRouterReady(() {
        InAppNotificationService.instance.show(
          title: title,
          body: body,
          onTap: onTap,
          playSound: false,
        );
      });
    }

    // System tray notification even while the app is open (silent here;
    // sound is played above so it matches the web asset exactly).
    await _showLocalNotificationParts(
      title: title,
      body: body,
      data: data,
      playSound: false,
    );
  }

  void handlePendingNavigation() {
    if (_pendingNavigationHandled) return;
    final data = _pendingNavigationData;
    if (data == null) return;
    _pendingNavigationHandled = true;
    _pendingNavigationData = null;
    _handleNotificationData(data, navigate: true);
  }

  void _onForegroundMessage(RemoteMessage message) {
    _refreshOrderFromData(message.data);
    unawaited(_refreshProfileFromData(message.data));
    unawaited(NotificationsService.instance.refreshUnreadCount());

    final notification = message.notification;
    final title =
        notification?.title ??
        message.data['title']?.toString() ??
        'Al Ras Smart App';
    final body =
        notification?.body ?? message.data['body']?.toString() ?? '';
    final data = Map<String, dynamic>.from(message.data);

    unawaited(
      showForegroundAlert(
        title: title,
        body: body,
        data: data,
        onTap: () => _navigateFromNotificationData(data),
      ),
    );
  }

  void _onNotificationOpened(RemoteMessage message) {
    _handleNotificationData(message.data, navigate: true);
  }

  void _onLocalNotificationTap(NotificationResponse response) {
    final payload = response.payload;
    if (payload == null || payload.isEmpty) return;

    try {
      final data = jsonDecode(payload) as Map<String, dynamic>;
      _handleNotificationData(data, navigate: true);
    } catch (e) {
      debugPrint('Invalid notification payload: $e');
    }
  }

  Future<void> _showLocalNotificationParts({
    required String title,
    required String body,
    Map<String, dynamic> data = const {},
    bool playSound = true,
  }) async {
    final payload = jsonEncode(data);

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          androidChannelId,
          _androidChannelName,
          channelDescription: _androidChannelDescription,
          importance: Importance.high,
          priority: Priority.high,
          playSound: playSound,
          sound: playSound
              ? const RawResourceAndroidNotificationSound(_androidSoundName)
              : null,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: playSound,
          sound: playSound ? 'notification_ding.mp3' : null,
        ),
      ),
      payload: payload,
    );
  }

  bool _isDuplicateAlert(
    String title,
    String body,
    Map<String, dynamic> data,
  ) {
    final referenceId =
        (data['referenceId'] ?? data['ReferenceId'] ?? data['messageId'] ?? '')
            .toString();
    final key =
        referenceId.isNotEmpty ? 'ref:$referenceId' : '$title|$body';
    final now = DateTime.now();
    if (_lastAlertKey == key &&
        _lastAlertAt != null &&
        now.difference(_lastAlertAt!) < const Duration(seconds: 3)) {
      return true;
    }
    _lastAlertKey = key;
    _lastAlertAt = now;
    return false;
  }

  void _refreshOrderFromData(Map<String, dynamic> data) {
    final type =
        (data['type'] ?? data['Type'] ?? '').toString().toLowerCase();
    final routeId =
        (data['routeId'] ?? data['RouteId'] ?? '').toString().toLowerCase();

    if (_isIncomingOrderNotification(type)) {
      final cubit = sl<ClintCubit>();
      unawaited(Future.wait([
        cubit.fetchIncomingOrders(silent: true),
        cubit.fetchMyOrders(silent: true),
      ]));
      return;
    }

    if (_isProductCatalogNotification(type, routeId)) {
      unawaited(CatalogSyncService.instance.onProductNotification());
      return;
    }

    final orderId = _parseOrderId(data);
    final cubit = sl<ClintCubit>();
    if (orderId != null) {
      unawaited(cubit.refreshOrderById(orderId));
      unawaited(cubit.fetchIncomingOrders(silent: true));
      return;
    }
    // Chat / non-order pushes should not force a full orders refresh.
    if (type.contains('chat')) return;
    unawaited(Future.wait([
      cubit.fetchIncomingOrders(silent: true),
      cubit.fetchMyOrders(silent: true),
    ]));
  }

  Future<void> _refreshProfileFromData(Map<String, dynamic> data) async {
    final type =
        (data['type'] ?? data['Type'] ?? '').toString().toLowerCase();
    final routeId =
        (data['routeId'] ?? data['RouteId'] ?? '').toString().toLowerCase();

    final isProfileDecision =
        type.contains('company_profile_approved') ||
        type.contains('company_profile_rejected') ||
        type.contains('shipping_company_profile_approved') ||
        type.contains('shipping_company_profile_rejected') ||
        type == 'company_approved' ||
        type == 'shipping_company_approved' ||
        type == 'company_rejected' ||
        type == 'shipping_company_rejected' ||
        routeId == 'profile';

    if (!isProfileDecision) return;

    try {
      await ProfileService.instance.fetchMyProfile(forceRefresh: true);
    } catch (e) {
      debugPrint('Failed to refresh profile after approval push: $e');
    }
  }

  bool _isIncomingOrderNotification(String type) {
    return type == 'new_order' ||
        type == 'request_offer' ||
        type == 'order' ||
        type == 'product_order' ||
        type == 'order_placed' ||
        type == 'order_created' ||
        type.contains('order_status');
  }

  bool _isProductCatalogNotification(String type, String routeId) {
    if (type == 'request_offer' || routeId == 'my_ads') return true;
    if (routeId == 'product-detail') return true;
    if (type.contains('product')) return true;
    if (type.contains('ad_')) return true;
    if (type.contains('approval') &&
        (type.contains('product') || type.contains('ad') || type.contains('listing'))) {
      return true;
    }
    return false;
  }

  void _handleNotificationData(
    Map<String, dynamic> data, {
    required bool navigate,
  }) {
    _refreshOrderFromData(data);
    unawaited(_refreshProfileFromData(data));
    if (!navigate) return;

    _runWhenRouterReady(() => _navigateFromNotificationData(data));
  }

  void _runWhenRouterReady(VoidCallback action, {VoidCallback? fallback}) {
    void attempt() {
      if (AppRoutes.navigatorKey.currentContext != null) {
        action();
        return;
      }
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (AppRoutes.navigatorKey.currentContext != null) {
          action();
        } else {
          fallback?.call();
        }
      });
    }

    attempt();
  }

  void _navigateFromNotificationData(Map<String, dynamic> data) {
    final ctx = AppRoutes.navigatorKey.currentContext;
    if (ctx == null) {
      debugPrint('Notification navigation skipped: no navigator context');
      return;
    }

    final type = (data['type'] ??
            data['Type'] ??
            data['typeName'] ??
            data['TypeName'] ??
            '')
        .toString()
        .toLowerCase();

    // Profile approval/rejection always opens edit profile (push payload quirk).
    if (type.contains('company_profile_approved') ||
        type.contains('company_profile_rejected') ||
        type.contains('company_approved') ||
        type.contains('company_rejected')) {
      AppRoutes.router.push(AppRoutes.kEditProfileView);
      return;
    }

    // Same routing as in-app notification list (Android + iOS).
    final referenceId = (data['highlightProductId'] ??
            data['productId'] ??
            data['ProductId'] ??
            data['referenceId'] ??
            data['ReferenceId'] ??
            data['orderId'] ??
            data['OrderId'] ??
            '')
        .toString()
        .trim();

    final item = AppNotificationModel(
      id: (data['id'] ?? data['Id'] ?? '').toString(),
      title: (data['title'] ?? data['Title'] ?? '').toString(),
      body: (data['body'] ?? data['Body'] ?? '').toString(),
      referenceId: referenceId,
      routeId: (data['routeId'] ?? data['RouteId'] ?? '').toString(),
      routeName: (data['routeName'] ?? data['RouteName'] ?? '').toString(),
      typeName: type,
    );

    unawaited(NotificationNavigationHelper.open(ctx, item));
  }

  int? _parseOrderId(Map<String, dynamic> data) {
    return int.tryParse(
      data['orderId']?.toString() ??
          data['OrderId']?.toString() ??
          data['referenceId']?.toString() ??
          data['ReferenceId']?.toString() ??
          '',
    );
  }
}
