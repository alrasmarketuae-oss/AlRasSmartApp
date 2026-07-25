import 'package:alrasmarket/core/services/api_constants.dart';

class ChatContactModel {
  const ChatContactModel({
    required this.contactUserId,
    required this.displayName,
    this.avatarUrl,
    this.lastMessagePreview,
    this.lastMessageType,
    this.lastMessageRelativeTime,
    this.lastMessageSentAtUtc,
    this.unreadCount = 0,
    this.isOnline = false,
  });

  final String contactUserId;
  final String displayName;
  final String? avatarUrl;
  final String? lastMessagePreview;
  final String? lastMessageType;
  final String? lastMessageRelativeTime;
  final String? lastMessageSentAtUtc;
  final int unreadCount;
  final bool isOnline;

  String? get avatarUrlAbsolute {
    final url = avatarUrl;
    if (url == null || url.isEmpty) return null;
    return ApiConstants.resolveMediaUrl(url);
  }

  factory ChatContactModel.fromJson(Map<String, dynamic> json) {
    return ChatContactModel(
      contactUserId:
          (json['contactUserId'] ?? json['contactId'] ?? '').toString(),
      displayName: (json['displayName'] ?? 'User').toString(),
      avatarUrl: json['avatarUrl']?.toString(),
      lastMessagePreview: json['lastMessagePreview']?.toString(),
      lastMessageType: json['lastMessageType']?.toString(),
      lastMessageRelativeTime: json['lastMessageRelativeTime']?.toString(),
      lastMessageSentAtUtc: json['lastMessageSentAtUtc']?.toString(),
      unreadCount: json['unreadCount'] as int? ?? 0,
      isOnline: json['isOnline'] as bool? ?? false,
    );
  }
}
