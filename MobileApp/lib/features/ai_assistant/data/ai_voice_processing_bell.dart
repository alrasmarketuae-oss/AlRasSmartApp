import 'dart:math' as math;
import 'dart:typed_data';

import 'package:alrasmarket/features/ai_assistant/data/ai_voice_speaker_route.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

/// Soft repeating bell while the voice agent is processing a request.
class AiVoiceProcessingBell {
  AiVoiceProcessingBell();

  final AudioPlayer _player = AudioPlayer();
  bool _ready = false;
  bool _playing = false;
  Uint8List? _wav;

  Future<void> start() async {
    if (_playing) return;
    _playing = true;
    try {
      await _ensureReady();
      await _player.stop();
      await _player.setReleaseMode(ReleaseMode.loop);
      await _player.setVolume(0.42);
      await _player.play(BytesSource(_wav!, mimeType: 'audio/wav'));
    } catch (e) {
      _playing = false;
      debugPrint('Processing bell play failed: $e');
    }
  }

  Future<void> stop() async {
    if (!_playing) return;
    _playing = false;
    try {
      await _player.stop();
    } catch (_) {}
  }

  Future<void> dispose() async {
    await stop();
    await _player.dispose();
  }

  Future<void> _ensureReady() async {
    if (_ready) return;
    _wav = _buildBellWav();
    await _player.setAudioContext(AiVoiceSpeakerRoute.context);
    await _player.setPlayerMode(PlayerMode.mediaPlayer);
    _ready = true;
  }

  /// ~1.35s clip: two decaying tones with a pause so looping feels like a ring.
  static Uint8List _buildBellWav() {
    const rate = 22050;
    const totalMs = 1350;
    final n = (rate * totalMs) ~/ 1000;
    final pcm = Int16List(n);
    _tone(pcm, rate, startMs: 0, durMs: 280, freq: 880, volume: 0.38);
    _tone(pcm, rate, startMs: 90, durMs: 320, freq: 1320, volume: 0.22);
    _tone(pcm, rate, startMs: 420, durMs: 260, freq: 988, volume: 0.32);
    _tone(pcm, rate, startMs: 500, durMs: 300, freq: 1480, volume: 0.18);

    final bytes = pcm.buffer.asUint8List();
    final dataSize = bytes.length;
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
      ..add(bytes);
    return out.takeBytes();
  }

  static void _tone(
    Int16List pcm,
    int rate, {
    required int startMs,
    required int durMs,
    required double freq,
    required double volume,
  }) {
    final start = (rate * startMs) ~/ 1000;
    final count = (rate * durMs) ~/ 1000;
    for (var i = 0; i < count; i++) {
      final idx = start + i;
      if (idx >= pcm.length) return;
      final t = i / rate;
      final env = math.exp(-t * 7.5);
      final sample = (math.sin(2 * math.pi * freq * t) * volume * env * 32767)
          .round()
          .clamp(-32767, 32767);
      pcm[idx] = (pcm[idx] + sample).clamp(-32767, 32767);
    }
  }

  static List<int> _u16(int v) => [v & 0xff, (v >> 8) & 0xff];

  static List<int> _u32(int v) => [
        v & 0xff,
        (v >> 8) & 0xff,
        (v >> 16) & 0xff,
        (v >> 24) & 0xff,
      ];
}
