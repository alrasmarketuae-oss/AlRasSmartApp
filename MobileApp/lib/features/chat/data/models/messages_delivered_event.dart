class MessagesDeliveredEvent {
  const MessagesDeliveredEvent({
    required this.fromUserId,
    required this.toUserId,
    required this.messageIds,
    this.deliveredAtUtc,
  });

  final String fromUserId;
  final String toUserId;
  final List<String> messageIds;
  final DateTime? deliveredAtUtc;

  factory MessagesDeliveredEvent.fromJson(Map<String, dynamic> json) {
    final ids = json['messageIds'] ?? json['MessageIds'];
    return MessagesDeliveredEvent(
      fromUserId: (json['fromUserId'] ?? json['FromUserId'] ?? '').toString(),
      toUserId: (json['toUserId'] ?? json['ToUserId'] ?? '').toString(),
      messageIds: ids is List
          ? ids.map((e) => e.toString()).toList()
          : const <String>[],
      deliveredAtUtc: json['deliveredAtUtc'] != null
          ? DateTime.tryParse(json['deliveredAtUtc'].toString())
          : (json['DeliveredAtUtc'] != null
              ? DateTime.tryParse(json['DeliveredAtUtc'].toString())
              : null),
    );
  }
}
