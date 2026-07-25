// Video compression — DISABLED
//
// To re-enable:
// 1. Uncomment in pubspec.yaml: ffmpeg_kit_flutter_new: ^4.2.1
// 2. Run: flutter pub get
// 3. Uncomment the implementation block below
// 4. Uncomment compression logic in create_ad_cubit._prepareVideoPath
// 5. Uncomment compression UI in create_ad_product_images_widget.dart
// 6. Uncomment isCompressingVideo / videoCompressionProgress in create_ad_states.dart

/*
import 'dart:async';
import 'dart:io';

import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_session.dart';
import 'package:ffmpeg_kit_flutter_new/ffprobe_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import 'create_ad_form_mapper.dart';

typedef VideoCompressionProgressCallback = void Function(double progress);

class ProductVideoCompressor {
  ProductVideoCompressor._();

  static const _audioBitrateK = 96;
  static const _crfProfiles = <({int width, int crf})>[
    (width: 1280, crf: 28),
    (width: 960, crf: 30),
    (width: 720, crf: 32),
    (width: 640, crf: 34),
  ];
  static const _maxBitrateAttempts = 6;

  static Future<String?> compressToMaxSize(
    String inputPath, {
    int maxBytes = CreateAdFormMapper.maxProductVideoBytes,
    VideoCompressionProgressCallback? onProgress,
  }) async {
    final inputFile = File(inputPath);
    if (!await inputFile.exists()) return null;

    final originalSize = await inputFile.length();
    onProgress?.call(0);

    final durationSec = await _readDurationSeconds(inputPath);
    if (durationSec <= 0) {
      debugPrint('[ProductVideoCompressor] Could not read video duration.');
      if (originalSize <= maxBytes) {
        onProgress?.call(1);
        return inputPath;
      }
      return null;
    }

    final outputPath = await _buildOutputPath();
    final maxAttempts = _crfProfiles.length + _maxBitrateAttempts;
    var attempt = 0;

    for (final profile in _crfProfiles) {
      final range = _attemptProgressRange(
        attempt: attempt,
        maxAttempts: maxAttempts,
      );
      await _deleteIfExists(outputPath);
      final ok = await _runCrfCompress(
        inputPath: inputPath,
        outputPath: outputPath,
        width: profile.width,
        crf: profile.crf,
        durationSec: durationSec,
        onProgress: onProgress,
        progressStart: range.start,
        progressEnd: range.end,
      );
      attempt++;
      if (!ok) continue;

      final size = await File(outputPath).length();
      if (size > 0 && size <= maxBytes) {
        await _deleteIfDifferent(inputPath, outputPath);
        onProgress?.call(1);
        return outputPath;
      }
    }

    var videoBitrateK = _targetVideoBitrateK(
      durationSec: durationSec,
      maxBytes: maxBytes,
    );
    const minBitrateK = 300;
    while (videoBitrateK >= minBitrateK && attempt < maxAttempts) {
      final range = _attemptProgressRange(
        attempt: attempt,
        maxAttempts: maxAttempts,
      );
      await _deleteIfExists(outputPath);
      final ok = await _runBitrateCompress(
        inputPath: inputPath,
        outputPath: outputPath,
        width: 640,
        videoBitrateK: videoBitrateK,
        durationSec: durationSec,
        onProgress: onProgress,
        progressStart: range.start,
        progressEnd: range.end,
      );
      attempt++;
      if (!ok) break;

      final size = await File(outputPath).length();
      if (size > 0 && size <= maxBytes) {
        await _deleteIfDifferent(inputPath, outputPath);
        onProgress?.call(1);
        return outputPath;
      }

      videoBitrateK = (videoBitrateK * 0.75).floor();
    }

    await _deleteIfExists(outputPath);
    if (originalSize <= maxBytes) {
      onProgress?.call(1);
      return inputPath;
    }
    return null;
  }

  static ({double start, double end}) _attemptProgressRange({
    required int attempt,
    required int maxAttempts,
  }) {
    final slice = 1 / maxAttempts;
    return (start: attempt * slice, end: (attempt + 1) * slice);
  }

  static int _targetVideoBitrateK({
    required double durationSec,
    required int maxBytes,
  }) {
    final audioBits = _audioBitrateK * 1000 * durationSec;
    final videoBits = (maxBytes * 8 * 0.92) - audioBits;
    final bitrateK = (videoBits / durationSec / 1000).floor();
    return bitrateK.clamp(300, 2500);
  }

  static Future<double> _readDurationSeconds(String inputPath) async {
    try {
      final session = await FFprobeKit.getMediaInformation(inputPath);
      final info = session.getMediaInformation();
      final duration = double.tryParse(info?.getDuration() ?? '');
      if (duration != null && duration > 0) return duration;
    } catch (e) {
      debugPrint('[ProductVideoCompressor] FFprobe failed: $e');
    }
    return 0;
  }

  static Future<bool> _runCrfCompress({
    required String inputPath,
    required String outputPath,
    required int width,
    required int crf,
    required double durationSec,
    VideoCompressionProgressCallback? onProgress,
    required double progressStart,
    required double progressEnd,
  }) {
    return _runFfmpeg(
      arguments: [
        '-y', '-i', inputPath,
        '-c:v', 'libx264', '-preset', 'medium', '-crf', '$crf',
        '-vf', "scale='min($width,iw)':-2",
        '-c:a', 'aac', '-b:a', '${_audioBitrateK}k',
        '-movflags', '+faststart', outputPath,
      ],
      durationSec: durationSec,
      onProgress: onProgress,
      progressStart: progressStart,
      progressEnd: progressEnd,
    );
  }

  static Future<bool> _runBitrateCompress({
    required String inputPath,
    required String outputPath,
    required int width,
    required int videoBitrateK,
    required double durationSec,
    VideoCompressionProgressCallback? onProgress,
    required double progressStart,
    required double progressEnd,
  }) {
    return _runFfmpeg(
      arguments: [
        '-y', '-i', inputPath,
        '-c:v', 'libx264', '-preset', 'medium',
        '-b:v', '${videoBitrateK}k',
        '-maxrate', '${videoBitrateK}k',
        '-bufsize', '${videoBitrateK * 2}k',
        '-vf', "scale='min($width,iw)':-2",
        '-c:a', 'aac', '-b:a', '${_audioBitrateK}k',
        '-movflags', '+faststart', outputPath,
      ],
      durationSec: durationSec,
      onProgress: onProgress,
      progressStart: progressStart,
      progressEnd: progressEnd,
    );
  }

  static Future<bool> _runFfmpeg({
    required List<String> arguments,
    required double durationSec,
    VideoCompressionProgressCallback? onProgress,
    required double progressStart,
    required double progressEnd,
  }) async {
    final durationMs = durationSec * 1000;
    final completer = Completer<bool>();

    await FFmpegKit.executeWithArgumentsAsync(
      arguments,
      (FFmpegSession session) async {
        if (!completer.isCompleted) {
          final returnCode = await session.getReturnCode();
          onProgress?.call(progressEnd.clamp(0, 1));
          completer.complete(ReturnCode.isSuccess(returnCode));
        }
      },
      null,
      (statistics) {
        if (durationMs <= 0) return;
        final sessionProgress =
            (statistics.getTime() / durationMs).clamp(0.0, 1.0);
        final overall =
            progressStart + sessionProgress * (progressEnd - progressStart);
        onProgress?.call(overall.clamp(0.0, 0.99));
      },
    );

    return completer.future;
  }

  static Future<String> _buildOutputPath() async {
    final docsDir = await getApplicationDocumentsDirectory();
    final assetsDir = Directory('${docsDir.path}/create_ad_assets');
    if (!await assetsDir.exists()) {
      await assetsDir.create(recursive: true);
    }
    return '${assetsDir.path}/compressed_${DateTime.now().millisecondsSinceEpoch}.mp4';
  }

  static Future<void> _deleteIfExists(String path) async {
    final file = File(path);
    if (await file.exists()) await file.delete();
  }

  static Future<void> _deleteIfDifferent(String original, String compressed) async {
    if (original == compressed) return;
    try {
      final originalFile = File(original);
      if (await originalFile.exists()) await originalFile.delete();
    } catch (e) {
      debugPrint('[ProductVideoCompressor] Failed to delete original: $e');
    }
  }
}
*/
