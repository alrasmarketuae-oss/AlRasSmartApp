import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_pcm_sound/flutter_pcm_sound.dart' as pcm;

/// Streams PCM16 24 kHz mono as soon as the first playable chunk arrives.
class AiVoicePcmPlayer {
  static const sampleRate = 24000;

  final AudioPlayer _fallback = AudioPlayer();
  bool _pcmReady = false;
  bool _playingProgress = false;
  final BytesBuilder _fallbackBuffer = BytesBuilder(copy: false);

  Future<void> start() async {
    try {
      await pcm.FlutterPcmSound.setLogLevel(pcm.LogLevel.none);
      await pcm.FlutterPcmSound.setup(
        sampleRate: sampleRate,
        channelCount: 1,
        iosAudioCategory: pcm.IosAudioCategory.playAndRecord,
      );
      await pcm.FlutterPcmSound.setFeedThreshold(1200);
      _pcmReady = true;
    } catch (e) {
      debugPrint('PCM sound setup failed, using WAV fallback: $e');
      _pcmReady = false;
      await _fallback.setPlayerMode(PlayerMode.lowLatency);
      await _fallback.setReleaseMode(ReleaseMode.stop);
    }
  }

  Future<void> feed(Uint8List pcm16, {required String kind}) async {
    if (pcm16.isEmpty) return;
    if (kind == 'response' && _playingProgress) {
      await stopPlayback();
    }
    _playingProgress = kind == 'progress';

    if (_pcmReady) {
      try {
        final copy = Uint8List.fromList(pcm16);
        await pcm.FlutterPcmSound.feed(
          pcm.PcmArrayInt16(bytes: ByteData.sublistView(copy)),
        );
        pcm.FlutterPcmSound.start();
        return;
      } catch (e) {
        debugPrint('PCM feed failed: $e');
      }
    }

    _fallbackBuffer.add(pcm16);
    if (_fallbackBuffer.length >= 3840) {
      await _playFallbackWav();
    }
  }

  Future<void> stopPlayback() async {
    _playingProgress = false;
    _fallbackBuffer.clear();
    if (_pcmReady) {
      try {
        await pcm.FlutterPcmSound.release();
        await pcm.FlutterPcmSound.setup(
          sampleRate: sampleRate,
          channelCount: 1,
          iosAudioCategory: pcm.IosAudioCategory.playAndRecord,
        );
      } catch (_) {}
    }
    try {
      await _fallback.stop();
    } catch (_) {}
  }

  Future<void> dispose() async {
    await stopPlayback();
    try {
      if (_pcmReady) {
        await pcm.FlutterPcmSound.release();
      }
    } catch (_) {}
    await _fallback.dispose();
  }

  Future<void> _playFallbackWav() async {
    if (_fallbackBuffer.isEmpty) return;
    final pcmBytes = _fallbackBuffer.takeBytes();
    final wav = _wrapWav(pcmBytes, sampleRate);
    try {
      await _fallback.play(BytesSource(wav));
    } catch (e) {
      debugPrint('WAV fallback play failed: $e');
    }
  }

  static Uint8List _wrapWav(Uint8List pcmBytes, int rate) {
    final dataSize = pcmBytes.length;
    final out = BytesBuilder(copy: false)
      ..add('RIFF'.codeUnits)
      ..add(_u32(36 + dataSize))
      ..add('WAVE'.codeUnits)
      ..add('fmt '.codeUnits)
      ..add(_u32(16))
      ..add(_u16(1))
      ..add(_u16(1))
      ..add(_u32(rate))
      ..add(_u32(rate * 2))
      ..add(_u16(2))
      ..add(_u16(16))
      ..add('data'.codeUnits)
      ..add(_u32(dataSize))
      ..add(pcmBytes);
    return out.takeBytes();
  }

  static List<int> _u16(int v) => [v & 0xff, (v >> 8) & 0xff];

  static List<int> _u32(int v) => [
        v & 0xff,
        (v >> 8) & 0xff,
        (v >> 16) & 0xff,
        (v >> 24) & 0xff,
      ];
}
