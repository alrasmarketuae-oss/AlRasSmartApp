import 'package:alrasmarket/features/chat/data/models/chat_message_model.dart';

class ChatMessageDeletedEvent {
  const ChatMessageDeletedEvent({
    required this.messageId,
    required this.fromUserId,
    required this.toUserId,
    required this.scope,
    required this.deletedByUserId,
    required this.isDeleted,
    this.message,
  });

  final String messageId;
  final String fromUserId;
  final String toUserId;
  final String scope;
  final String deletedByUserId;
  final bool isDeleted;
  final ChatMessageModel? message;

  factory ChatMessageDeletedEvent.fromJson(Map<String, dynamic> json) {
    final rawMessage = json['message'] ?? json['Message'];
    return ChatMessageDeletedEvent(
      messageId: (json['messageId'] ?? json['MessageId'] ?? '').toString(),
      fromUserId: (json['fromUserId'] ?? json['FromUserId'] ?? '').toString(),
      toUserId: (json['toUserId'] ?? json['ToUserId'] ?? '').toString(),
      scope: (json['scope'] ?? json['Scope'] ?? 'me').toString().toLowerCase(),
      deletedByUserId:
          (json['deletedByUserId'] ?? json['DeletedByUserId'] ?? '').toString(),
      isDeleted: json['isDeleted'] as bool? ?? json['IsDeleted'] as bool? ?? false,
      message: rawMessage is Map
          ? ChatMessageModel.fromJson(Map<String, dynamic>.from(rawMessage))
          : null,
    );
  }
}
