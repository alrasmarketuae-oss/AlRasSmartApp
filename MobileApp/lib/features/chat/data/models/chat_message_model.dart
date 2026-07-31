import 'dart:convert';

import 'package:alrasmarket/core/services/api_constants.dart';
import 'package:alrasmarket/core/utils/utc_date_time.dart';
import 'package:alrasmarket/features/chat/data/models/chat_message_type.dart';

class ChatFileContent {
  const ChatFileContent({
    required this.path,
    required this.name,
    required this.sizeBytes,
    required this.mimeType,
  });

  final String path;
  final String name;
  final int sizeBytes;
  final String mimeType;

  String? get readableSize {
    if (sizeBytes <= 0) return null;
    const units = ['B', 'KB', 'MB', 'GB'];
    var value = sizeBytes.toDouble();
    var unitIndex = 0;
    while (value >= 1024 && unitIndex < units.length - 1) {
      value /= 1024;
      unitIndex++;
    }
    final rounded = value >= 10 || unitIndex == 0
        ? value.round().toString()
        : value.toStringAsFixed(1);
    return '$rounded ${units[unitIndex]}';
  }
}

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

  /// Chat attachments live on the media CDN, except API routes such as
  /// `/Chat/voice` and `/Chat/video` which stream from the API host.
  String get contentUrl => resolveAttachmentUrl(content);

  static String resolveAttachmentUrl(String rawPath) {
    final trimmed = rawPath.trim();
    if (trimmed.isEmpty) return '';
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return ApiConstants.rewriteMediaUrl(trimmed);
    }
    if (trimmed.startsWith('/Chat/') || trimmed.startsWith('/api/')) {
      return '${ApiConstants.apiOrigin}$trimmed';
    }
    return ApiConstants.resolveMediaUrl(trimmed);
  }

  /// Image messages may carry a single path or a `{"images":[...]}` payload.
  List<String> get imagePaths {
    final trimmed = content.trim();
    if (trimmed.isEmpty) return const [];
    if (trimmed.startsWith('{') && trimmed.contains('"images"')) {
      try {
        final decoded = jsonDecode(trimmed);
        if (decoded is Map && decoded['images'] is List) {
          final paths = (decoded['images'] as List)
              .whereType<String>()
              .map((e) => e.trim())
              .where((e) => e.isNotEmpty)
              .toList();
          if (paths.isNotEmpty) return paths;
        }
      } catch (_) {
        // Fall through to the single-path case.
      }
    }
    return [trimmed];
  }

  String get videoUrl {
    if (messageType != ChatMessageType.video) return contentUrl;
    final normalized = _normalizedStoragePath;
    if (!normalized.startsWith('/chat-videos/')) return contentUrl;
    final encoded = Uri.encodeComponent(normalized);
    return '${ApiConstants.baseUrl}/Chat/video?path=$encoded';
  }

  /// Document messages carry `{"path":..,"name":..,"size":..,"mime":..}` because the
  /// stored object is renamed to a GUID and the original name must survive.
  ChatFileContent? get fileContent {
    final trimmed = content.trim();
    if (trimmed.isEmpty) return null;

    if (trimmed.startsWith('{')) {
      try {
        final decoded = jsonDecode(trimmed);
        if (decoded is! Map) return null;
        final path = decoded['path']?.toString().trim() ?? '';
        final name = decoded['name']?.toString().trim() ?? '';
        if (name.isEmpty && path.isEmpty) return null;
        return ChatFileContent(
          path: path,
          name: name.isNotEmpty ? name : path.split('/').last,
          sizeBytes: int.tryParse('${decoded['size']}') ?? 0,
          mimeType: decoded['mime']?.toString().trim() ?? '',
        );
      } catch (_) {
        return null;
      }
    }

    if (trimmed.startsWith('/chat-files/')) {
      return ChatFileContent(
        path: trimmed,
        name: trimmed.split('/').last,
        sizeBytes: 0,
        mimeType: '',
      );
    }

    return null;
  }

  /// Downloads through the API so the response keeps the original file name.
  String? get fileDownloadUrl {
    final file = fileContent;
    final path = file?.path.trim() ?? '';
    if (file == null || path.isEmpty) return null;
    final normalized = path.startsWith('/') ? path : '/$path';
    return '${ApiConstants.baseUrl}/Chat/file'
        '?path=${Uri.encodeComponent(normalized)}'
        '&name=${Uri.encodeComponent(file.name)}';
  }

  /// Streams through the API so the response carries a playable content type.
  String get voiceUrl {
    final normalized = _normalizedStoragePath;
    if (!normalized.startsWith('/chat-voice/')) return contentUrl;
    final encoded = Uri.encodeComponent(normalized);
    return '${ApiConstants.baseUrl}/Chat/voice?path=$encoded';
  }

  String get _normalizedStoragePath {
    final trimmed = content.trim().replaceAll('\\', '/');
    if (trimmed.isEmpty ||
        trimmed.startsWith('http://') ||
        trimmed.startsWith('https://')) {
      return '';
    }
    return trimmed.startsWith('/') ? trimmed : '/$trimmed';
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
