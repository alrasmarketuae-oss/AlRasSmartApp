class ConversationSeenEvent {
  const ConversationSeenEvent({
    required this.viewerUserId,
    required this.otherUserId,
    this.seenAtUtc,
  });

  final String viewerUserId;
  final String otherUserId;
  final DateTime? seenAtUtc;

  factory ConversationSeenEvent.fromJson(Map<String, dynamic> json) {
    return ConversationSeenEvent(
      viewerUserId: (json['viewerUserId'] ?? '').toString(),
      otherUserId: (json['otherUserId'] ?? '').toString(),
      seenAtUtc: json['seenAtUtc'] != null
          ? DateTime.tryParse(json['seenAtUtc'].toString())
          : null,
    );
  }
}
