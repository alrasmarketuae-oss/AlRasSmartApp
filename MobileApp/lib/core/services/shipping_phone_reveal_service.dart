import 'package:alrasmarket/core/serveses/auth_service.dart';
import 'package:alrasmarket/core/services/api_constants.dart';
import 'package:alrasmarket/core/services/dio_helper.dart';

class ShippingPhoneRevealService {
  ShippingPhoneRevealService._();

  /// Tracks each "show number" tap once per post per app session.
  static final Set<int> _trackedPostIds = <int>{};

  static Future<void> trackReveal(int postId) async {
    if (postId <= 0 || _trackedPostIds.contains(postId)) return;

    final token = AuthService.instance.currentToken;
    if (token == null || token.trim().isEmpty) return;

    _trackedPostIds.add(postId);
    try {
      final response = await DioHelper.postData(
        url: ApiConstants.internationalShippingRevealPhoneEndPoint(postId),
        data: const {},
        token: token,
      );
      final status = response?.statusCode ?? 0;
      if (status < 200 || status >= 300) {
        _trackedPostIds.remove(postId);
      }
    } catch (_) {
      _trackedPostIds.remove(postId);
    }
  }
}
