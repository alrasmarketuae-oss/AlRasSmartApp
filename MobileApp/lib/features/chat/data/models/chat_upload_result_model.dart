import 'package:alrasmarket/features/chat/data/models/chat_message_type.dart';

class ChatUploadResultModel {
  const ChatUploadResultModel({
    required this.content,
    required this.messageType,
  });

  final String content;
  final ChatMessageType messageType;

  factory ChatUploadResultModel.fromJson(Map<String, dynamic> json) {
    return ChatUploadResultModel(
      content: (json['content'] ?? '').toString(),
      messageType: ChatMessageType.fromApi(json['messageType']),
    );
  }
}
