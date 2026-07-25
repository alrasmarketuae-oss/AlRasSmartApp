import 'dart:io';

import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:http/io_client.dart';
import 'package:video_player/video_player.dart';

/// Shared disk cache for remote videos (CDN).
final CacheManager appVideoCacheManager = CacheManager(
  Config(
    'alras_video_cache_v2',
    stalePeriod: const Duration(days: 30),
    maxNrOfCacheObjects: 80,
    fileService: HttpFileService(
      httpClient: IOClient(_createHttpClient()),
    ),
  ),
);

HttpClient _createHttpClient() {
  final client = HttpClient();
  client.userAgent =
      'Mozilla/5.0 (Linux; Android 14) AppleWebKit/537.36 '
      '(KHTML, like Gecko) Chrome/122.0.0.0 Mobile Safari/537.36 '
      'AlRasMarket/1.0';
  client.connectionTimeout = const Duration(seconds: 45);
  client.idleTimeout = const Duration(seconds: 30);
  client.autoUncompress = true;
  return client;
}

/// Builds a [VideoPlayerController] from a remote CDN URL using the disk cache when possible.
Future<VideoPlayerController> createCachedNetworkVideoController(String url) async {
  final trimmed = url.trim();
  if (trimmed.isEmpty) {
    throw ArgumentError('Video URL is empty');
  }

  try {
    final file = await appVideoCacheManager.getSingleFile(trimmed);
    if (await file.exists()) {
      return VideoPlayerController.file(File(file.path));
    }
  } catch (_) {
    // Fall through to network if cache fetch fails.
  }

  return VideoPlayerController.networkUrl(
    Uri.parse(trimmed),
    httpHeaders: const {
      'User-Agent':
          'Mozilla/5.0 (Linux; Android 14) AppleWebKit/537.36 '
          '(KHTML, like Gecko) Chrome/122.0.0.0 Mobile Safari/537.36 '
          'AlRasMarket/1.0',
      'Accept': '*/*',
    },
  );
}
