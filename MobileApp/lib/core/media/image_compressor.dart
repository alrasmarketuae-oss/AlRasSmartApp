import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'video_compressor.dart';

class ImageCompressor {
  ImageCompressor._();

  static const _imageExtensions = {'jpg', 'jpeg', 'png', 'webp', 'heic', 'heif'};
  static final _rand = Random();

  /// Max upload size for image-search requests.
  static const int searchImageMaxBytes = 100 * 1024;

  static bool isImagePath(String path) {
    final ext = p.extension(path).replaceFirst('.', '').toLowerCase();
    return _imageExtensions.contains(ext);
  }

  static String _uniqueStamp() =>
      '${DateTime.now().microsecondsSinceEpoch}_${_rand.nextInt(1 << 30)}';

  static Future<String?> compressIfNeeded(
    String inputPath, {
    int quality = 82,
    int maxWidth = 1920,
    int maxHeight = 1920,
    CompressionProgressCallback? onProgress,
  }) async {
    final source = File(inputPath);
    if (!await source.exists()) return null;
    if (!isImagePath(inputPath)) return inputPath;

    onProgress?.call(0.05);

    final docsDir = await getApplicationDocumentsDirectory();
    final outDir = Directory('${docsDir.path}/compressed_media');
    if (!await outDir.exists()) {
      await outDir.create(recursive: true);
    }

    final ext = p.extension(inputPath).toLowerCase();
    final targetExt = ext == '.png' ? '.jpg' : ext;
    final targetPath = '${outDir.path}/image_${_uniqueStamp()}$targetExt';

    onProgress?.call(0.2);

    try {
      final result = await FlutterImageCompress.compressAndGetFile(
        inputPath,
        targetPath,
        quality: quality,
        minWidth: maxWidth,
        minHeight: maxHeight,
        format: targetExt == '.png'
            ? CompressFormat.png
            : CompressFormat.jpeg,
      );

      onProgress?.call(1);

      if (result == null) return inputPath;
      final compressed = File(result.path);
      if (!await compressed.exists()) return inputPath;

      final originalSize = await source.length();
      final compressedSize = await compressed.length();
      if (compressedSize >= originalSize) {
        await compressed.delete();
        return inputPath;
      }

      return result.path;
    } catch (e) {
      debugPrint('[ImageCompressor] Failed: $e');
      onProgress?.call(1);
      return inputPath;
    }
  }

  /// Compresses until file size is under [maxBytes] (default 100 KB for image search).
  static Future<String?> compressToMaxBytes(
    String inputPath, {
    int maxBytes = searchImageMaxBytes,
    CompressionProgressCallback? onProgress,
  }) async {
    final source = File(inputPath);
    if (!await source.exists()) return null;
    if (!isImagePath(inputPath)) return inputPath;

    final originalSize = await source.length();
    if (originalSize <= maxBytes) {
      onProgress?.call(1);
      return inputPath;
    }

    onProgress?.call(0.05);

    final docsDir = await getApplicationDocumentsDirectory();
    final outDir = Directory('${docsDir.path}/compressed_media');
    if (!await outDir.exists()) {
      await outDir.create(recursive: true);
    }

    final stamp = _uniqueStamp();
    String? bestPath;
    var bestSize = originalSize;

    // Progressively lower quality and dimensions until under maxBytes.
    final attempts = <({int quality, int maxSide})>[
      (quality: 70, maxSide: 1280),
      (quality: 55, maxSide: 1024),
      (quality: 40, maxSide: 800),
      (quality: 30, maxSide: 640),
      (quality: 20, maxSide: 480),
      (quality: 15, maxSide: 360),
      (quality: 10, maxSide: 320),
    ];

    for (var i = 0; i < attempts.length; i++) {
      final attempt = attempts[i];
      onProgress?.call(0.1 + (0.85 * (i + 1) / attempts.length));

      final targetPath = '${outDir.path}/search_img_${stamp}_$i.jpg';

      try {
        final result = await FlutterImageCompress.compressAndGetFile(
          inputPath,
          targetPath,
          quality: attempt.quality,
          minWidth: attempt.maxSide,
          minHeight: attempt.maxSide,
          format: CompressFormat.jpeg,
        );

        if (result == null) continue;
        final compressed = File(result.path);
        if (!await compressed.exists()) continue;

        final size = await compressed.length();
        debugPrint(
          '[ImageCompressor] search attempt q=${attempt.quality} '
          'side=${attempt.maxSide} → ${(size / 1024).toStringAsFixed(1)} KB',
        );

        if (size < bestSize) {
          if (bestPath != null && bestPath != result.path) {
            try {
              await File(bestPath).delete();
            } catch (_) {}
          }
          bestPath = result.path;
          bestSize = size;
        } else {
          try {
            await compressed.delete();
          } catch (_) {}
        }

        if (size <= maxBytes) {
          onProgress?.call(1);
          return result.path;
        }
      } catch (e) {
        debugPrint('[ImageCompressor] search attempt failed: $e');
      }
    }

    onProgress?.call(1);
    // Return the smallest we achieved even if still slightly over max.
    return bestPath ?? inputPath;
  }
}
