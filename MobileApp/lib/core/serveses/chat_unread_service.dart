import 'package:alrasmarket/core/services/api_constants.dart';
import 'package:alrasmarket/core/services/dio_helper.dart';
import 'package:alrasmarket/core/serveses/auth_service.dart';
import 'package:flutter/foundation.dart';

/// Unread direct-chat badge (profile tab + Live Chat shortcut).
class ChatUnreadService extends ChangeNotifier {
  ChatUnreadService._();
  static final ChatUnreadService instance = ChatUnreadService._();

  int unreadCount = 0;
  bool _refreshing = false;

  void resetForLogout() {
    unreadCount = 0;
    notifyListeners();
  }

  /// Optimistically clear when the open conversation was marked seen.
  void clearLocal() {
    if (unreadCount == 0) return;
    unreadCount = 0;
    notifyListeners();
  }

  Future<void> refreshUnreadCount() async {
    final token = AuthService.instance.currentToken;
    if (token == null || token.isEmpty) {
      if (unreadCount != 0) {
        unreadCount = 0;
        notifyListeners();
      }
      return;
    }

    if (_refreshing) return;
    _refreshing = true;
    try {
      final response = await DioHelper.getData(
        url: ApiConstants.chatUnreadCountEndPoint,
        token: token,
      );
      if (response?.statusCode != 200) return;

      final data = response?.data;
      var next = 0;
      if (data is Map) {
        next = int.tryParse(
              (data['totalUnread'] ?? data['TotalUnread'])?.toString() ?? '',
            ) ??
            0;
      }
      if (next != unreadCount) {
        unreadCount = next;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('ChatUnreadService.refreshUnreadCount failed: $e');
    } finally {
      _refreshing = false;
    }
  }
}
