// import 'package:flutter_local_notifications/flutter_local_notifications.dart';
// import 'package:firebase_messaging/firebase_messaging.dart';
// import 'package:firebase_core/firebase_core.dart';

// class FirebaseNotificationService {
//   static final FirebaseNotificationService _instance =
//       FirebaseNotificationService._internal();
//   factory FirebaseNotificationService() => _instance;
//   FirebaseNotificationService._internal();

//   final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
//   final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
//       FlutterLocalNotificationsPlugin();

//   String? _fcmToken;
//   bool _isInitialized = false;

//   // Getters
//   String? get fcmToken => _fcmToken;
//   bool get isInitialized => _isInitialized;

//   /// Initialize Firebase notification service
//   Future<void> initialize() async {
//     try {
//       if (_isInitialized) return;

//       print('🚀 FirebaseNotificationService: Initializing...');

//       // Request permission for iOS
//       await _requestPermission();

//       // Get FCM token
//       await _getFCMToken();

//       // Initialize local notifications
//       await _initializeLocalNotifications();

//       // Handle background messages
//       FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

//       // Handle foreground messages
//       FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

//       // Handle notification tap when app is in background
//       FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

//       // Check if app was opened from notification
//       await _checkInitialMessage();

//       _isInitialized = true;
//       print('✅ FirebaseNotificationService: Initialized successfully');
//     } catch (e) {
//       print('❌ FirebaseNotificationService: Error initializing: $e');
//       rethrow;
//     }
//   }

//   /// Request notification permission (required for iOS)
//   /// This method checks current status and only requests if not determined
//   Future<void> _requestPermission() async {
//     try {
//       // Check current permission status first
//       NotificationSettings currentSettings = await _firebaseMessaging.getNotificationSettings();
      
//       print(
//         '📱 FirebaseNotificationService: Current permission status: ${currentSettings.authorizationStatus}',
//       );

//       // Only request permission if it's not determined
//       if (currentSettings.authorizationStatus == AuthorizationStatus.notDetermined) {
//         print('📱 FirebaseNotificationService: Requesting notification permission...');
        
//       NotificationSettings settings = await _firebaseMessaging
//           .requestPermission(
//             alert: true,
//             announcement: false,
//             badge: true,
//             carPlay: false,
//             criticalAlert: false,
//             provisional: false,
//             sound: true,
//           );

//       print(
//           '📱 FirebaseNotificationService: Permission status after request: ${settings.authorizationStatus}',
//       );

//       if (settings.authorizationStatus == AuthorizationStatus.authorized) {
//         print('✅ FirebaseNotificationService: Notification permission granted');
//       } else if (settings.authorizationStatus ==
//           AuthorizationStatus.provisional) {
//         print(
//           '⚠️ FirebaseNotificationService: Provisional notification permission granted',
//         );
//       } else {
//         print('❌ FirebaseNotificationService: Notification permission denied');
//         }
//       } else {
//         print('📱 FirebaseNotificationService: Permission already determined, skipping request');
//       }
//     } catch (e) {
//       print('❌ FirebaseNotificationService: Error requesting permission: $e');
//     }
//   }

//   /// Get FCM token
//   Future<void> _getFCMToken() async {
//     try {
//       _fcmToken = await _firebaseMessaging.getToken();
//       print('🔑 FirebaseNotificationService: FCM Token: $_fcmToken');

//       if (_fcmToken != null) {
//         print('🔑 FirebaseNotificationService: FCM Token: $_fcmToken');

//         // Listen for token refresh
//         _firebaseMessaging.onTokenRefresh.listen((newToken) {
//           _fcmToken = newToken;
//           print(
//             '🔄 FirebaseNotificationService: FCM Token refreshed: $_fcmToken',
//           );
//           // TODO: Send new token to your server
//         });
//       } else {
//         print('❌ FirebaseNotificationService: Failed to get FCM token');
//       }
//     } catch (e) {
//       print('❌ FirebaseNotificationService: Error getting FCM token: $e');
//     }
//   }

//   /// Initialize local notifications
//   Future<void> _initializeLocalNotifications() async {
//     try {
//       const AndroidInitializationSettings initializationSettingsAndroid =
//           AndroidInitializationSettings('@mipmap/ic_launcher');

//       const DarwinInitializationSettings initializationSettingsIOS =
//           DarwinInitializationSettings(
//             requestAlertPermission: false,
//             requestBadgePermission: false,
//             requestSoundPermission: false,
//           );

//       const InitializationSettings initializationSettings =
//           InitializationSettings(
//             android: initializationSettingsAndroid,
//             iOS: initializationSettingsIOS,
//           );

//       await _flutterLocalNotificationsPlugin.initialize(
//         initializationSettings,
//         onDidReceiveNotificationResponse: _onNotificationTap,
//       );

//       print('✅ FirebaseNotificationService: Local notifications initialized');
//     } catch (e) {
//       print(
//         '❌ FirebaseNotificationService: Error initializing local notifications: $e',
//       );
//     }
//   }

//   /// Handle foreground messages
//   void _handleForegroundMessage(RemoteMessage message) {
//     print('📨 FirebaseNotificationService: Foreground message received:');
//     print('  Title: ${message.notification?.title}');
//     print('  Body: ${message.notification?.body}');
//     print('  Data: ${message.data}');

//     // Show local notification
//     _showLocalNotification(message);
//   }

//   /// Handle notification tap when app is in background
//   void _handleNotificationTap(RemoteMessage message) {
//     print('👆 FirebaseNotificationService: Notification tapped (background):');
//     print('  Title: ${message.notification?.title}');
//     print('  Body: ${message.notification?.body}');
//     print('  Data: ${message.data}');

//     // TODO: Navigate to specific screen based on notification data
//   }

//   /// Handle notification tap in local notifications
//   void _onNotificationTap(NotificationResponse response) {
//     print('👆 FirebaseNotificationService: Local notification tapped:');
//     print('  Payload: ${response.payload}');

//     // TODO: Navigate to specific screen based on notification payload
//   }

//   /// Check if app was opened from notification
//   Future<void> _checkInitialMessage() async {
//     try {
//       RemoteMessage? initialMessage = await _firebaseMessaging
//           .getInitialMessage();

//       if (initialMessage != null) {
//         print('🚀 FirebaseNotificationService: App opened from notification:');
//         print('  Title: ${initialMessage.notification?.title}');
//         print('  Body: ${initialMessage.notification?.body}');
//         print('  Data: ${initialMessage.data}');

//         // TODO: Navigate to specific screen based on notification data
//       }
//     } catch (e) {
//       print(
//         '❌ FirebaseNotificationService: Error checking initial message: $e',
//       );
//     }
//   }

//   /// Show local notification
//   Future<void> _showLocalNotification(RemoteMessage message) async {
//     try {
//       const AndroidNotificationDetails androidPlatformChannelSpecifics =
//           AndroidNotificationDetails(
//             'high_importance_channel',
//             'High Importance Notifications',
//             channelDescription:
//                 'This channel is used for important notifications.',
//             importance: Importance.max,
//             priority: Priority.high,
//             showWhen: true,
//           );

//       const DarwinNotificationDetails iOSPlatformChannelSpecifics =
//           DarwinNotificationDetails(
//             presentAlert: true,
//             presentBadge: true,
//             presentSound: true,
//           );

//       const NotificationDetails platformChannelSpecifics = NotificationDetails(
//         android: androidPlatformChannelSpecifics,
//         iOS: iOSPlatformChannelSpecifics,
//       );

//       await _flutterLocalNotificationsPlugin.show(
//         message.hashCode,
//         message.notification?.title ?? 'New Notification',
//         message.notification?.body ?? '',
//         platformChannelSpecifics,
//         payload: message.data.toString(),
//       );

//       print('✅ FirebaseNotificationService: Local notification shown');
//     } catch (e) {
//       print(
//         '❌ FirebaseNotificationService: Error showing local notification: $e',
//       );
//     }
//   }

//   /// Subscribe to topic
//   Future<void> subscribeToTopic(String topic) async {
//     try {
//       await _firebaseMessaging.subscribeToTopic(topic);
//       print('✅ FirebaseNotificationService: Subscribed to topic: $topic');
//     } catch (e) {
//       print(
//         '❌ FirebaseNotificationService: Error subscribing to topic $topic: $e',
//       );
//     }
//   }

//   /// Unsubscribe from topic
//   Future<void> unsubscribeFromTopic(String topic) async {
//     try {
//       await _firebaseMessaging.unsubscribeFromTopic(topic);
//       print('✅ FirebaseNotificationService: Unsubscribed from topic: $topic');
//     } catch (e) {
//       print(
//         '❌ FirebaseNotificationService: Error unsubscribing from topic $topic: $e',
//       );
//     }
//   }

//   /// Get current FCM token (refresh if needed)
//   Future<String?> refreshToken() async {
//     try {
//       _fcmToken = await _firebaseMessaging.getToken();
//       print('🔄 FirebaseNotificationService: FCM Token refreshed: $_fcmToken');
//       return _fcmToken;
//     } catch (e) {
//       print('❌ FirebaseNotificationService: Error refreshing FCM token: $e');
//       return null;
//     }
//   }

//   /// Delete FCM token
//   Future<void> deleteToken() async {
//     try {
//       await _firebaseMessaging.deleteToken();
//       _fcmToken = null;
//       print('🗑️ FirebaseNotificationService: FCM Token deleted');
//     } catch (e) {
//       print('❌ FirebaseNotificationService: Error deleting FCM token: $e');
//     }
//   }

//   /// Dispose resources
//   void dispose() {
//     _isInitialized = false;
//     print('🔄 FirebaseNotificationService: Disposed');
//   }
// }

// /// Background message handler (must be top-level function)
// @pragma('vm:entry-point')
// Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
//   // Ensure Firebase is initialized
//   await Firebase.initializeApp();

//   print('📨 FirebaseNotificationService: Background message received:');
//   print('  Title: ${message.notification?.title}');
//   print('  Body: ${message.notification?.body}');
//   print('  Data: ${message.data}');

//   // TODO: Handle background message processing
// }
