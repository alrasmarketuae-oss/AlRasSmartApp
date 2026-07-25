enum ChatMessageType {
  text(1),
  voice(2),
  image(3),
  location(4),
  video(5);

  const ChatMessageType(this.apiValue);
  final int apiValue;

  static ChatMessageType fromApi(dynamic value) {
    final intValue = value is int
        ? value
        : int.tryParse(value?.toString() ?? '') ?? 1;
    return ChatMessageType.values.firstWhere(
      (e) => e.apiValue == intValue,
      orElse: () => ChatMessageType.text,
    );
  }
}

enum MessageDeliveryStatus { sending, sent, failed }
