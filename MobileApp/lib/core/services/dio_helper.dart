import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter/foundation.dart';

import 'api_constants.dart';
import '../helper/cach_helper.dart';
import '../serveses/cached_constants.dart' as cache;

class DioHelper {
  static Dio? dio;
  String i = ApiConstants.baseUrl;

  static String? _resolveToken(String? token) => token ?? cache.token;

  static String _preferredLanguage() {
    final raw = CachHelper.getData('languageCode')?.toString() ??
        CachHelper.getData('locale')?.toString() ??
        'en';
    return raw.trim().toLowerCase().startsWith('ar') ? 'ar' : 'en';
  }

  static Map<String, dynamic> _authHeaders({String? token}) {
    final language = _preferredLanguage();
    return {
      'x-auth-token': _resolveToken(token),
      'Authorization': 'Bearer ${_resolveToken(token)}',
      'X-Preferred-Language': language,
      'Accept-Language': language,
    };
  }

  static init() {
    dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        receiveDataWhenStatusError: true,
        // Mobile networks / cold API starts often exceed 25s; keep generous.
        connectTimeout: const Duration(seconds: 45),
        receiveTimeout: const Duration(seconds: 60),
        sendTimeout: const Duration(seconds: 45),
      ),
    );

    dio!.interceptors.add(
      _RetryOnTransientErrorInterceptor(dio!, maxRetries: 2),
    );

    // Local API (LAN / self-signed): accept bad certificates when isLocal.
    // Production (isLocal=false) keeps strict TLS.
    if (kDebugMode || ApiConstants.isLocal) {
      dio!.httpClientAdapter = IOHttpClientAdapter(
        createHttpClient: () {
          final client = HttpClient();
          client.badCertificateCallback = (cert, host, port) => true;
          return client;
        },
      );
    }
  }

  static Future<Response?>? getData({
    required String url,
    Map<String, dynamic>? query,
    Map<String, dynamic>? data,
    String lan = 'ar',
    String? token,
    Duration? receiveTimeout,
  }) async {
    dio!.options.headers = {
      'Content-Type': 'application/json',
      ..._authHeaders(token: token),
    };
    final x = await dio?.get(
      url,
      data: data,
      queryParameters: query,
      options: receiveTimeout == null
          ? null
          : Options(receiveTimeout: receiveTimeout),
    );
    return x;
  }

  static Future<Response?>? postData({
    required String url,
    Map<String, dynamic>? query,
    required Object? data, // body: Map or List for JSON
    String lan = 'en',
    String? token,
  }) async {
    dio!.options.headers = {
      'Content-Type': 'application/json',
      ..._authHeaders(token: token),
    };
    print("0000post  ${url}");
    final x = await dio?.post(url, queryParameters: query, data: data);
    print("x: ${x?.data}");
    return x;
  }

  static Future<Response?>? putData({
    required String url,
    Map<String, dynamic>? query,
    required Object? data, //body
    String lan = 'en',
    String? token,
  }) async {
    dio!.options.headers = {
      'Content-Type': 'application/json',
      ..._authHeaders(token: token),
    };
    final x = await dio?.put(url, queryParameters: query, data: data);
    return x;
  }

  static Future<Response?>? patchData({
    required String url,
    Map<String, dynamic>? query,
    required Object? data,
    String? token,
  }) async {
    dio!.options.headers = {
      'Content-Type': 'application/json',
      ..._authHeaders(token: token),
    };
    final x = await dio?.patch(url, queryParameters: query, data: data);
    return x;
  }

  /// PUT multipart (e.g. update product).
  static Future<Response?>? putUpload({
    required String url,
    required FormData formData,
    String? token,
    ProgressCallback? onSendProgress,
  }) async {
    dio!.options.headers = {
      ..._authHeaders(token: token),
    };
    try {
      return await dio?.put(
        url,
        data: formData,
        onSendProgress: onSendProgress,
        options: Options(
          contentType: 'multipart/form-data',
          sendTimeout: const Duration(minutes: 5),
          receiveTimeout: const Duration(minutes: 5),
        ),
      );
    } on DioException catch (e) {
      return e.response;
    }
  }

  /// Upload file using FormData
  static Future<Response?>? uploadFile({
    required String url,
    required FormData formData,
    String? token,
    ProgressCallback? onSendProgress,
  }) async {
    debugPrint('[Upload] URL: $url');

    dio!.options.headers = {
      ..._authHeaders(token: token),
    };
    try {
      final x = await dio?.post(
        url,
        data: formData,
        onSendProgress: onSendProgress,
        options: Options(
          contentType: 'multipart/form-data',
          sendTimeout: const Duration(minutes: 5),
          receiveTimeout: const Duration(minutes: 5),
        ),
      );
      return x;
    } on DioException catch (e) {
      final response = e.response;
      if (response != null) {
        debugPrint('Error uploading file (${response.statusCode}): ${response.data}');
        return response;
      }
      debugPrint('Error uploading file: $e');
      return null;
    } catch (e) {
      debugPrint('Error uploading file: $e');
      return null;
    }

  }

  /// Direct PUT to an absolute URL (e.g. Cloudflare R2 presigned). No API auth headers.
  static Future<Response?> putBytesToAbsoluteUrl({
    required String url,
    required File file,
    required String contentType,
    ProgressCallback? onSendProgress,
  }) async {
    final length = await file.length();
    final client = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 30),
        sendTimeout: const Duration(minutes: 10),
        receiveTimeout: const Duration(minutes: 2),
        validateStatus: (status) => status != null && status < 500,
      ),
    );

    try {
      return await client.put(
        url,
        data: file.openRead(),
        onSendProgress: onSendProgress,
        options: Options(
          headers: {
            Headers.contentTypeHeader: contentType,
            Headers.contentLengthHeader: length,
          },
          contentType: contentType,
        ),
      );
    } on DioException catch (e) {
      debugPrint('Direct PUT failed (${e.response?.statusCode}): ${e.message}');
      return e.response;
    } finally {
      client.close();
    }
  }

  static Future<Response?>? deleteData({
    required String url,
    Map<String, dynamic>? query,
    Map<String, dynamic>? data,
    String lan = 'en',
    String? token,
  }) async {
    dio!.options.headers = {
      'Content-Type': 'application/json',
      ..._authHeaders(token: token),
    };
    final x = await dio?.delete(url, data: data, queryParameters: query);
    return x;
  }

  /// GET with a full absolute URL (ignores [dio] baseUrl). For dev/LAN endpoints.
  static Future<Response<dynamic>> getFullUrl(
    String fullUrl, {
    Map<String, dynamic>? headers,
  }) async {
    final client = Dio(
      BaseOptions(
        receiveDataWhenStatusError: true,
        headers: headers ?? const {'accept': '*/*'},
      ),
    );
    if (kDebugMode) {
      client.httpClientAdapter = IOHttpClientAdapter(
        createHttpClient: () {
          final httpClient = HttpClient();
          httpClient.badCertificateCallback = (cert, host, port) => true;
          return httpClient;
        },
      );
    }
    return client.get<dynamic>(fullUrl);
  }
}

/// Retries idempotent GETs on transient network/timeout failures.
class _RetryOnTransientErrorInterceptor extends Interceptor {
  _RetryOnTransientErrorInterceptor(this._dio, {this.maxRetries = 2});

  final Dio _dio;
  final int maxRetries;
  static const _retryExtraKey = 'transient_retry_count';

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (!_shouldRetry(err)) {
      return handler.next(err);
    }

    final attempt = (err.requestOptions.extra[_retryExtraKey] as int?) ?? 0;
    if (attempt >= maxRetries) {
      return handler.next(err);
    }

    final nextAttempt = attempt + 1;
    err.requestOptions.extra[_retryExtraKey] = nextAttempt;
    final delayMs = 500 * nextAttempt;
    debugPrint(
      '[Dio] transient ${err.type} on ${err.requestOptions.method} '
      '${err.requestOptions.path}; retry $nextAttempt/$maxRetries in ${delayMs}ms',
    );
    await Future<void>.delayed(Duration(milliseconds: delayMs));

    try {
      final response = await _dio.fetch<dynamic>(err.requestOptions);
      return handler.resolve(response);
    } on DioException catch (retryError) {
      return handler.next(retryError);
    } catch (e) {
      return handler.next(
        DioException(requestOptions: err.requestOptions, error: e),
      );
    }
  }

  bool _shouldRetry(DioException err) {
    final method = err.requestOptions.method.toUpperCase();
    if (method != 'GET' && method != 'HEAD') return false;
    switch (err.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.connectionError:
        return true;
      case DioExceptionType.unknown:
        // DNS / socket resets often land here without a response.
        return err.response == null;
      default:
        return false;
    }
  }
}

/*  {
                "name": name,
                "description": description,
                "images": imagesUrl,
                "quantity": quantity,
                "price": price,
                "category": categoriesValue,
              } */
