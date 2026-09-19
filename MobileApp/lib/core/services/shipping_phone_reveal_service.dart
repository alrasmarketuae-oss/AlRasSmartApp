import 'package:alrasmarket/core/helper/cach_helper.dart';
import 'package:alrasmarket/core/serveses/auth_service.dart';
import 'package:alrasmarket/core/serveses/cached_constants.dart' as cache;
import 'package:alrasmarket/core/services/api_constants.dart';
import 'package:alrasmarket/core/services/dio_helper.dart';
import 'package:flutter/foundation.dart';

class ShippingPhoneRevealService {
  ShippingPhoneRevealService._();

  /// Posts successfully tracked in this app session (avoid duplicate spam).
  static final Set<int> _trackedPostIds = <int>{};

  static String? _resolveToken() {
    final fromAuth = AuthService.instance.currentToken?.trim();
    if (fromAuth != null && fromAuth.isNotEmpty) return fromAuth;
    final fromCacheConst = cache.token?.trim();
    if (fromCacheConst != null && fromCacheConst.isNotEmpty) {
      return fromCacheConst;
    }
    final fromPrefs = CachHelper.getData('token')?.toString().trim();
    if (fromPrefs != null && fromPrefs.isNotEmpty) return fromPrefs;
    return null;
  }

  /// Records a "show number" tap for [postId]. Safe to call fire-and-forget.
  static Future<void> trackReveal(int postId) async {
    if (postId <= 0) {
      debugPrint('[ShippingPhoneReveal] skip: invalid postId=$postId');
      return;
    }
    if (_trackedPostIds.contains(postId)) {
      debugPrint('[ShippingPhoneReveal] skip: already tracked postId=$postId');
      return;
    }

    final token = _resolveToken();
    if (token == null) {
      debugPrint('[ShippingPhoneReveal] skip: no auth token (guest)');
      return;
    }

    // Mark only after success so transient failures can retry.
    try {
      final response = await DioHelper.postData(
        url: ApiConstants.internationalShippingRevealPhoneEndPoint(postId),
        data: const <String, dynamic>{},
        token: token,
      );
      final status = response?.statusCode ?? 0;
      if (status >= 200 && status < 300) {
        _trackedPostIds.add(postId);
        debugPrint('[ShippingPhoneReveal] tracked postId=$postId');
      } else {
        debugPrint(
          '[ShippingPhoneReveal] failed postId=$postId status=$status body=${response?.data}',
        );
      }
    } catch (e) {
      debugPrint('[ShippingPhoneReveal] error postId=$postId err=$e');
    }
  }
}
