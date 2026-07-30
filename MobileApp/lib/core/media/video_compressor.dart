import 'dart:async';
import 'dart:io';

import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_session.dart';
import 'package:ffmpeg_kit_flutter_new/ffprobe_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_player/video_player.dart';

typedef CompressionProgressCallback = void Function(double progress);

class VideoCompressor {
  VideoCompressor._();

  static const _audioBitrateK = 96;
  /// WhatsApp-like: one fast pass first; only fall back if still over the ceiling.
  static const _x264Preset = 'veryfast';
  static const _crfProfiles = <({int width, int crf})>[
    (width: 720, crf: 28),
    (width: 640, crf: 32),
  ];
  static const _maxBitrateAttempts = 2;
  /// Skip re-encode when already small enough (WhatsApp-style).
  static const _alreadySmallEnoughBytes = 12 * 1024 * 1024;

  /// Prefer libx264; on some FFmpegKit builds use mpeg4 (always available).
  static List<String> _videoEncodeArgs({
    required int width,
    int? crf,
    int? videoBitrateK,
  }) {
    final scale = "scale='min($width,iw)':-2";
    if (crf != null) {
      return [
        '-c:v', 'libx264',
        '-preset', _x264Preset,
        '-crf', '$crf',
        '-vf', scale,
      ];
    }
    final bitrate = videoBitrateK!;
    return [
      '-c:v', 'libx264',
      '-preset', _x264Preset,
      '-b:v', '${bitrate}k',
      '-maxrate', '${bitrate}k',
      '-bufsize', '${bitrate * 2}k',
      '-vf', scale,
    ];
  }

  static List<String> _mpeg4EncodeArgs({
    required int width,
    int qscale = 5,
    int? videoBitrateK,
  }) {
    final scale = "scale='min($width,iw)':-2";
    if (videoBitrateK != null) {
      return [
        '-c:v', 'mpeg4',
        '-b:v', '${videoBitrateK}k',
        '-vf', scale,
      ];
    }
    return [
      '-c:v', 'mpeg4',
      '-qscale:v', '$qscale',
      '-vf', scale,
    ];
  }

  /// Compresses [inputPath] down to at most [maxBytes].
  ///
  /// When [forceCompress] is true (ad uploads), always re-encodes even if the
  /// source is already under [maxBytes], and only keeps the result when it is
  /// meaningfully smaller than the original. This avoids skipping compression
  /// for e.g. a 23 MB clip when the upload ceiling is 100 MB.
  static Future<String?> compressToMaxSize(
    String inputPath, {
    int maxBytes = 30 * 1024 * 1024,
    bool forceCompress = false,
    CompressionProgressCallback? onProgress,
  }) async {
    final inputFile = File(inputPath);
    if (!await inputFile.exists()) return null;

    final originalSize = await inputFile.length();
    onProgress?.call(0);

    if (!forceCompress && originalSize <= maxBytes) {
      onProgress?.call(1);
      return inputPath;
    }

    // Already compact — no multi-pass re-encode (WhatsApp skips these too).
    if (forceCompress &&
        originalSize <= _alreadySmallEnoughBytes &&
        originalSize <= maxBytes) {
      onProgress?.call(1);
      return inputPath;
    }

    final durationSec = await _readDurationSeconds(inputPath);
    if (durationSec <= 0) {
      debugPrint('[VideoCompressor] Could not read video duration.');
      return originalSize <= maxBytes ? inputPath : null;
    }

    final outputPath = await _buildOutputPath();
    final maxAttempts = _crfProfiles.length + _maxBitrateAttempts;
    var attempt = 0;
    String? bestPath;
    var bestSize = originalSize;

    Future<String?> finishWith(String path) async {
      onProgress?.call(1);
      final outMb =
          ((await File(path).length()) / (1024 * 1024)).toStringAsFixed(1);
      final inMb = (originalSize / (1024 * 1024)).toStringAsFixed(1);
      debugPrint(
        '[VideoCompressor] $inMb MB → $outMb MB (force=$forceCompress)',
      );
      return path;
    }

    Future<bool> acceptTry(String tryPath) async {
      final size = await File(tryPath).length();
      if (size <= 0) {
        await _deleteIfExists(tryPath);
        return false;
      }
      if (size > maxBytes) {
        if (forceCompress) await _deleteIfExists(tryPath);
        return false;
      }
      // Non-force: first under-ceiling pass wins.
      if (!forceCompress) {
        return true;
      }
      // Force: accept first successful shrink (don't ladder for 15%+ cuts).
      if (size >= bestSize) {
        await _deleteIfExists(tryPath);
        return false;
      }
      if (bestPath != null && bestPath != tryPath) {
        await _deleteIfExists(bestPath!);
      }
      bestSize = size;
      bestPath = tryPath;
      return true;
    }

    for (final profile in _crfProfiles) {
      final range = _attemptProgressRange(
        attempt: attempt,
        maxAttempts: maxAttempts,
      );
      final tryPath =
          forceCompress ? await _buildOutputPath() : outputPath;
      if (!forceCompress) await _deleteIfExists(outputPath);
      final ok = await _runCrfCompress(
        inputPath: inputPath,
        outputPath: tryPath,
        width: profile.width,
        crf: profile.crf,
        durationSec: durationSec,
        onProgress: onProgress,
        progressStart: range.start,
        progressEnd: range.end,
      );
      attempt++;
      if (!ok) {
        if (forceCompress) await _deleteIfExists(tryPath);
        continue;
      }

      final done = await acceptTry(tryPath);
      if (!forceCompress && done) return finishWith(tryPath);
      if (forceCompress && done) return finishWith(bestPath!);
    }

    var videoBitrateK = _targetVideoBitrateK(
      durationSec: durationSec,
      // When forcing, aim under the smaller of ceiling and original size.
      maxBytes: forceCompress
          ? (originalSize < maxBytes ? originalSize : maxBytes)
          : maxBytes,
    );
    const minBitrateK = 300;
    while (videoBitrateK >= minBitrateK && attempt < maxAttempts) {
      final range = _attemptProgressRange(
        attempt: attempt,
        maxAttempts: maxAttempts,
      );
      final tryPath =
          forceCompress ? await _buildOutputPath() : outputPath;
      if (!forceCompress) await _deleteIfExists(outputPath);
      final ok = await _runBitrateCompress(
        inputPath: inputPath,
        outputPath: tryPath,
        width: 640,
        videoBitrateK: videoBitrateK,
        durationSec: durationSec,
        onProgress: onProgress,
        progressStart: range.start,
        progressEnd: range.end,
      );
      attempt++;
      if (!ok) {
        if (forceCompress) await _deleteIfExists(tryPath);
        break;
      }

      final done = await acceptTry(tryPath);
      if (!forceCompress && done) return finishWith(tryPath);
      if (forceCompress && done) return finishWith(bestPath!);

      videoBitrateK = (videoBitrateK * 0.75).floor();
    }

    if (forceCompress && bestPath != null && bestSize < originalSize) {
      return finishWith(bestPath!);
    }

    await _deleteIfExists(outputPath);
    if (bestPath != null) {
      await _deleteIfExists(bestPath!);
    }
    debugPrint(
      '[VideoCompressor] No smaller output; keeping original '
      '(${(originalSize / (1024 * 1024)).toStringAsFixed(1)} MB)',
    );
    return originalSize <= maxBytes ? inputPath : null;
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

  static Future<double> readDurationSeconds(String inputPath) async {
    return _readDurationSeconds(inputPath);
  }

  /// Rounded whole seconds for API upload (product videos allow up to 3 minutes).
  static Future<int> readDurationSecondsRounded(
    String inputPath, {
    int maxSeconds = 180,
  }) async {
    final duration = await _readDurationSeconds(inputPath);
    if (duration <= 0) return 0;
    final cappedMax = maxSeconds < 1 ? 1 : maxSeconds;
    return duration.round().clamp(1, cappedMax);
  }

  static Future<double> _readDurationSeconds(String inputPath) async {
    try {
      final session = await FFprobeKit.getMediaInformation(inputPath);
      final info = session.getMediaInformation();
      final duration = double.tryParse(info?.getDuration() ?? '');
      if (duration != null && duration > 0) return duration;
    } catch (e) {
      debugPrint('[VideoCompressor] FFprobe failed: $e');
    }

    final controller = VideoPlayerController.file(File(inputPath));
    try {
      await controller.initialize();
      final seconds = controller.value.duration.inMilliseconds / 1000.0;
      if (seconds > 0) return seconds;
    } catch (e) {
      debugPrint('[VideoCompressor] VideoPlayer duration failed: $e');
    } finally {
      await controller.dispose();
    }

    return 0;
  }

  static Future<bool> _runCrfCompress({
    required String inputPath,
    required String outputPath,
    required int width,
    required int crf,
    required double durationSec,
    CompressionProgressCallback? onProgress,
    required double progressStart,
    required double progressEnd,
  }) async {
    final libx264Ok = await _runFfmpeg(
      arguments: [
        '-y', '-i', inputPath,
        ..._videoEncodeArgs(width: width, crf: crf),
        '-c:a', 'aac', '-b:a', '${_audioBitrateK}k',
        '-movflags', '+faststart', outputPath,
      ],
      durationSec: durationSec,
      onProgress: onProgress,
      progressStart: progressStart,
      progressEnd: progressEnd,
    );
    if (libx264Ok) return true;

    return _runFfmpeg(
      arguments: [
        '-y', '-i', inputPath,
        ..._mpeg4EncodeArgs(width: width, qscale: crf.clamp(2, 31)),
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
    CompressionProgressCallback? onProgress,
    required double progressStart,
    required double progressEnd,
  }) async {
    final libx264Ok = await _runFfmpeg(
      arguments: [
        '-y', '-i', inputPath,
        ..._videoEncodeArgs(width: width, videoBitrateK: videoBitrateK),
        '-c:a', 'aac', '-b:a', '${_audioBitrateK}k',
        '-movflags', '+faststart', outputPath,
      ],
      durationSec: durationSec,
      onProgress: onProgress,
      progressStart: progressStart,
      progressEnd: progressEnd,
    );
    if (libx264Ok) return true;

    return _runFfmpeg(
      arguments: [
        '-y', '-i', inputPath,
        ..._mpeg4EncodeArgs(width: width, videoBitrateK: videoBitrateK),
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
    CompressionProgressCallback? onProgress,
    required double progressStart,
    required double progressEnd,
  }) async {
    final durationMs = durationSec * 1000;
    final completer = Completer<bool>();
    // FFmpeg statistics can jump backwards between packets — keep UI monotonic.
    var lastEmitted = progressStart;

    void emitProgress(double value) {
      final clamped = value.clamp(progressStart, progressEnd.clamp(0.0, 0.99));
      if (clamped + 0.0001 < lastEmitted) return;
      lastEmitted = clamped;
      onProgress?.call(clamped);
    }

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
        emitProgress(overall);
      },
    );

    return completer.future;
  }

  static Future<String> _buildOutputPath() async {
    final docsDir = await getApplicationDocumentsDirectory();
    final assetsDir = Directory('${docsDir.path}/compressed_media');
    if (!await assetsDir.exists()) {
      await assetsDir.create(recursive: true);
    }
    return '${assetsDir.path}/video_${DateTime.now().microsecondsSinceEpoch}.mp4';
  }

  static Future<void> _deleteIfExists(String path) async {
    final file = File(path);
    if (await file.exists()) await file.delete();
  }
}
