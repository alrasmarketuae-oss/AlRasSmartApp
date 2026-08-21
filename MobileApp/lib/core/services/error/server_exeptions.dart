import 'package:dio/dio.dart';
import '/core/services/error/api_error_model.dart';
import '/core/utils/dio_user_facing_message.dart';

class ServerException implements Exception {
  final ApiErrorModel errModel;
  const ServerException({required this.errModel});

  static void handleDioExceptions(DioException e) {
    final busy = DioUserFacingMessage.englishHighDemand;

    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.connectionError:
        throw ServerException(
          errModel: ApiErrorModel(message: busy, error: busy),
        );
      case DioExceptionType.cancel:
        throw ServerException(
          errModel: ApiErrorModel(message: busy, error: busy),
        );
      case DioExceptionType.badCertificate:
        throw ServerException(
          errModel: ApiErrorModel(message: busy, error: busy),
        );
      case DioExceptionType.unknown:
        throw ServerException(
          errModel: ApiErrorModel(
            message: DioUserFacingMessage.fromDio(e),
            error: DioUserFacingMessage.fromDio(e),
          ),
        );
      case DioExceptionType.badResponse:
        final status = e.response?.statusCode;
        if (status != null &&
            (status == 429 ||
                status == 500 ||
                status == 502 ||
                status == 503 ||
                status == 504 ||
                status >= 520)) {
          throw ServerException(
            errModel: ApiErrorModel(message: busy, error: busy),
          );
        }

        final parsed = _tryParseApiError(e.response?.data);
        if (parsed != null) {
          throw ServerException(errModel: parsed);
        }

        throw ServerException(
          errModel: ApiErrorModel(
            message: DioUserFacingMessage.fromDio(e),
            error: DioUserFacingMessage.fromDio(e),
          ),
        );
    }
  }

  static ApiErrorModel? _tryParseApiError(dynamic data) {
    try {
      if (data is Map<String, dynamic>) {
        return ApiErrorModel.fromJson(data);
      }
      if (data is Map) {
        return ApiErrorModel.fromJson(Map<String, dynamic>.from(data));
      }
    } catch (_) {
      return null;
    }
    return null;
  }
}
