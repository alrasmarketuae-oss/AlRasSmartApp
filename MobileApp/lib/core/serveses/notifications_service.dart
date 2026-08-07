import 'package:alrasmarket/core/services/api_constants.dart';
import 'package:alrasmarket/core/services/dio_helper.dart';
import 'package:alrasmarket/core/serveses/auth_service.dart';
import 'package:alrasmarket/features/clint/data/models/app_notification_model.dart';
import 'package:flutter/foundation.dart';

class NotificationsService extends ChangeNotifier {
  NotificationsService._();
  static final NotificationsService instance = NotificationsService._();

  int unreadCount = 0;

  /// In-memory list cache for the current login session (page 1).
  List<AppNotificationModel>? _sessionItems;
  int _sessionTotalCount = 0;
  int _sessionPageSize = 20;
  String? _sessionUserId;

  bool get hasUsableSessionListCache {
    final userId = AuthService.instance.currentUserID;
    if (_sessionItems == null ||
        userId == null ||
        userId.isEmpty ||
        userId != _sessionUserId) {
      return false;
    }
    // New notification arrived (badge > 0) → skip cache and hit the API.
    if (unreadCount > 0) return false;
    return true;
  }

  AppNotificationsPageModel? peekSessionPage1() {
    if (!hasUsableSessionListCache) return null;
    return AppNotificationsPageModel(
      items: List<AppNotificationModel>.from(_sessionItems!),
      totalCount: _sessionTotalCount,
      unreadCount: unreadCount,
      page: 1,
      pageSize: _sessionPageSize,
    );
  }

  void clearSessionListCache() {
    _sessionItems = null;
    _sessionTotalCount = 0;
    _sessionPageSize = 20;
    _sessionUserId = null;
  }

  /// Clears list cache + unread badge (logout / session wipe).
  void resetForLogout() {
    clearSessionListCache();
    unreadCount = 0;
    notifyListeners();
  }

  void _saveSessionPage1(
    AppNotificationsPageModel page, {
    List<AppNotificationModel>? displayItems,
  }) {
    final userId = AuthService.instance.currentUserID;
    if (userId == null || userId.isEmpty) return;
    _sessionUserId = userId;
    _sessionItems = List<AppNotificationModel>.from(
      displayItems ?? page.items,
    );
    _sessionTotalCount = page.totalCount;
    _sessionPageSize = page.pageSize;
  }

  /// Keep cache in sync after mark-all-read remaps items locally.
  void updateSessionItems(List<AppNotificationModel> items) {
    if (_sessionItems == null) return;
    final userId = AuthService.instance.currentUserID;
    if (userId == null || userId != _sessionUserId) return;
    _sessionItems = List<AppNotificationModel>.from(items);
  }

  Future<AppNotificationsPageModel> fetchMine({
    int page = 1,
    int pageSize = 50,
    bool forceRefresh = false,
  }) async {
    if (page == 1 && !forceRefresh) {
      final cached = peekSessionPage1();
      if (cached != null) return cached;
    }

    final response = await DioHelper.getData(
      url: ApiConstants.notificationsMineEndPoint,
      query: {'page': page, 'pageSize': pageSize},
      token: AuthService.instance.currentToken,
    );

    if (response?.statusCode != 200) {
      throw Exception('Failed to load notifications');
    }

    final data = response?.data;
    if (data is! Map) {
      throw Exception('Invalid notifications response');
    }

    final pageModel =
        AppNotificationsPageModel.fromJson(Map<String, dynamic>.from(data));
    unreadCount = pageModel.unreadCount;
    if (page == 1) {
      _saveSessionPage1(pageModel);
    }
    notifyListeners();
    return pageModel;
  }

  Future<void> refreshUnreadCount() async {
    final token = AuthService.instance.currentToken;
    if (token == null || token.isEmpty) {
      unreadCount = 0;
      clearSessionListCache();
      notifyListeners();
      return;
    }

    try {
      final response = await DioHelper.getData(
        url: ApiConstants.notificationsUnreadCountEndPoint,
        token: token,
      );
      if (response?.statusCode != 200 || response?.data is! Map) return;
      final map = Map<String, dynamic>.from(response!.data as Map);
      final next =
          int.tryParse(map['unreadCount']?.toString() ?? '') ?? unreadCount;
      unreadCount = next;
      // Drop stale list when something new arrives.
      if (next > 0) {
        clearSessionListCache();
      }
      notifyListeners();
    } catch (_) {
      // keep last known count
    }
  }

  Future<void> markRead(String notificationId) async {
    final token = AuthService.instance.currentToken;
    if (token == null || token.isEmpty || notificationId.isEmpty) return;

    await DioHelper.postData(
      url: ApiConstants.notificationMarkReadEndPoint(notificationId),
      data: const {},
      token: token,
    );
    if (unreadCount > 0) {
      unreadCount -= 1;
      notifyListeners();
    }
  }

  Future<void> markAllRead() async {
    final token = AuthService.instance.currentToken;
    if (token == null || token.isEmpty) return;

    await DioHelper.postData(
      url: ApiConstants.notificationsMarkAllReadEndPoint,
      data: const {},
      token: token,
    );
    unreadCount = 0;
    notifyListeners();
  }
}
