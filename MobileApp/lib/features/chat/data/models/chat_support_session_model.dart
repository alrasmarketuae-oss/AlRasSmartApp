class ChatSupportSessionModel {
  const ChatSupportSessionModel({
    required this.agentUserId,
    required this.agentName,
    required this.assignedAtUtc,
    this.releasedAtUtc,
    this.isActive = false,
    this.customerUserId,
  });

  final String agentUserId;
  final String agentName;
  final DateTime assignedAtUtc;
  final DateTime? releasedAtUtc;
  final bool isActive;
  final String? customerUserId;

  factory ChatSupportSessionModel.fromJson(
    Map<String, dynamic> json, {
    bool? forceActive,
  }) {
    final assigned = DateTime.tryParse(
          (json['assignedAtUtc'] ?? json['AssignedAtUtc'] ?? '').toString(),
        ) ??
        DateTime.now().toUtc();
    final releasedRaw = json['releasedAtUtc'] ?? json['ReleasedAtUtc'];
    final released = releasedRaw == null
        ? null
        : DateTime.tryParse(releasedRaw.toString());
    final activeFlag = json['isActive'] as bool? ??
        json['IsActive'] as bool? ??
        released == null;

    return ChatSupportSessionModel(
      agentUserId:
          (json['agentUserId'] ?? json['AgentUserId'] ?? '').toString(),
      agentName: (json['agentName'] ?? json['AgentName'] ?? 'Support')
          .toString(),
      assignedAtUtc: assigned,
      releasedAtUtc: released,
      isActive: forceActive ?? activeFlag,
      customerUserId:
          (json['customerUserId'] ?? json['CustomerUserId'])?.toString(),
    );
  }

  ChatSupportSessionModel copyWith({
    String? agentUserId,
    String? agentName,
    DateTime? assignedAtUtc,
    DateTime? releasedAtUtc,
    bool? isActive,
    String? customerUserId,
    bool clearReleasedAt = false,
  }) {
    return ChatSupportSessionModel(
      agentUserId: agentUserId ?? this.agentUserId,
      agentName: agentName ?? this.agentName,
      assignedAtUtc: assignedAtUtc ?? this.assignedAtUtc,
      releasedAtUtc:
          clearReleasedAt ? null : (releasedAtUtc ?? this.releasedAtUtc),
      isActive: isActive ?? this.isActive,
      customerUserId: customerUserId ?? this.customerUserId,
    );
  }
}
