class AppNotificationModel {
  const AppNotificationModel({
    required this.id,
    required this.title,
    required this.body,
    this.referenceId = '',
    this.routeId = '',
    this.routeName = '',
    this.typeName = '',
    this.isRead = true,
    this.createdAt,
  });

  final String id;
  final String title;
  final String body;
  final String referenceId;
  final String routeId;
  final String routeName;
  final String typeName;
  final bool isRead;
  final DateTime? createdAt;

  String get navigationRoute {
    final name = routeName.trim();
    if (name.isNotEmpty) return name;
    return routeId;
  }

  factory AppNotificationModel.fromJson(Map<String, dynamic> json) {
    DateTime? created;
    final rawCreated = json['createdAt'] ?? json['CreatedAt'];
    if (rawCreated != null) {
      created = DateTime.tryParse(rawCreated.toString())?.toLocal();
    }

    final isReadRaw = json['isRead'] ?? json['IsRead'];
    final isRead = isReadRaw == true ||
        isReadRaw?.toString().toLowerCase() == 'true';

    return AppNotificationModel(
      id: (json['id'] ?? json['Id'] ?? '').toString(),
      title: (json['title'] ?? json['Title'] ?? '').toString(),
      body: (json['body'] ?? json['Body'] ?? '').toString(),
      referenceId: (json['referenceId'] ?? json['ReferenceId'] ?? '').toString(),
      routeId: (json['routeId'] ?? json['RouteId'] ?? '').toString(),
      routeName: (json['routeName'] ?? json['RouteName'] ?? '').toString(),
      typeName: (json['typeName'] ?? json['TypeName'] ?? '').toString(),
      isRead: isRead,
      createdAt: created,
    );
  }
}

class AppNotificationsPageModel {
  const AppNotificationsPageModel({
    required this.items,
    required this.totalCount,
    this.unreadCount = 0,
    this.page = 1,
    this.pageSize = 50,
  });

  final List<AppNotificationModel> items;
  final int totalCount;
  final int unreadCount;
  final int page;
  final int pageSize;

  factory AppNotificationsPageModel.fromJson(Map<String, dynamic> json) {
    final raw = json['items'] as List<dynamic>? ?? const [];
    return AppNotificationsPageModel(
      totalCount: int.tryParse(json['totalCount']?.toString() ?? '') ?? raw.length,
      unreadCount: int.tryParse(json['unreadCount']?.toString() ?? '') ?? 0,
      page: int.tryParse(json['page']?.toString() ?? '') ?? 1,
      pageSize: int.tryParse(json['pageSize']?.toString() ?? '') ?? raw.length,
      items: raw
          .whereType<Map>()
          .map((e) => AppNotificationModel.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
    );
  }
}
