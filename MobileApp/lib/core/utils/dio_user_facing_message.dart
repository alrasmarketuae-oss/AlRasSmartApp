import 'package:dio/dio.dart';

/// Friendly copy when the API is down, timed out, or overloaded.
/// Never surface raw Flutter/Dio exception strings to users.
class DioUserFacingMessage {
  DioUserFacingMessage._();

  static const englishHighDemand =
      'Sorry, we are receiving high demand right now. Please try again in a few seconds.';

  static const arabicHighDemand =
      'عذرًا، لدينا ضغط عالي على السيرفر حاليًا. حاول مرة أخرى خلال ثوانٍ.';

  static String highDemand({required bool isAr}) =>
      isAr ? arabicHighDemand : englishHighDemand;

  /// Prefer Arabic when [isAr] is true; otherwise English.
  static String fromDio(DioException e, {bool isAr = false}) {
    final fallback = highDemand(isAr: isAr);

    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.connectionError:
        return fallback;
      case DioExceptionType.cancel:
        return fallback;
      case DioExceptionType.badCertificate:
      case DioExceptionType.unknown:
      case DioExceptionType.badResponse:
        break;
    }

    final status = e.response?.statusCode;
    if (status != null && _isServerBusyStatus(status)) {
      return fallback;
    }

    final apiMessage = _extractApiMessage(e.response?.data);
    if (apiMessage != null &&
        apiMessage.isNotEmpty &&
        !_looksLikeTechnicalDump(apiMessage)) {
      return apiMessage;
    }

    if (_looksLikeTechnicalDump(e.message) ||
        _looksLikeTechnicalDump(e.toString())) {
      return fallback;
    }

    final raw = (e.message ?? '').trim();
    return raw.isEmpty ? fallback : raw;
  }

  /// Maps any caught object (DioException, ServerException text, etc.) to UI copy.
  static String sanitize(Object? error, {bool isAr = false}) {
    if (error is DioException) {
      return fromDio(error, isAr: isAr);
    }

    final text = (error?.toString() ?? '').trim();
    if (text.isEmpty || _looksLikeTechnicalDump(text)) {
      return highDemand(isAr: isAr);
    }
    return text;
  }

  static bool _isServerBusyStatus(int status) =>
      status == 408 ||
      status == 425 ||
      status == 429 ||
      status == 500 ||
      status == 502 ||
      status == 503 ||
      status == 504 ||
      status >= 520;

  static String? _extractApiMessage(dynamic data) {
    if (data == null) return null;
    if (data is String) {
      final t = data.trim();
      if (t.startsWith('{') || t.startsWith('<')) return null;
      return t.isEmpty ? null : t;
    }
    if (data is Map) {
      final message = data['message'] ?? data['Message'] ?? data['error'] ?? data['Error'];
      if (message is String && message.trim().isNotEmpty) {
        return message.trim();
      }
    }
    return null;
  }

  static bool _looksLikeTechnicalDump(String? value) {
    if (value == null) return false;
    final q = value.toLowerCase();
    return q.contains('dioexception') ||
        q.contains('dio error') ||
        q.contains('socketexception') ||
        q.contains('httpexception') ||
        q.contains('handshakeexception') ||
        q.contains('clientexception') ||
        q.contains('xmlhttprequest') ||
        q.contains('failed host lookup') ||
        q.contains('connection refused') ||
        q.contains('connection reset') ||
        q.contains('network is unreachable') ||
        q.contains('timed out') ||
        q.contains('timeout') ||
        q.contains('statuscode:') ||
        q.contains('status code') ||
        q.contains('requestoptions') ||
        q.contains('stack overflow') ||
        q.contains('formatException'.toLowerCase()) ||
        q.contains('null check operator') ||
        q.startsWith('exception:') ||
        q.startsWith('error:');
  }
}
