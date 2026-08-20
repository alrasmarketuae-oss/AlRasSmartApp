import 'dart:async';
import 'dart:typed_data';

import 'package:alrasmarket/features/ai_assistant/data/ai_voice_agent_service.dart';
import 'package:alrasmarket/features/ai_assistant/data/ai_voice_pcm_player.dart';
import 'package:alrasmarket/features/ai_assistant/data/ai_voice_speaker_route.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:record/record.dart';

enum AiVoiceAgentPhase {
  connecting,
  listening,
  processing,
  speaking,
  muted,
  error,
}

class AiVoiceAgentController with WidgetsBindingObserver {
  AiVoiceAgentController({
    required this.language,
    required this.voiceGender,
    required this.onPhase,
    required this.onUserTranscript,
    required this.onAssistantTranscript,
    required this.onError,
  });

  final String language;
  final String voiceGender;
  final void Function(AiVoiceAgentPhase phase) onPhase;
  final void Function(String text) onUserTranscript;
  final void Function(String text) onAssistantTranscript;
  final void Function(String message) onError;

  final AiVoiceAgentService _hub = AiVoiceAgentService();
  final AiVoicePcmPlayer _player = AiVoicePcmPlayer();
  final AudioRecorder _recorder = AudioRecorder();

  StreamSubscription<Uint8List>? _micSub;
  StreamSubscription<Amplitude>? _ampSub;
  bool _started = false;
  bool _muted = false;
  bool _backgrounded = false;
  bool _agentSpeaking = false;
  bool _closed = false;
  bool _recovering = false;
  bool _sendingAudio = false;
  int _recoveries = 0;
  DateTime _lastRecoveryAt = DateTime.fromMillisecondsSinceEpoch(0);
  DateTime? _playbackStartedAt;
  DateTime? _lastResponseAudioAt;
  Timer? _playbackDrainTimer;
  int _loudFramesWhileSpeaking = 0;

  /// Close-range speech only (~-26 dBFS). Far/quiet sounds should not barge-in.
  static const _bargeInThresholdDb = -26.0;
  static const _bargeInPeakThresholdDb = -22.0;
  static const _bargeInGraceMs = 900;
  static const _bargeInRequiredFrames = 7;
  final BytesBuilder _sendBuffer = BytesBuilder(copy: false);
  AiVoiceAgentPhase _phase = AiVoiceAgentPhase.connecting;

  bool get isMuted => _muted;
  AiVoiceAgentPhase get phase => _phase;

  Future<void> start() async {
    if (_started || _closed) return;
    _started = true;
    WidgetsBinding.instance.addObserver(this);
    _setPhase(AiVoiceAgentPhase.connecting);

    try {
      final permitted = await _recorder.hasPermission();
      if (!permitted) {
        _setPhase(AiVoiceAgentPhase.error);
        onError('Microphone permission is required for voice chat.');
        return;
      }

      await _player.start();
      await AiVoiceSpeakerRoute.apply();
      await _hub.connect(
        language: language,
        voiceGender: voiceGender,
        onStatus: _onStatus,
        onAudio: (pcmBytes, {required kind}) {
          if (_closed) return;
          if (kind == 'response') {
            _agentSpeaking = true;
            _playbackStartedAt ??= DateTime.now();
            _lastResponseAudioAt = DateTime.now();
            _playbackDrainTimer?.cancel();
            _sendBuffer.clear();
            _setPhase(AiVoiceAgentPhase.speaking);
          }
          unawaited(_player.feed(pcmBytes, kind: kind));
        },
        onTranscript: (role, text, {required isFinal}) {
          if (role == 'user' && isFinal) {
            onUserTranscript(text);
          } else if (role == 'assistant') {
            onAssistantTranscript(text);
          }
        },
        onInterrupted: () {
          debugPrint('Voice user interrupted agent');
          unawaited(_handleInterrupt(fromServer: true));
        },
        onError: (message, {required recoverable}) {
          debugPrint('Voice agent error: $message recoverable=$recoverable');
          if (recoverable) {
            unawaited(_recoverSession());
            return;
          }
          onError(message);
        },
        onMetrics: (metrics) {
          debugPrint('Voice metrics: $metrics');
        },
        onReconnecting: () {
          _setPhase(AiVoiceAgentPhase.connecting);
        },
        onReconnected: () {
          debugPrint('Voice reconnected');
          _setPhase(
            _muted ? AiVoiceAgentPhase.muted : AiVoiceAgentPhase.listening,
          );
        },
      );

      await _startMic();
      _setPhase(_muted ? AiVoiceAgentPhase.muted : AiVoiceAgentPhase.listening);
    } catch (e, st) {
      debugPrint('Voice agent start failed: $e\n$st');
      _setPhase(AiVoiceAgentPhase.error);
      onError('مقدرناش نفتح المحادثة الصوتية. حاول تاني.');
    }
  }

  Future<void> setMuted(bool muted) async {
    _muted = muted;
    if (muted) {
      await _stopMic();
      _setPhase(AiVoiceAgentPhase.muted);
      return;
    }
    if (!_backgrounded) {
      await _startMic();
    }
    _setPhase(AiVoiceAgentPhase.listening);
  }

  Future<void> interruptFromUi() => _handleInterrupt(fromServer: false);

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_closed) return;
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      _backgrounded = true;
      unawaited(_stopMic());
      unawaited(_player.stopPlayback());
      return;
    }
    if (state == AppLifecycleState.resumed) {
      _backgrounded = false;
      if (!_muted && _started) {
        unawaited(_startMic());
        _setPhase(AiVoiceAgentPhase.listening);
      }
    }
  }

  Future<void> dispose() async {
    _closed = true;
    _playbackDrainTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    await _stopMic();
    await _hub.close();
    await _player.dispose();
    await _recorder.dispose();
  }

  void _onStatus(String phase) {
    switch (phase) {
      case 'response_complete':
        _scheduleListeningAfterPlaybackDrain();
        return;
      case 'listening':
        if (_shouldDelayListeningForPlayback()) {
          _scheduleListeningAfterPlaybackDrain();
          return;
        }
        _finishSpeakingPhase();
        break;
      case 'processing':
        if (_agentSpeaking || _shouldDelayListeningForPlayback()) {
          return;
        }
        _setPhase(AiVoiceAgentPhase.processing);
        break;
      case 'speaking':
        _agentSpeaking = true;
        _playbackStartedAt ??= DateTime.now();
        _setPhase(AiVoiceAgentPhase.speaking);
        break;
    }
  }

  bool _shouldDelayListeningForPlayback() =>
      _player.queuedResponseBytes > 0 ||
      _lastResponseAudioAt != null &&
          DateTime.now().difference(_lastResponseAudioAt!).inMilliseconds < 1200;

  void _scheduleListeningAfterPlaybackDrain() {
    _playbackDrainTimer?.cancel();
    final delayMs = _player.estimateRemainingPlaybackMs();
    _playbackDrainTimer = Timer(Duration(milliseconds: delayMs), () {
      if (_closed) return;
      _finishSpeakingPhase();
    });
  }

  void _finishSpeakingPhase() {
    _playbackDrainTimer?.cancel();
    _agentSpeaking = false;
    _playbackStartedAt = null;
    _lastResponseAudioAt = null;
    _player.markResponsePlaybackComplete();
    _setPhase(
      _muted ? AiVoiceAgentPhase.muted : AiVoiceAgentPhase.listening,
    );
  }

  Future<void> _startMic() async {
    if (_closed || _muted || _backgrounded) return;
    await _stopMic();
    final hasPermission = await _recorder.hasPermission();
    if (!hasPermission) {
      onError('Microphone permission is required for voice chat.');
      return;
    }

    const config = RecordConfig(
      encoder: AudioEncoder.pcm16bits,
      sampleRate: AiVoicePcmPlayer.sampleRate,
      numChannels: 1,
      autoGain: true,
      echoCancel: true,
      noiseSuppress: true,
      androidConfig: AndroidRecordConfig(
        audioSource: AndroidAudioSource.voiceRecognition,
        speakerphone: true,
        audioManagerMode: AudioManagerMode.modeNormal,
      ),
      iosConfig: IosRecordConfig(
        categoryOptions: [
          IosAudioCategoryOption.defaultToSpeaker,
          IosAudioCategoryOption.allowBluetooth,
          IosAudioCategoryOption.allowBluetoothA2DP,
          IosAudioCategoryOption.mixWithOthers,
        ],
      ),
    );

    final stream = await _recorder.startStream(config);
    _micSub = stream.listen(
      _onMicBytes,
      onError: (Object e, StackTrace st) {
        debugPrint('Mic stream error: $e\n$st');
      },
    );
    _ampSub = _recorder.onAmplitudeChanged(const Duration(milliseconds: 90)).listen(
      _onAmplitude,
      onError: (_) {},
    );
    await AiVoiceSpeakerRoute.apply();
  }

  Future<void> _stopMic() async {
    await _ampSub?.cancel();
    _ampSub = null;
    await _micSub?.cancel();
    _micSub = null;
    try {
      if (await _recorder.isRecording()) {
        await _recorder.stop();
      }
    } catch (_) {}
    _sendBuffer.clear();
  }

  void _onMicBytes(Uint8List bytes) {
    if (_closed || _muted || _backgrounded || bytes.isEmpty) return;
    // Keep amplitude barge-in, but do not bill OpenAI for echo while speaking.
    if (_agentSpeaking) return;
    _sendBuffer.add(bytes);
    // ~80ms at 24 kHz PCM16 mono. Smaller chunks keep VAD from starving.
    if (_sendBuffer.length >= 3840) {
      final chunk = Uint8List.fromList(_sendBuffer.takeBytes());
      unawaited(_sendAudio(chunk));
    }
  }

  Future<void> _sendAudio(Uint8List chunk) async {
    if (_sendingAudio) {
      _sendBuffer.add(chunk);
      return;
    }
    _sendingAudio = true;
    try {
      await _hub.sendAudioChunk(chunk);
      while (!_closed && _sendBuffer.length >= 3840) {
        final next = Uint8List.fromList(_sendBuffer.takeBytes());
        await _hub.sendAudioChunk(next);
      }
    } catch (e, st) {
      debugPrint('Voice send audio failed: $e\n$st');
    } finally {
      _sendingAudio = false;
    }
  }

  Future<void> _recoverSession() async {
    if (_closed || _recovering) return;
    final now = DateTime.now();
    if (now.difference(_lastRecoveryAt) > const Duration(seconds: 45)) {
      _recoveries = 0;
    }
    if (_recoveries >= 3) {
      _setPhase(AiVoiceAgentPhase.error);
      onError('مقدرناش نثبت الاتصال الصوتي. اقفل المكالمة وافتحها تاني.');
      return;
    }
    _recovering = true;
    _recoveries++;
    _lastRecoveryAt = now;
    _setPhase(AiVoiceAgentPhase.connecting);
    try {
      await _hub.restartSession();
      if (!_muted && !_backgrounded) {
        await _startMic();
      }
      _setPhase(_muted ? AiVoiceAgentPhase.muted : AiVoiceAgentPhase.listening);
    } catch (e, st) {
      debugPrint('Voice recover failed: $e\n$st');
      _setPhase(AiVoiceAgentPhase.error);
      onError('مقدرناش نفتح المحادثة الصوتية. حاول تاني.');
    } finally {
      _recovering = false;
    }
  }

  void _onAmplitude(Amplitude amp) {
    if (_closed || _muted || !_agentSpeaking) {
      _loudFramesWhileSpeaking = 0;
      return;
    }
    final started = _playbackStartedAt;
    if (started == null ||
        DateTime.now().difference(started).inMilliseconds < _bargeInGraceMs) {
      return;
    }

    final closeEnough = amp.current >= _bargeInThresholdDb &&
        amp.max >= _bargeInPeakThresholdDb;
    if (closeEnough) {
      _loudFramesWhileSpeaking++;
    } else {
      _loudFramesWhileSpeaking = 0;
    }

    if (_loudFramesWhileSpeaking >= _bargeInRequiredFrames) {
      debugPrint(
        'Voice close-range barge-in current=${amp.current} max=${amp.max}',
      );
      _loudFramesWhileSpeaking = 0;
      unawaited(_handleInterrupt(fromServer: false));
    }
  }

  Future<void> _handleInterrupt({required bool fromServer}) async {
    try {
      _agentSpeaking = false;
      _playbackStartedAt = null;
      _loudFramesWhileSpeaking = 0;
      await _player.stopPlayback();
      if (!fromServer) {
        await _hub.interruptAgent();
      }
      if (!_muted) {
        _setPhase(AiVoiceAgentPhase.listening);
      }
    } catch (e, st) {
      debugPrint('Voice interrupt failed: $e\n$st');
    }
  }

  void _setPhase(AiVoiceAgentPhase phase) {
    if (_closed) return;
    _phase = phase;
    onPhase(phase);
  }
}
