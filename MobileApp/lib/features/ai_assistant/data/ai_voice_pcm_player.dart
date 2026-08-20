import 'dart:typed_data';

import 'package:alrasmarket/features/ai_assistant/data/ai_voice_speaker_route.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_pcm_sound/flutter_pcm_sound.dart' as pcm;

/// Streams PCM16 24 kHz mono as soon as the first playable chunk arrives.
class AiVoicePcmPlayer {
  static const sampleRate = 24000;
  static const bytesPerSecond = sampleRate * 2;

  final AudioPlayer _fallback = AudioPlayer();
  bool _pcmReady = false;
  final BytesBuilder _fallbackBuffer = BytesBuilder(copy: false);
  int _queuedResponseBytes = 0;
  int _generation = 0;
  Future<void> _chain = Future<void>.value();

  int get queuedResponseBytes => _queuedResponseBytes;

  Future<void> start() => _enqueue(_setupEngine);

  Future<void> feed(Uint8List pcm16, {required String kind}) {
    if (pcm16.isEmpty) return Future.value();
    return _enqueue(() => _feedNow(pcm16, kind: kind));
  }

  void markResponsePlaybackComplete() {
    _queuedResponseBytes = 0;
  }

  int estimateRemainingPlaybackMs() {
    if (_queuedResponseBytes <= 0) return 0;
    return ((_queuedResponseBytes / bytesPerSecond) * 1000).ceil() + 250;
  }

  /// Stops queued audio without leaving the engine in a dead state.
  Future<void> stopPlayback() => _enqueue(() async {
        _generation++;
        _queuedResponseBytes = 0;
        _fallbackBuffer.clear();
        try {
          await _fallback.stop();
        } catch (_) {}
        await _setupEngine();
      });

  Future<void> dispose() async {
    await stopPlayback();
    try {
      if (_pcmReady) {
        await pcm.FlutterPcmSound.release();
      }
    } catch (_) {}
    await _fallback.dispose();
  }

  Future<void> _enqueue(Future<void> Function() op) {
    final next = _chain.then((_) => op());
    _chain = next.catchError((Object e, StackTrace st) {
      debugPrint('PCM player op failed: $e\n$st');
    });
    return next;
  }

  Future<void> _setupEngine() async {
    try {
      await pcm.FlutterPcmSound.setLogLevel(pcm.LogLevel.none);
      await pcm.FlutterPcmSound.setup(
        sampleRate: sampleRate,
        channelCount: 1,
        iosAudioCategory: pcm.IosAudioCategory.playAndRecord,
        iosAllowBackgroundAudio: true,
      );
      await pcm.FlutterPcmSound.setFeedThreshold(1200);
      _pcmReady = true;
    } catch (e) {
      debugPrint('PCM sound setup failed, using WAV fallback: $e');
      _pcmReady = false;
      await _fallback.setPlayerMode(PlayerMode.lowLatency);
      await _fallback.setReleaseMode(ReleaseMode.stop);
    }
    await AiVoiceSpeakerRoute.apply();
    try {
      await _fallback.setAudioContext(AiVoiceSpeakerRoute.context);
      await _fallback.setVolume(1.0);
    } catch (_) {}
  }

  Future<void> _feedNow(Uint8List pcm16, {required String kind}) async {
    final generation = _generation;
    if (kind == 'response') {
      _queuedResponseBytes += pcm16.length;
    }

    if (_pcmReady) {
      try {
        if (generation != _generation) return;
        final copy = Uint8List.fromList(pcm16);
        await pcm.FlutterPcmSound.feed(
          pcm.PcmArrayInt16(bytes: ByteData.sublistView(copy)),
        );
        if (generation != _generation) return;
        pcm.FlutterPcmSound.start();
        return;
      } catch (e) {
        debugPrint('PCM feed failed, rebuilding engine: $e');
        await _setupEngine();
        if (generation != _generation || !_pcmReady) {
          // fall through to WAV
        } else {
          try {
            final copy = Uint8List.fromList(pcm16);
            await pcm.FlutterPcmSound.feed(
              pcm.PcmArrayInt16(bytes: ByteData.sublistView(copy)),
            );
            pcm.FlutterPcmSound.start();
            return;
          } catch (e2) {
            debugPrint('PCM retry feed failed: $e2');
          }
        }
      }
    }

    if (generation != _generation) return;
    _fallbackBuffer.add(pcm16);
    if (_fallbackBuffer.length >= 3840) {
      await _playFallbackWav();
    }
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
