import 'package:alrasmarket/core/services/api_constants.dart';
import 'package:alrasmarket/core/services/dio_helper.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class UserPreferencesService {
  UserPreferencesService._();

  static final UserPreferencesService instance = UserPreferencesService._();

  static String _normalizeLanguage(String languageCode) {
    return languageCode.toLowerCase() == 'ar' ? 'ar' : 'en';
  }

  /// PUT /api/UserPreferences/language — requires auth token.
  Future<bool> updatePreferredLanguage({
    required String languageCode,
    required String token,
  }) async {
    final language = _normalizeLanguage(languageCode);
    if (token.isEmpty) return false;

    try {
      final response = await DioHelper.putData(
        url: ApiConstants.userPreferredLanguageEndPoint,
        token: token,
        data: {'Language': language},
      );

      if (response?.statusCode == 200) {
        debugPrint('Preferred language updated to $language');
        return true;
      }

      debugPrint(
        'Failed to update preferred language: ${response?.statusCode} ${response?.data}',
      );
      return false;
    } on DioException catch (e) {
      debugPrint('Failed to update preferred language: ${e.message}');
      return false;
    } catch (e) {
      debugPrint('Failed to update preferred language: $e');
      return false;
    }
  }
}
