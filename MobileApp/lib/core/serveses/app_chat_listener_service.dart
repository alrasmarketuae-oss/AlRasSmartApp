import 'dart:async';

import 'package:alrasmarket/core/router/app_router.dart';
import 'package:alrasmarket/core/services/api_constants.dart';
import 'package:alrasmarket/core/services/app_push_notification_service.dart';
import 'package:alrasmarket/core/serveses/auth_service.dart';
import 'package:alrasmarket/features/chat/data/models/chat_message_model.dart';
import 'package:alrasmarket/features/chat/data/models/chat_message_type.dart';
import 'package:alrasmarket/features/chat/data/models/chat_presence_model.dart';
import 'package:alrasmarket/features/chat/data/models/chat_support_session_model.dart';
import 'package:alrasmarket/features/chat/data/models/conversation_seen_event.dart';
import 'package:alrasmarket/features/chat/data/models/messages_delivered_event.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:signalr_netcore/signalr_client.dart';

/// Single shared ChatHub connection for the whole app (notifications + open chat).
class AppChatListenerService {
  AppChatListenerService._();

  static final AppChatListenerService instance = AppChatListenerService._();

  HubConnection? _hubConnection;
  String? _userId;
  bool _starting = false;

  /// When set, the support chat screen is open with this peer (support admin id).
  String? activeConversationOtherUserId;

  final StreamController<ChatMessageModel> _messageController =
      StreamController<ChatMessageModel>.broadcast();
  final StreamController<ConversationSeenEvent> _seenController =
      StreamController<ConversationSeenEvent>.broadcast();
  final StreamController<MessagesDeliveredEvent> _deliveredController =
      StreamController<MessagesDeliveredEvent>.broadcast();
  final StreamController<ChatPresenceModel> _presenceController =
      StreamController<ChatPresenceModel>.broadcast();
  final StreamController<ChatSupportSessionModel> _sessionController =
      StreamController<ChatSupportSessionModel>.broadcast();

  Stream<ChatMessageModel> get messageStream => _messageController.stream;
  Stream<ConversationSeenEvent> get seenStream => _seenController.stream;
  Stream<MessagesDeliveredEvent> get deliveredStream =>
      _deliveredController.stream;
  Stream<ChatPresenceModel> get presenceStream => _presenceController.stream;
  Stream<ChatSupportSessionModel> get supportSessionStream =>
      _sessionController.stream;

  bool get isConnected =>
      _hubConnection?.state == HubConnectionState.Connected;

  Future<void> start() async {
    if (_starting || isConnected) return;

    final token = AuthService.instance.currentToken;
    final userId = AuthService.instance.currentUserID;
    if (token == null ||
        token.isEmpty ||
        userId == null ||
        userId.isEmpty) {
      return;
    }

    _starting = true;
    try {
      await _stopConnectionOnly();

      _userId = userId;
      _hubConnection = HubConnectionBuilder()
          .withUrl(
            ApiConstants.chatHubUrl,
            options: HttpConnectionOptions(
              accessTokenFactory: () async =>
                  AuthService.instance.currentToken ?? token,
            ),
          )
          .withAutomaticReconnect()
          .build();

      _hubConnection!.on('receiveMessage', _onReceiveMessage);
      _hubConnection!.on('messageUpdated', _onReceiveMessage);
      _hubConnection!.on('conversationSeen', _onConversationSeen);
      _hubConnection!.on('messagesDelivered', _onMessagesDelivered);
      _hubConnection!.on('userLastSeen', _onUserLastSeen);
      _hubConnection!.on('supportSessionStarted', _onSupportSessionStarted);
      _hubConnection!.on('supportSessionEnded', _onSupportSessionEnded);

      _hubConnection!.onreconnected(({connectionId}) async {
        await _joinUserGroup();
      });

      await _hubConnection!.start();
      await _joinUserGroup();
      debugPrint('AppChatListenerService connected');
    } catch (e) {
      debugPrint('AppChatListenerService start failed: $e');
      await _stopConnectionOnly();
    } finally {
      _starting = false;
    }
  }

  Future<void> stop() async {
    activeConversationOtherUserId = null;
    _userId = null;
    await _stopConnectionOnly();
  }

  Future<void> _stopConnectionOnly() async {
    _starting = false;
    try {
      final hub = _hubConnection;
      final userId = _userId;
      if (hub != null &&
          hub.state == HubConnectionState.Connected &&
          userId != null &&
          userId.isNotEmpty) {
        await hub.invoke('LeaveUserChat', args: [userId]);
      }
      await hub?.stop();
    } catch (_) {}
    _hubConnection = null;
  }

  Future<void> ensureStarted() async {
    if (isConnected) return;
    await start();
  }

  Future<void> acknowledgeDelivery(String senderUserId) async {
    final hub = _hubConnection;
    if (hub == null ||
        hub.state != HubConnectionState.Connected ||
        senderUserId.isEmpty) {
      return;
    }

    try {
      await hub.invoke('AcknowledgeDelivery', args: [senderUserId]);
    } catch (_) {}
  }

  Future<void> _joinUserGroup() async {
    final hub = _hubConnection;
    final userId = _userId;
    if (hub == null ||
        hub.state != HubConnectionState.Connected ||
        userId == null ||
        userId.isEmpty) {
      return;
    }

    try {
      await hub.invoke('JoinUserChat', args: [userId]);
    } catch (_) {}
  }

  void _onReceiveMessage(List<Object?>? arguments) {
    if (arguments == null || arguments.isEmpty) return;

    try {
      final raw = arguments[0];
      if (raw is! Map) return;

      final message = ChatMessageModel.fromJson(
        Map<String, dynamic>.from(raw),
      );
      _messageController.add(message);

      final uid = AuthService.instance.currentUserID;
      if (uid != null &&
          message.toUserId.toLowerCase() == uid.toLowerCase()) {
        unawaited(acknowledgeDelivery(message.fromUserId));
      }

      _handleIncomingNotification(message);
    } catch (e) {
      debugPrint('AppChatListenerService parse error: $e');
    }
  }

  void _onConversationSeen(List<Object?>? arguments) {
    if (arguments == null || arguments.isEmpty) return;
    try {
      final raw = arguments[0];
      if (raw is! Map) return;
      _seenController.add(
        ConversationSeenEvent.fromJson(Map<String, dynamic>.from(raw)),
      );
    } catch (_) {}
  }

  void _onMessagesDelivered(List<Object?>? arguments) {
    if (arguments == null || arguments.isEmpty) return;
    try {
      final raw = arguments[0];
      if (raw is! Map) return;
      _deliveredController.add(
        MessagesDeliveredEvent.fromJson(Map<String, dynamic>.from(raw)),
      );
    } catch (_) {}
  }

  void _onUserLastSeen(List<Object?>? arguments) {
    if (arguments == null || arguments.isEmpty) return;
    try {
      final raw = arguments[0];
      if (raw is! Map) return;
      _presenceController.add(
        ChatPresenceModel.fromJson(Map<String, dynamic>.from(raw)),
      );
    } catch (_) {}
  }

  void _onSupportSessionStarted(List<Object?>? arguments) {
    _handleSupportSession(arguments, isActive: true);
  }

  void _onSupportSessionEnded(List<Object?>? arguments) {
    _handleSupportSession(arguments, isActive: false);
  }

  void _handleSupportSession(List<Object?>? arguments, {required bool isActive}) {
    if (arguments == null || arguments.isEmpty) return;
    try {
      final raw = arguments[0];
      if (raw is! Map) return;
      final session = ChatSupportSessionModel.fromJson(
        Map<String, dynamic>.from(raw),
        forceActive: isActive,
      );
      _sessionController.add(session);

      final uid = AuthService.instance.currentUserID;
      if (uid == null) return;
      if (session.customerUserId != null &&
          session.customerUserId!.toLowerCase() != uid.toLowerCase()) {
        return;
      }

      final name = session.agentName.trim().isEmpty
          ? 'الدعم الفني'
          : session.agentName.trim();
      const title = 'الدعم الفني';
      final body = isActive
          ? 'أنت تتحدث مع $name'
          : 'تم إغلاق المحادثة من قبل $name';

      if (_isOnSupportChatScreen()) {
        return;
      }

      unawaited(
        AppPushNotificationService.instance.showForegroundAlert(
          title: title,
          body: body,
          data: {
            'type': 'chat_message',
            'routeId': 'chat',
            'title': title,
            'body': body,
          },
          onTap: () => AppRoutes.router.push(AppRoutes.kSupportChatView),
        ),
      );
    } catch (e) {
      debugPrint('AppChatListenerService session event error: $e');
    }
  }

  void _handleIncomingNotification(ChatMessageModel message) {
    final uid = AuthService.instance.currentUserID;
    if (uid == null) return;
    if (message.toUserId.toLowerCase() != uid.toLowerCase()) return;

    final isFromSupport = message.fromUserId.toLowerCase() ==
        ApiConstants.supportAdminUserId.toLowerCase();
    if (!isFromSupport) return;

    final activeOther = activeConversationOtherUserId;
    if (activeOther != null &&
        activeOther.toLowerCase() == message.fromUserId.toLowerCase()) {
      return;
    }
    if (_isOnSupportChatScreen()) return;

    final body = _messagePreview(message);
    unawaited(
      AppPushNotificationService.instance.showForegroundAlert(
        title: 'Support',
        body: body,
        data: {
          'type': 'chat_message',
          'routeId': 'chat',
          'referenceId': message.messageId,
          'fromUserId': message.fromUserId,
          'toUserId': message.toUserId,
          'title': 'Support',
          'body': body,
        },
        onTap: () => AppRoutes.router.push(AppRoutes.kSupportChatView),
      ),
    );
  }

  bool _isOnSupportChatScreen() {
    final context = AppRoutes.navigatorKey.currentContext;
    if (context == null) return false;
    return GoRouterState.of(context).matchedLocation ==
        AppRoutes.kSupportChatView;
  }

  String _messagePreview(ChatMessageModel message) {
    switch (message.messageType) {
      case ChatMessageType.image:
        return 'Sent an image';
      case ChatMessageType.voice:
        return 'Sent a voice message';
      case ChatMessageType.video:
        return 'Sent a video';
      case ChatMessageType.location:
        return 'Sent a location';
      case ChatMessageType.file:
        final fileName = message.fileContent?.name.trim() ?? '';
        return fileName.isEmpty ? 'Sent a file' : 'Sent a file: $fileName';
      case ChatMessageType.text:
        final text = message.content.trim();
        if (text.isEmpty) return 'New message from support';
        return text.length > 120 ? '${text.substring(0, 120)}…' : text;
    }
  }
}
