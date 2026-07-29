import 'dart:async';
import 'dart:io';

import 'package:alrasmarket/features/chat/data/models/chat_message_type.dart';
import 'package:alrasmarket/features/chat/data/utils/chat_media_helper.dart';
import 'package:alrasmarket/features/company/presentation/helpers/create_ad_form_mapper.dart';

import 'image_compressor.dart';
import 'video_compressor.dart';

export 'video_compressor.dart' show CompressionProgressCallback;

enum MediaCompressionPhase { compressing, uploading }

class MediaCompressionService {
  MediaCompressionService._();

  static const int chatVideoMaxBytes = 30 * 1024 * 1024;
  static const int adVideoMaxBytes = CreateAdFormMapper.maxProductVideoBytes;

  /// Parallel image compressions during publish/edit.
  static const int adImageConcurrency = 4;

  /// Parallel video compressions (FFmpeg is CPU-heavy).
  static const int adVideoConcurrency = 2;

  static bool isVideoPath(String path) {
    return ChatMediaHelper.uploadTypeForPath(path) == ChatMessageType.video ||
        CreateAdFormMapper.isVideoPath(path);
  }

  static bool isImagePath(String path) => ImageCompressor.isImagePath(path);

  static Future<String?> prepareChatMedia(
    String inputPath, {
    CompressionProgressCallback? onProgress,
  }) async {
    if (isVideoPath(inputPath)) {
      return VideoCompressor.compressToMaxSize(
        inputPath,
        maxBytes: chatVideoMaxBytes,
        onProgress: onProgress,
      );
    }
    if (isImagePath(inputPath)) {
      return ImageCompressor.compressIfNeeded(
        inputPath,
        onProgress: onProgress,
      );
    }
    return inputPath;
  }

  static Future<String?> prepareAdMedia(
    String inputPath, {
    CompressionProgressCallback? onProgress,
  }) async {
    if (isVideoPath(inputPath)) {
      // Always re-encode ad videos. maxProductVideoBytes (100MB) is only the
      // upload ceiling — without forceCompress, clips under that limit (e.g.
      // 23MB) were uploaded raw with no size reduction.
      return VideoCompressor.compressToMaxSize(
        inputPath,
        maxBytes: adVideoMaxBytes,
        forceCompress: true,
        onProgress: onProgress,
      );
    }
    if (isImagePath(inputPath)) {
      return ImageCompressor.compressIfNeeded(
        inputPath,
        onProgress: onProgress,
      );
    }
    return inputPath;
  }

  /// Compresses many files in parallel (images and videos separately pooled).
  /// Returns results in the same order as [paths].
  ///
  /// [onFraction] reports overall progress in `0..1` (including in-file video
  /// compress progress when available).
  static Future<List<String>> prepareAdMediaMany(
    List<String> paths, {
    int imageConcurrency = adImageConcurrency,
    int videoConcurrency = adVideoConcurrency,
    void Function(int completed, int total)? onProgress,
    void Function(double fraction)? onFraction,
  }) async {
    if (paths.isEmpty) return const [];

    final results = List<String>.from(paths);
    final imageIndexes = <int>[];
    final videoIndexes = <int>[];

    for (var i = 0; i < paths.length; i++) {
      final path = paths[i];
      if (isVideoPath(path)) {
        videoIndexes.add(i);
      } else if (isImagePath(path)) {
        imageIndexes.add(i);
      }
    }

    final total = imageIndexes.length + videoIndexes.length;
    if (total == 0) return results;

    var completed = 0;
    final inFlight = <int, double>{};
    var lastFraction = 0.0;

    void emitFraction({bool force = false}) {
      final activeSum = inFlight.values.fold<double>(0, (a, b) => a + b);
      final fraction = ((completed + activeSum) / total).clamp(0.0, 1.0);
      // Never let the bar bounce backwards (parallel workers / FFmpeg noise).
      if (!force && fraction + 0.0001 < lastFraction) {
        onProgress?.call(completed, total);
        return;
      }
      lastFraction = fraction;
      onFraction?.call(fraction);
      onProgress?.call(completed, total);
    }

    emitFraction(force: true);

    Future<void> runPool(List<int> indexes, int concurrency) async {
      if (indexes.isEmpty) return;
      final pending = List<int>.from(indexes);
      final limit = concurrency < 1 ? 1 : concurrency;

      Future<void> worker() async {
        while (true) {
          if (pending.isEmpty) return;
          final index = pending.removeLast();
          final path = paths[index];
          inFlight[index] = 0.02;
          emitFraction();

          var fileLast = 0.02;
          final prepared = await prepareAdMedia(
            path,
            onProgress: (fileProgress) {
              final next = fileProgress.clamp(0.0, 0.99);
              if (next + 0.0001 < fileLast) return;
              fileLast = next;
              inFlight[index] = next;
              emitFraction();
            },
          );
          if (prepared == null && isVideoPath(path)) {
            // Signal compress failure for the caller.
            results[index] = '';
          } else {
            results[index] = prepared ?? path;
          }
          inFlight.remove(index);
          completed++;
          emitFraction();
        }
      }

      final workers = List.generate(
        limit < indexes.length ? limit : indexes.length,
        (_) => worker(),
      );
      await Future.wait(workers);
    }

    await runPool(imageIndexes, imageConcurrency);
    await runPool(videoIndexes, videoConcurrency);
    onFraction?.call(1);
    onProgress?.call(total, total);
    return results;
  }

  static Future<int> fileSizeBytes(String path) async {
    final file = File(path);
    if (!await file.exists()) return 0;
    return file.length();
  }
}
