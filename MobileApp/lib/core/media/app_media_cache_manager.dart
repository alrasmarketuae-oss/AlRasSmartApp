import 'dart:io';

import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:http/io_client.dart';

/// Shared image disk cache — version bump clears poisoned CDN failures.
class AppMediaCacheManager {
  AppMediaCacheManager._();

  static const key = 'alras_media_cache_v3';

  static final CacheManager instance = CacheManager(
    Config(
      key,
      stalePeriod: const Duration(days: 21),
      maxNrOfCacheObjects: 400,
      fileService: HttpFileService(
        httpClient: IOClient(_createHttpClient()),
      ),
    ),
  );

  static HttpClient _createHttpClient() {
    final client = HttpClient();
    // Cloudflare sometimes challenges bare Dart clients; use a normal mobile UA.
    client.userAgent =
        'Mozilla/5.0 (Linux; Android 14) AppleWebKit/537.36 '
        '(KHTML, like Gecko) Chrome/122.0.0.0 Mobile Safari/537.36 '
        'AlRasMarket/1.0';
    client.connectionTimeout = const Duration(seconds: 25);
    client.idleTimeout = const Duration(seconds: 30);
    client.autoUncompress = true;
    return client;
  }
}
