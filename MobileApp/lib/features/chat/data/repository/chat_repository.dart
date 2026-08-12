import 'dart:async';
import 'dart:io';

import 'package:alrasmarket/core/error/failure.dart';
import 'package:alrasmarket/core/serveses/app_chat_listener_service.dart';
import 'package:alrasmarket/core/services/api_constants.dart';
import 'package:alrasmarket/core/services/dio_helper.dart';
import 'package:alrasmarket/features/chat/data/models/chat_message_model.dart';
import 'package:alrasmarket/features/chat/data/models/chat_message_type.dart';
import 'package:alrasmarket/features/chat/data/models/chat_presence_model.dart';
import 'package:alrasmarket/features/chat/data/models/chat_support_session_model.dart';
import 'package:alrasmarket/features/chat/data/models/chat_upload_result_model.dart';
import 'package:alrasmarket/features/chat/data/models/conversation_seen_event.dart';
import 'package:alrasmarket/features/chat/data/models/messages_delivered_event.dart';
import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';

class ChatConversationDetails {
  const ChatConversationDetails({
    required this.messages,
    required this.supportSessions,
    this.activeAgentId,
    this.activeAgentName,
    this.hasMore = false,
    this.nextBeforeMessageId,
  });

  final List<ChatMessageModel> messages;
  final List<ChatSupportSessionModel> supportSessions;
  final String? activeAgentId;
  final String? activeAgentName;
  final bool hasMore;
  final String? nextBeforeMessageId;
}

/// HTTP + shared SignalR streams (no second hub connection).
class ChatRepository {
  final AppChatListenerService _hub = AppChatListenerService.instance;

  Stream<ChatMessageModel> get messageStream => _hub.messageStream;
  Stream<ConversationSeenEvent> get seenStream => _hub.seenStream;
  Stream<MessagesDeliveredEvent> get deliveredStream => _hub.deliveredStream;
  Stream<ChatPresenceModel> get presenceStream => _hub.presenceStream;
  Stream<ChatSupportSessionModel> get supportSessionStream =>
      _hub.supportSessionStream;

  bool get isConnected => _hub.isConnected;

  Future<Either<Failure, void>> initializeSignalR({
    required String userId,
    required String token,
  }) async {
    try {
      await _hub.enterChatScreen();
      if (!_hub.isConnected) {
        return const Left(ServerFailure('Failed to connect to chat server'));
      }
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure('Failed to connect to chat server: $e'));
    }
  }

  void setActiveConversation(String? otherUserId) {
    _hub.activeConversationOtherUserId = otherUserId;
  }

  Future<Either<Failure, ChatPresenceModel>> updatePresence({
    required String token,
  }) async {
    try {
      final response = await DioHelper.postData(
        url: ApiConstants.chatPresenceEndPoint,
        token: token,
        data: const <String, dynamic>{},
      );

      if (response == null) {
        return const Left(ServerFailure('No response from server'));
      }

      if (response.statusCode != 200) {
        return Left(
          ServerFailure(
            _extractMessage(response.data) ??
                'Failed to update presence (${response.statusCode})',
          ),
        );
      }

      final data = response.data;
      if (data is Map) {
        return Right(
          ChatPresenceModel.fromJson(Map<String, dynamic>.from(data)),
        );
      }
      return const Left(ServerFailure('Invalid presence response'));
    } catch (e) {
      return Left(ServerFailure('Failed to update presence: $e'));
    }
  }

  Future<Either<Failure, ChatMessageModel>> sendMessage({
    required String token,
    required String toUserId,
    required ChatMessageType messageType,
    required String content,
  }) async {
    try {
      final response = await DioHelper.postData(
        url: ApiConstants.chatMessagesEndPoint,
        token: token,
        data: {
          'toUserId': toUserId,
          'messageType': messageType.apiValue,
          'content': content,
        },
      );

      if (response == null) {
        return const Left(ServerFailure('No response from server'));
      }

      if (response.statusCode != 200) {
        return Left(
          ServerFailure(
            _extractMessage(response.data) ??
                'Failed to send message (${response.statusCode})',
          ),
        );
      }

      final body = response.data;
      if (body is Map) {
        return Right(
          ChatMessageModel.fromJson(Map<String, dynamic>.from(body)),
        );
      }
      return const Left(ServerFailure('Invalid response body'));
    } catch (e) {
      return Left(ServerFailure('Failed to send message: $e'));
    }
  }

  Future<Either<Failure, ChatUploadResultModel>> uploadMedia({
    required String token,
    required String filePath,
    required ChatMessageType messageType,
  }) async {
    if (messageType == ChatMessageType.image ||
        messageType == ChatMessageType.video ||
        messageType == ChatMessageType.voice) {
      final direct = await _uploadMediaViaDirectR2(
        token: token,
        filePath: filePath,
        messageType: messageType,
      );
      if (direct != null) {
        return direct;
      }
    }

    return _uploadMediaViaMultipart(
      token: token,
      filePath: filePath,
      messageType: messageType,
    );
  }

  /// Returns null when multipart fallback should be used (presign unavailable).
  Future<Either<Failure, ChatUploadResultModel>?> _uploadMediaViaDirectR2({
    required String token,
    required String filePath,
    required ChatMessageType messageType,
  }) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        return const Left(ServerFailure('File not found'));
      }

      final presignUrl = switch (messageType) {
        ChatMessageType.image => ApiConstants.chatPresignImageEndPoint,
        ChatMessageType.video => ApiConstants.chatPresignVideoEndPoint,
        ChatMessageType.voice => ApiConstants.chatPresignVoiceEndPoint,
        _ => throw StateError('Unsupported direct chat upload type'),
      };

      final Object? presignBody = messageType == ChatMessageType.image
          ? const <String, dynamic>{}
          : <String, dynamic>{
              'extension': _extensionFromPath(filePath),
            };

      final presignResponse = await DioHelper.postData(
        url: presignUrl,
        data: presignBody,
        token: token,
      );
      final presignStatus = presignResponse?.statusCode ?? 0;
      if (presignStatus == 503 || presignStatus == 404) {
        return null;
      }
      if (presignStatus < 200 || presignStatus >= 300) {
        return Left(
          ServerFailure(
            _extractMessage(presignResponse?.data) ??
                'Chat presign failed ($presignStatus)',
          ),
        );
      }

      final data = presignResponse?.data;
      if (data is! Map) {
        return const Left(ServerFailure('Invalid chat presign response'));
      }

      final uploadUrl =
          data['uploadUrl']?.toString() ?? data['UploadUrl']?.toString();
      final path = data['path']?.toString() ?? data['Path']?.toString();
      final contentType = data['contentType']?.toString() ??
          data['ContentType']?.toString() ??
          _defaultContentType(messageType, filePath);

      if (uploadUrl == null ||
          uploadUrl.isEmpty ||
          path == null ||
          path.isEmpty) {
        return const Left(ServerFailure('Chat presign response missing URL or path'));
      }

      final putResponse = await DioHelper.putBytesToAbsoluteUrl(
        url: uploadUrl,
        file: file,
        contentType: contentType,
      );
      final putStatus = putResponse?.statusCode ?? 0;
      if (putStatus < 200 || putStatus >= 300) {
        return Left(ServerFailure('Chat direct upload failed ($putStatus)'));
      }

      final confirmResponse = await DioHelper.postData(
        url: ApiConstants.chatConfirmUploadEndPoint,
        data: {
          'path': path,
          'messageType': messageType.apiValue,
        },
        token: token,
      );
      final confirmStatus = confirmResponse?.statusCode ?? 0;
      if (confirmStatus < 200 || confirmStatus >= 300) {
        return Left(
          ServerFailure(
            _extractMessage(confirmResponse?.data) ??
                'Chat upload confirm failed ($confirmStatus)',
          ),
        );
      }

      final confirmData = confirmResponse?.data;
      if (confirmData is Map) {
        final result = ChatUploadResultModel.fromJson(
          Map<String, dynamic>.from(confirmData),
        );
        if (result.content.isNotEmpty) {
          return Right(result);
        }
      }

      return const Left(ServerFailure('Invalid chat confirm response'));
    } on DioException catch (e) {
      final status = e.response?.statusCode ?? 0;
      if (status == 503 || status == 404) {
        return null;
      }
      return Left(
        ServerFailure(_extractMessage(e.response?.data) ?? e.message ?? 'Chat upload error'),
      );
    } catch (e) {
      return Left(ServerFailure('Chat direct upload failed: $e'));
    }
  }

  Future<Either<Failure, ChatUploadResultModel>> _uploadMediaViaMultipart({
    required String token,
    required String filePath,
    required ChatMessageType messageType,
  }) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        return const Left(ServerFailure('File not found'));
      }

      final fileName = file.path.split('/').last;
      final formData = FormData.fromMap({
        'MessageType': messageType.apiValue,
        'File': await MultipartFile.fromFile(
          file.path,
          filename: fileName,
        ),
      });

      final response = await DioHelper.uploadFile(
        url: ApiConstants.chatUploadEndPoint,
        formData: formData,
        token: token,
      );

      if (response == null) {
        return const Left(ServerFailure('No response from server'));
      }

      if (response.statusCode != 200) {
        return Left(
          ServerFailure(
            _extractMessage(response.data) ??
                'Failed to upload file (${response.statusCode})',
          ),
        );
      }

      final data = response.data;
      if (data is Map) {
        final result = ChatUploadResultModel.fromJson(
          Map<String, dynamic>.from(data),
        );
        if (result.content.isNotEmpty) {
          return Right(result);
        }
      }
      return const Left(ServerFailure('Invalid upload response'));
    } catch (e) {
      return Left(ServerFailure('Failed to upload file: $e'));
    }
  }

  Future<Either<Failure, void>> markConversationSeen({
    required String token,
    required String otherUserId,
  }) async {
    try {
      final response = await DioHelper.postData(
        url: ApiConstants.chatSeenEndPoint,
        token: token,
        data: {'otherUserId': otherUserId},
      );

      if (response == null) {
        return const Left(ServerFailure('No response from server'));
      }

      if (response.statusCode != 200) {
        return Left(ServerFailure('Failed: ${response.statusCode}'));
      }

      return const Right(null);
    } catch (e) {
      return Left(ServerFailure('Failed to mark seen: $e'));
    }
  }

  Future<Either<Failure, void>> markConversationDelivered({
    required String token,
    required String otherUserId,
  }) async {
    try {
      final response = await DioHelper.postData(
        url: ApiConstants.chatDeliveredEndPoint,
        token: token,
        data: {'otherUserId': otherUserId},
      );

      if (response == null) {
        return const Left(ServerFailure('No response from server'));
      }

      if (response.statusCode != 200) {
        return Left(ServerFailure('Failed: ${response.statusCode}'));
      }

      return const Right(null);
    } catch (e) {
      return Left(ServerFailure('Failed to mark delivered: $e'));
    }
  }

  Future<Either<Failure, ChatConversationDetails>> getConversationDetails({
    required String token,
    required String otherUserId,
    int limit = 50,
    String? beforeMessageId,
  }) async {
    try {
      final response = await DioHelper.getData(
        url: ApiConstants.chatConversationEndPoint,
        query: {
          'otherUserId': otherUserId,
          'limit': limit,
          if (beforeMessageId != null && beforeMessageId.isNotEmpty)
            'before': beforeMessageId,
        },
        token: token,
      );

      if (response == null) {
        return const Left(ServerFailure('No response from server'));
      }

      if (response.statusCode != 200) {
        return Left(
          ServerFailure(
            _extractMessage(response.data) ??
                'Failed to fetch conversation (${response.statusCode})',
          ),
        );
      }

      final data = response.data;
      if (data is! Map) {
        return const Left(ServerFailure('Invalid conversation response'));
      }

      final map = Map<String, dynamic>.from(data);
      final messagesRaw = map['messages'] ?? map['Messages'] ?? [];
      final sessionsRaw =
          map['supportSessions'] ?? map['SupportSessions'] ?? [];

      final messages = messagesRaw is List
          ? messagesRaw
              .whereType<Map>()
              .map(
                (json) => ChatMessageModel.fromJson(
                  Map<String, dynamic>.from(json),
                ),
              )
              .toList()
          : <ChatMessageModel>[];

      final sessions = sessionsRaw is List
          ? sessionsRaw
              .whereType<Map>()
              .map(
                (json) => ChatSupportSessionModel.fromJson(
                  Map<String, dynamic>.from(json),
                ),
              )
              .toList()
          : <ChatSupportSessionModel>[];

      return Right(
        ChatConversationDetails(
          messages: messages,
          supportSessions: sessions,
          activeAgentId:
              (map['activeAgentId'] ?? map['ActiveAgentId'])?.toString(),
          activeAgentName:
              (map['activeAgentName'] ?? map['ActiveAgentName'])?.toString(),
          hasMore: map['hasMore'] == true || map['HasMore'] == true,
          nextBeforeMessageId: (map['nextBeforeMessageId'] ??
                  map['NextBeforeMessageId'])
              ?.toString(),
        ),
      );
    } on DioException catch (e) {
      return Left(
        ServerFailure(
          _extractMessage(e.response?.data) ?? e.message ?? 'Network error',
        ),
      );
    } catch (e) {
      return Left(ServerFailure('Failed to fetch conversation: $e'));
    }
  }

  Future<Either<Failure, List<ChatMessageModel>>> getMessages({
    required String token,
    required String otherUserId,
  }) async {
    final details = await getConversationDetails(
      token: token,
      otherUserId: otherUserId,
    );
    return details.map((d) => d.messages);
  }

  Future<Either<Failure, int>> getUnreadCount({required String token}) async {
    try {
      final response = await DioHelper.getData(
        url: ApiConstants.chatUnreadCountEndPoint,
        token: token,
      );

      if (response?.statusCode != 200) {
        return const Right(0);
      }

      final data = response?.data;
      if (data is Map) {
        return Right(data['totalUnread'] as int? ?? 0);
      }
      return const Right(0);
    } catch (_) {
      return const Right(0);
    }
  }

  /// Stops the shared ChatHub when leaving the support chat screen.
  Future<void> dispose() async {
    await _hub.leaveChatScreen();
  }

  String? _extractMessage(dynamic data) {
    if (data is Map) {
      return data['message']?.toString() ?? data['title']?.toString();
    }
    if (data is String) return data;
    return null;
  }

  static String _extensionFromPath(String filePath) {
    final dot = filePath.lastIndexOf('.');
    if (dot < 0 || dot >= filePath.length - 1) {
      return '';
    }
    return filePath.substring(dot).toLowerCase();
  }

  static String _defaultContentType(
    ChatMessageType messageType,
    String filePath,
  ) {
    return switch (messageType) {
      ChatMessageType.image => 'image/jpeg',
      ChatMessageType.video => 'video/mp4',
      ChatMessageType.voice => 'audio/mp4',
      _ => 'application/octet-stream',
    };
  }
}
