import 'dart:async';

import 'package:alrasmarket/core/media/media_compression_service.dart';
import 'package:alrasmarket/core/serveses/auth_service.dart';
import 'package:alrasmarket/features/chat/data/models/chat_message_model.dart';
import 'package:alrasmarket/features/chat/data/models/chat_message_type.dart';
import 'package:alrasmarket/features/chat/data/models/chat_presence_model.dart';
import 'package:alrasmarket/features/chat/data/models/chat_support_session_model.dart';
import 'package:alrasmarket/features/chat/data/repository/chat_repository.dart';
import 'package:alrasmarket/features/chat/data/utils/chat_media_helper.dart';
import 'package:alrasmarket/features/chat/presentation/controller/chat_states.dart';
import 'package:alrasmarket/generated/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ChatCubit extends Cubit<ChatState> {
  ChatCubit({ChatRepository? repository})
      : _repository = repository ?? ChatRepository(),
        super(ChatInitial()) {
    _initialize();
  }

  static ChatCubit get(BuildContext context) =>
      BlocProvider.of<ChatCubit>(context);

  /// Matches the server limit in `ChatAppService.MaxChatFileBytes`.
  static const int chatFileMaxBytes = 20 * 1024 * 1024;

  final ChatRepository _repository;
  StreamSubscription<ChatMessageModel>? _messageSubscription;
  StreamSubscription<dynamic>? _seenSubscription;
  StreamSubscription<dynamic>? _deliveredSubscription;
  StreamSubscription<ChatPresenceModel>? _presenceSubscription;
  StreamSubscription<ChatSupportSessionModel>? _sessionSubscription;
  Timer? _presenceTimer;

  List<ChatMessageModel> messages = [];
  List<ChatSupportSessionModel> supportSessions = [];
  String? activeAgentName;
  String? userId;
  String? otherUserId;
  ChatPresenceModel? otherUserPresence;
  bool _isConversationActive = false;

  void _initialize() {
    _messageSubscription = _repository.messageStream.listen((message) {
      final oid = otherUserId;
      final uid = userId;
      if (oid == null || uid == null || !_isConversationActive) return;

      final isInConversation =
          (message.fromUserId.toLowerCase() == oid.toLowerCase() &&
              message.toUserId.toLowerCase() == uid.toLowerCase()) ||
          (message.fromUserId.toLowerCase() == uid.toLowerCase() &&
              message.toUserId.toLowerCase() == oid.toLowerCase());

      if (!isInConversation) return;

      unawaited(_ingestIncomingMessage(message));
    });

    _seenSubscription = _repository.seenStream.listen((event) {
      final uid = userId;
      final oid = otherUserId;
      if (uid == null || oid == null || !_isConversationActive) return;

      // Support agent (or peer) read my messages.
      if (event.otherUserId.toLowerCase() == uid.toLowerCase()) {
        _markOutgoingAsSeen(oid);
      }
    });

    _deliveredSubscription = _repository.deliveredStream.listen((event) {
      final uid = userId;
      if (uid == null || !_isConversationActive) return;
      if (event.fromUserId.toLowerCase() != uid.toLowerCase()) return;

      final ids = event.messageIds.toSet();
      if (ids.isEmpty) return;

      var changed = false;
      messages = messages.map((m) {
        if (!ids.contains(m.messageId) || m.isDelivered) return m;
        changed = true;
        return m.copyWith(isDelivered: true);
      }).toList();
      if (changed) {
        emit(ChatMessagesLoaded(List.from(messages)));
      }
    });

    _presenceSubscription = _repository.presenceStream.listen((presence) {
      final oid = otherUserId;
      if (oid == null || !_isConversationActive) return;
      if (presence.userId.toLowerCase() == oid.toLowerCase()) {
        otherUserPresence = presence;
        emit(ChatPresenceUpdated(presence));
      }
    });

    _sessionSubscription =
        _repository.supportSessionStream.listen(_applySupportSession);
  }

  void _applySupportSession(ChatSupportSessionModel session) {
    if (!_isConversationActive) return;

    final idx = supportSessions.indexWhere(
      (s) =>
          s.agentUserId.toLowerCase() == session.agentUserId.toLowerCase() &&
          s.assignedAtUtc.toIso8601String() ==
              session.assignedAtUtc.toIso8601String(),
    );

    if (session.isActive) {
      supportSessions = supportSessions
          .map(
            (s) => s.isActive
                ? s.copyWith(
                    isActive: false,
                    releasedAtUtc: s.releasedAtUtc ?? DateTime.now().toUtc(),
                  )
                : s,
          )
          .toList();
      if (idx >= 0) {
        supportSessions[idx] = session.copyWith(isActive: true);
      } else {
        supportSessions = [...supportSessions, session.copyWith(isActive: true)];
      }
      activeAgentName = session.agentName;
    } else {
      if (idx >= 0) {
        supportSessions[idx] = supportSessions[idx].copyWith(
          isActive: false,
          releasedAtUtc: session.releasedAtUtc ?? DateTime.now().toUtc(),
        );
      } else {
        supportSessions = [
          ...supportSessions,
          session.copyWith(
            isActive: false,
            releasedAtUtc: session.releasedAtUtc ?? DateTime.now().toUtc(),
          ),
        ];
      }
      if (activeAgentName?.toLowerCase() == session.agentName.toLowerCase()) {
        activeAgentName = null;
      }
      // Agent closed the session — stop presence heartbeats to cut SignalR load.
      _presenceTimer?.cancel();
      _presenceTimer = null;
    }

    emit(ChatSessionsUpdated(List.from(supportSessions)));
    emit(ChatMessagesLoaded(List.from(messages)));
  }

  void _markOutgoingAsSeen(String otherId) {
    bool changed = false;
    messages = messages.map((m) {
      if (m.fromUserId == userId && m.toUserId == otherId && !m.isSeen) {
        changed = true;
        return m.copyWith(isSeen: true, isDelivered: true);
      }
      return m;
    }).toList();
    if (changed) {
      emit(ChatMessagesLoaded(List.from(messages)));
    }
  }

  Future<void> startSupportChat({required String adminUserId}) async {
    final token = AuthService.instance.currentToken;
    final uid = AuthService.instance.currentUserID;
    if (token == null || uid == null) {
      emit(ChatMessagesError(S.current.pleaseLoginToStartChat));
      return;
    }

    userId = uid;
    otherUserId = adminUserId;
    _isConversationActive = true;
    _repository.setActiveConversation(adminUserId);

    final result = await _repository.initializeSignalR(
      userId: uid,
      token: token,
    );
    result.fold(
      (_) => emit(const ChatConnectionState(false)),
      (_) {
        emit(const ChatConnectionState(true));
        unawaited(_updatePresence());
        _startPresenceHeartbeat();
      },
    );

    await loadMessages();
  }

  Future<void> _ingestIncomingMessage(ChatMessageModel message) async {
    final oid = otherUserId;
    final uid = userId;
    if (oid == null || uid == null) return;

    final idx = messages.indexWhere((m) => m.messageId == message.messageId);
    if (idx >= 0) {
      final existing = messages[idx];
      messages[idx] = message.copyWith(
        deliveryStatus:
            existing.deliveryStatus == MessageDeliveryStatus.sending
                ? MessageDeliveryStatus.sent
                : existing.deliveryStatus,
        isDelivered: message.isDelivered || existing.isDelivered,
        isSeen: message.isSeen || existing.isSeen,
        content:
            existing.content.isNotEmpty ? existing.content : message.content,
      );
    } else {
      messages.add(message);
    }
    emit(ChatMessagesLoaded(List.from(messages)));

    if (message.fromUserId.toLowerCase() == oid.toLowerCase() &&
        message.toUserId.toLowerCase() == uid.toLowerCase()) {
      emit(ChatNewIncomingMessage(message));
      emit(ChatMessagesLoaded(List.from(messages)));
      unawaited(_markDeliveredAndSeen());
    }
  }

  void _startPresenceHeartbeat() {
    _presenceTimer?.cancel();
    _presenceTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (_isConversationActive) {
        unawaited(_updatePresence());
      }
    });
  }

  Future<void> _updatePresence() async {
    final token = AuthService.instance.currentToken;
    if (token == null) return;

    final result = await _repository.updatePresence(token: token);
    result.fold((_) {}, (_) {});
  }

  Future<void> loadMessages() async {
    final token = AuthService.instance.currentToken;
    final oid = otherUserId;
    if (token == null || oid == null) return;

    emit(ChatLoading());
    final result = await _repository.getConversationDetails(
      token: token,
      otherUserId: oid,
    );

    result.fold(
      (failure) => emit(ChatMessagesError(failure.message)),
      (details) {
        unawaited(_applyLoadedConversation(details));
      },
    );
  }

  Future<void> _applyLoadedConversation(ChatConversationDetails details) async {
    messages = List<ChatMessageModel>.from(details.messages);
    supportSessions = details.supportSessions;
    activeAgentName = details.activeAgentName;
    emit(ChatSessionsUpdated(List.from(supportSessions)));
    emit(ChatMessagesLoaded(messages));
    unawaited(_markDeliveredAndSeen());
    unawaited(_updatePresence());
  }

  Future<void> _markDeliveredAndSeen() async {
    final token = AuthService.instance.currentToken;
    final oid = otherUserId;
    if (token == null || oid == null || !_isConversationActive) return;

    await _repository.markConversationDelivered(
      token: token,
      otherUserId: oid,
    );
    await _repository.markConversationSeen(token: token, otherUserId: oid);
    unawaited(_updatePresence());
  }

  Future<void> sendTextMessage(String content) async {
    await _updatePresence();
    await _sendMessage(ChatMessageType.text, content);
  }

  Future<void> sendLocationMessage(String locationJson) async {
    await _updatePresence();
    await _sendMessage(ChatMessageType.location, locationJson);
  }

  Future<void> sendMediaMessage({
    required String filePath,
    required ChatMessageType messageType,
  }) async {
    final token = AuthService.instance.currentToken;
    final oid = otherUserId;
    final uid = userId;
    if (token == null || oid == null || uid == null) return;

    final tempId = 'local_${DateTime.now().microsecondsSinceEpoch}';
    final localMessage = ChatMessageModel(
      messageId: tempId,
      fromUserId: uid,
      toUserId: oid,
      messageType: messageType,
      content: filePath,
      sentAtUtc: DateTime.now().toUtc(),
      deliveryStatus: MessageDeliveryStatus.sending,
      processingProgress: 0,
      processingLabel:
          messageType == ChatMessageType.file ? 'Uploading...' : 'Compressing...',
    );
    messages.add(localMessage);
    emit(ChatMessagesLoaded(List.from(messages)));

    unawaited(
      _processAndSendMedia(
        tempId: tempId,
        filePath: filePath,
        messageType: messageType,
        token: token,
        uid: uid,
        oid: oid,
      ),
    );
  }

  Future<void> _processAndSendMedia({
    required String tempId,
    required String filePath,
    required ChatMessageType messageType,
    required String token,
    required String uid,
    required String oid,
  }) async {
    void updateMessage(ChatMessageModel updated) {
      final idx = messages.indexWhere((m) => m.messageId == tempId);
      if (idx >= 0) {
        messages[idx] = updated;
        emit(ChatMessagesLoaded(List.from(messages)));
      }
    }

    try {
      // Voice is already encoded; documents must be uploaded byte-for-byte.
      final skipCompression = messageType == ChatMessageType.voice ||
          messageType == ChatMessageType.file;
      String prepared = filePath;

      if (!skipCompression) {
        final compressed = await MediaCompressionService.prepareChatMedia(
          filePath,
          onProgress: (progress) {
            updateMessage(
              messages.firstWhere((m) => m.messageId == tempId).copyWith(
                    processingProgress: progress * 0.7,
                    processingLabel: 'Compressing...',
                    deliveryStatus: MessageDeliveryStatus.sending,
                  ),
            );
          },
        );

        if (compressed == null) {
          updateMessage(
            messages.firstWhere((m) => m.messageId == tempId).copyWith(
                  deliveryStatus: MessageDeliveryStatus.failed,
                  clearProcessingProgress: true,
                  processingLabel: 'Compression failed',
                ),
          );
          emit(const ChatMessageSendError('Could not compress media.'));
          return;
        }
        prepared = compressed;
      }

      if (messageType == ChatMessageType.video) {
        final size = await MediaCompressionService.fileSizeBytes(prepared);
        if (size > MediaCompressionService.chatVideoMaxBytes) {
          updateMessage(
            messages.firstWhere((m) => m.messageId == tempId).copyWith(
                  deliveryStatus: MessageDeliveryStatus.failed,
                  clearProcessingProgress: true,
                  processingLabel: 'Video too large',
                ),
          );
          emit(const ChatMessageSendError('Video must be 30 MB or smaller.'));
          return;
        }
      }

      if (messageType == ChatMessageType.file) {
        final size = await MediaCompressionService.fileSizeBytes(prepared);
        if (size > chatFileMaxBytes) {
          updateMessage(
            messages.firstWhere((m) => m.messageId == tempId).copyWith(
                  deliveryStatus: MessageDeliveryStatus.failed,
                  clearProcessingProgress: true,
                  processingLabel: 'File too large',
                ),
          );
          emit(const ChatMessageSendError('File must be 20 MB or smaller.'));
          return;
        }
      }

      updateMessage(
        messages.firstWhere((m) => m.messageId == tempId).copyWith(
              content: prepared,
              processingProgress: 0.75,
              processingLabel: 'Uploading...',
            ),
      );

      final uploadResult = await _repository.uploadMedia(
        token: token,
        filePath: prepared,
        messageType: messageType,
      );

      await uploadResult.fold(
        (failure) async {
          updateMessage(
            messages.firstWhere((m) => m.messageId == tempId).copyWith(
                  deliveryStatus: MessageDeliveryStatus.failed,
                  clearProcessingProgress: true,
                  clearProcessingLabel: true,
                ),
          );
          emit(ChatMessageSendError(failure.message));
        },
        (uploaded) async {
          updateMessage(
            messages.firstWhere((m) => m.messageId == tempId).copyWith(
                  processingProgress: 0.95,
                  processingLabel: 'Sending...',
                ),
          );
          await _sendMessage(
            uploaded.messageType,
            uploaded.content,
            replaceTempId: tempId,
          );
        },
      );
    } catch (e) {
      updateMessage(
        messages.firstWhere((m) => m.messageId == tempId).copyWith(
              deliveryStatus: MessageDeliveryStatus.failed,
              clearProcessingProgress: true,
              clearProcessingLabel: true,
            ),
      );
      emit(ChatMessageSendError(e.toString()));
    }
  }

  Future<void> sendFileMessage({
    required String filePath,
    required String fileName,
  }) async {
    final uploadType = ChatMediaHelper.uploadTypeForPath(filePath) ??
        ChatMediaHelper.uploadTypeForPath(fileName);

    if (uploadType == ChatMessageType.image) {
      await sendMediaMessage(
        filePath: filePath,
        messageType: ChatMessageType.image,
      );
      return;
    }

    if (uploadType == ChatMessageType.voice) {
      await sendMediaMessage(
        filePath: filePath,
        messageType: ChatMessageType.voice,
      );
      return;
    }

    if (uploadType == ChatMessageType.video) {
      await sendMediaMessage(
        filePath: filePath,
        messageType: ChatMessageType.video,
      );
      return;
    }

    if (uploadType == ChatMessageType.file) {
      await sendMediaMessage(
        filePath: filePath,
        messageType: ChatMessageType.file,
      );
      return;
    }

    emit(
      ChatMessageSendError(
        'Unsupported file type. Allowed: '
        '${ChatMediaHelper.supportedDocumentsLabel}, images, videos and audio.',
      ),
    );
  }

  Future<void> _sendMessage(
    ChatMessageType type,
    String content, {
    String? replaceTempId,
  }) async {
    final token = AuthService.instance.currentToken;
    final uid = userId;
    final oid = otherUserId;
    if (token == null || uid == null || oid == null) return;
    if (content.trim().isEmpty) return;

    final tempId =
        replaceTempId ?? 'local_${DateTime.now().microsecondsSinceEpoch}';
    if (replaceTempId == null) {
      final localMessage = ChatMessageModel(
        messageId: tempId,
        fromUserId: uid,
        toUserId: oid,
        messageType: type,
        content: content.trim(),
        sentAtUtc: DateTime.now().toUtc(),
        deliveryStatus: MessageDeliveryStatus.sending,
      );
      messages.add(localMessage);
      emit(ChatMessagesLoaded(List.from(messages)));
    }

    emit(ChatMessageSending());

    // Support chat sends plaintext (E2E encryption disabled).
    final wireContent = content.trim();

    final result = await _repository.sendMessage(
      token: token,
      toUserId: oid,
      messageType: type,
      content: wireContent,
    );

    result.fold(
      (failure) {
        final idx = messages.indexWhere((m) => m.messageId == tempId);
        if (idx >= 0) {
          messages[idx] = messages[idx].copyWith(
            deliveryStatus: MessageDeliveryStatus.failed,
          );
          emit(ChatMessagesLoaded(List.from(messages)));
        }
        emit(ChatMessageSendError(failure.message));
      },
      (serverMessage) {
        emit(ChatMessageSent());
        final idx = messages.indexWhere((m) => m.messageId == tempId);
        final updated = serverMessage.copyWith(
          content: content.trim(),
          deliveryStatus: MessageDeliveryStatus.sent,
          clearProcessingProgress: true,
          clearProcessingLabel: true,
        );
        if (idx >= 0) {
          messages[idx] = updated;
        } else {
          messages.add(updated);
        }
        emit(ChatMessagesLoaded(List.from(messages)));
        unawaited(_updatePresence());
      },
    );
  }

  String? presenceLabel() {
    final agent = activeAgentName?.trim();
    if (agent != null && agent.isNotEmpty) {
      return agent;
    }

    final presence = otherUserPresence;
    if (presence == null) return null;
    if (presence.isOnline) return 'Online';

    final lastSeen = presence.lastSeenAt;
    if (lastSeen == null) return null;

    final diff = DateTime.now().toUtc().difference(lastSeen.toUtc());
    if (diff.inMinutes < 1) return 'Last seen just now';
    if (diff.inHours < 1) return 'Last seen ${diff.inMinutes}m ago';
    if (diff.inDays < 1) return 'Last seen ${diff.inHours}h ago';
    return 'Last seen ${diff.inDays}d ago';
  }

  void exitConversation() {
    _isConversationActive = false;
    _repository.setActiveConversation(null);
    _presenceTimer?.cancel();
    _presenceTimer = null;
  }

  @override
  Future<void> close() async {
    exitConversation();
    await _messageSubscription?.cancel();
    await _seenSubscription?.cancel();
    await _deliveredSubscription?.cancel();
    await _presenceSubscription?.cancel();
    await _sessionSubscription?.cancel();
    await _repository.dispose();
    return super.close();
  }
}
