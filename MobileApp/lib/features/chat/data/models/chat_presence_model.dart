class ChatPresenceModel {
  const ChatPresenceModel({
    required this.userId,
    this.lastSeenAtUtc,
    this.isOnline = false,
  });

  final String userId;
  final String? lastSeenAtUtc;
  final bool isOnline;

  DateTime? get lastSeenAt {
    if (lastSeenAtUtc == null || lastSeenAtUtc!.isEmpty) return null;
    return DateTime.tryParse(lastSeenAtUtc!);
  }

  factory ChatPresenceModel.fromJson(Map<String, dynamic> json) {
    return ChatPresenceModel(
      userId: (json['userId'] ?? '').toString(),
      lastSeenAtUtc: json['lastSeenAtUtc']?.toString(),
      isOnline: json['isOnline'] as bool? ?? false,
    );
  }
}
