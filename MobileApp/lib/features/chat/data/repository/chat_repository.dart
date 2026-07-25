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
  });

  final List<ChatMessageModel> messages;
  final List<ChatSupportSessionModel> supportSessions;
  final String? activeAgentId;
  final String? activeAgentName;
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
      await _hub.ensureStarted();
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
  }) async {
    try {
      final response = await DioHelper.getData(
        url: ApiConstants.chatConversationEndPoint,
        query: {'otherUserId': otherUserId},
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

  Future<Either<Failure, String>> upsertMyKeyPair({
    required String token,
    required String publicKeyJwk,
    required String privateKeyJwk,
  }) async {
    try {
      final response = await DioHelper.putData(
        url: ApiConstants.chatKeysMeEndPoint,
        token: token,
        data: {
          'publicKeySpkiBase64': publicKeyJwk,
          'privateKeyPkcs8Base64': privateKeyJwk,
        },
      );
      if (response == null || (response.statusCode ?? 0) >= 300) {
        return Left(
          ServerFailure(
            _extractMessage(response?.data) ?? 'Failed to upload chat key',
          ),
        );
      }
      return Right(publicKeyJwk);
    } catch (e) {
      return Left(ServerFailure('Failed to upload chat key: $e'));
    }
  }

  Future<Either<Failure, ({String publicKeyJwk, String privateKeyJwk})?>>
      getMyKeyPair({required String token}) async {
    try {
      final response = await DioHelper.getData(
        url: ApiConstants.chatKeysMePrivateEndPoint,
        token: token,
      );
      if (response?.statusCode == 404) {
        return const Right(null);
      }
      if (response == null || response.statusCode != 200) {
        return Left(
          ServerFailure(
            _extractMessage(response?.data) ?? 'Failed to load chat key',
          ),
        );
      }
      final data = response.data;
      if (data is! Map) return const Right(null);
      final privateKey = data['privateKeyPkcs8Base64']?.toString() ??
          data['PrivateKeyPkcs8Base64']?.toString();
      final publicKey = data['publicKeySpkiBase64']?.toString() ??
          data['PublicKeySpkiBase64']?.toString();
      if (privateKey == null ||
          privateKey.trim().isEmpty ||
          publicKey == null ||
          publicKey.trim().isEmpty) {
        return const Right(null);
      }
      return Right((
        publicKeyJwk: publicKey.trim(),
        privateKeyJwk: privateKey.trim(),
      ));
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        return const Right(null);
      }
      return Left(ServerFailure('Failed to load chat key: $e'));
    } catch (e) {
      return Left(ServerFailure('Failed to load chat key: $e'));
    }
  }

  Future<Either<Failure, String?>> getPublicKey({
    required String token,
    required String userId,
  }) async {
    try {
      final response = await DioHelper.getData(
        url: ApiConstants.chatKeyByUserEndPoint(userId),
        token: token,
      );
      if (response?.statusCode == 404) {
        return const Right(null);
      }
      if (response == null || response.statusCode != 200) {
        return Left(
          ServerFailure(
            _extractMessage(response?.data) ?? 'Failed to load public key',
          ),
        );
      }
      final data = response.data;
      if (data is Map) {
        final key = data['publicKeySpkiBase64']?.toString() ??
            data['PublicKeySpkiBase64']?.toString();
        if (key == null || key.trim().isEmpty) {
          return const Right(null);
        }
        return Right(key.trim());
      }
      return const Right(null);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        return const Right(null);
      }
      return Left(ServerFailure('Failed to load public key: $e'));
    } catch (e) {
      return Left(ServerFailure('Failed to load public key: $e'));
    }
  }

  /// Does not stop the shared hub — only clears active conversation.
  void dispose() {
    _hub.activeConversationOtherUserId = null;
  }

  String? _extractMessage(dynamic data) {
    if (data is Map) {
      return data['message']?.toString() ?? data['title']?.toString();
    }
    if (data is String) return data;
    return null;
  }
}
