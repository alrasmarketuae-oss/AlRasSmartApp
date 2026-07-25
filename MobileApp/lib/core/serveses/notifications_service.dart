import 'package:alrasmarket/core/services/api_constants.dart';
import 'package:alrasmarket/core/services/dio_helper.dart';
import 'package:alrasmarket/core/serveses/auth_service.dart';
import 'package:alrasmarket/features/clint/data/models/app_notification_model.dart';
import 'package:flutter/foundation.dart';

class NotificationsService extends ChangeNotifier {
  NotificationsService._();
  static final NotificationsService instance = NotificationsService._();

  int unreadCount = 0;

  Future<AppNotificationsPageModel> fetchMine({
    int page = 1,
    int pageSize = 50,
  }) async {
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
    notifyListeners();
    return pageModel;
  }

  Future<void> refreshUnreadCount() async {
    final token = AuthService.instance.currentToken;
    if (token == null || token.isEmpty) {
      unreadCount = 0;
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
      unreadCount =
          int.tryParse(map['unreadCount']?.toString() ?? '') ?? unreadCount;
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
