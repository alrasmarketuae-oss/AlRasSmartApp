import 'package:alrasmarket/core/services/api_constants.dart';
import 'package:alrasmarket/core/utils/utc_date_time.dart';
import 'package:alrasmarket/features/chat/data/models/chat_message_type.dart';

class ChatMessageModel {
  const ChatMessageModel({
    required this.messageId,
    required this.fromUserId,
    required this.toUserId,
    required this.messageType,
    required this.content,
    required this.sentAtUtc,
    this.relativeTime,
    this.isEdited = false,
    this.deliveryStatus = MessageDeliveryStatus.sent,
    this.isSeen = false,
    this.isDelivered = false,
    this.supportAgentId,
    this.supportAgentName,
    this.processingProgress,
    this.processingLabel,
  });

  final String messageId;
  final String fromUserId;
  final String toUserId;
  final ChatMessageType messageType;
  final String content;
  final DateTime sentAtUtc;
  final String? relativeTime;
  final bool isEdited;
  final MessageDeliveryStatus deliveryStatus;
  final bool isSeen;
  final bool isDelivered;
  final String? supportAgentId;
  final String? supportAgentName;
  final double? processingProgress;
  final String? processingLabel;

  String get contentUrl {
    if (content.startsWith('http://') || content.startsWith('https://')) {
      return ApiConstants.rewriteMediaUrl(content);
    }
    if (content.startsWith('/chat-') || content.startsWith('/Chat/')) {
      return '${ApiConstants.apiOrigin}$content';
    }
    return ApiConstants.resolveMediaUrl(content);
  }

  String get videoUrl {
    if (messageType != ChatMessageType.video) return contentUrl;
    if (!content.startsWith('/chat-videos/')) return contentUrl;
    final encoded = Uri.encodeComponent(content);
    return '${ApiConstants.baseUrl}/Chat/video?path=$encoded';
  }

  ChatMessageModel copyWith({
    String? messageId,
    String? fromUserId,
    String? toUserId,
    ChatMessageType? messageType,
    String? content,
    DateTime? sentAtUtc,
    String? relativeTime,
    bool? isEdited,
    MessageDeliveryStatus? deliveryStatus,
    bool? isSeen,
    bool? isDelivered,
    String? supportAgentId,
    String? supportAgentName,
    double? processingProgress,
    String? processingLabel,
    bool clearProcessingProgress = false,
    bool clearProcessingLabel = false,
  }) {
    return ChatMessageModel(
      messageId: messageId ?? this.messageId,
      fromUserId: fromUserId ?? this.fromUserId,
      toUserId: toUserId ?? this.toUserId,
      messageType: messageType ?? this.messageType,
      content: content ?? this.content,
      sentAtUtc: sentAtUtc ?? this.sentAtUtc,
      relativeTime: relativeTime ?? this.relativeTime,
      isEdited: isEdited ?? this.isEdited,
      deliveryStatus: deliveryStatus ?? this.deliveryStatus,
      isSeen: isSeen ?? this.isSeen,
      isDelivered: isDelivered ?? this.isDelivered,
      supportAgentId: supportAgentId ?? this.supportAgentId,
      supportAgentName: supportAgentName ?? this.supportAgentName,
      processingProgress: clearProcessingProgress
          ? null
          : (processingProgress ?? this.processingProgress),
      processingLabel: clearProcessingLabel
          ? null
          : (processingLabel ?? this.processingLabel),
    );
  }

  factory ChatMessageModel.fromJson(Map<String, dynamic> json) {
    final isSeen = json['isSeen'] as bool? ?? json['IsSeen'] as bool? ?? false;
    final isDelivered =
        json['isDelivered'] as bool? ?? json['IsDelivered'] as bool? ?? false;
    return ChatMessageModel(
      messageId: (json['messageId'] ?? json['id'] ?? '').toString(),
      fromUserId: (json['fromUserId'] ?? json['fromId'] ?? '').toString(),
      toUserId: (json['toUserId'] ?? json['toId'] ?? '').toString(),
      messageType: ChatMessageType.fromApi(json['messageType']),
      content: (json['content'] ?? json['message'] ?? '').toString(),
      sentAtUtc: UtcDateTime.parseAsUtc(
            (json['sentAtUtc'] ?? json['sentAt'])?.toString(),
          ) ??
          DateTime.now().toUtc(),
      relativeTime: json['relativeTime']?.toString(),
      isEdited: json['isEdited'] as bool? ?? false,
      isSeen: isSeen,
      isDelivered: isDelivered || isSeen,
      supportAgentId:
          (json['supportAgentId'] ?? json['SupportAgentId'])?.toString(),
      supportAgentName:
          (json['supportAgentName'] ?? json['SupportAgentName'])?.toString(),
    );
  }
}
