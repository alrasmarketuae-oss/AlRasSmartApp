import 'dart:async';
import 'dart:typed_data';

import 'package:alrasmarket/features/ai_assistant/data/ai_voice_agent_service.dart';
import 'package:alrasmarket/features/ai_assistant/data/ai_voice_pcm_player.dart';
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
  DateTime? _playbackStartedAt;
  int _loudFramesWhileSpeaking = 0;
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
      await _hub.connect(
        language: language,
        voiceGender: voiceGender,
        onStatus: _onStatus,
        onAudio: (pcmBytes, {required kind}) {
          if (_closed) return;
          if (kind == 'response') {
            _agentSpeaking = true;
            _playbackStartedAt ??= DateTime.now();
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
        onError: (message) {
          debugPrint('Voice agent error: $message');
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
    } catch (e) {
      debugPrint('Voice agent start failed: $e');
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
    WidgetsBinding.instance.removeObserver(this);
    await _stopMic();
    await _hub.close();
    await _player.dispose();
    await _recorder.dispose();
  }

  void _onStatus(String phase) {
    switch (phase) {
      case 'listening':
        _agentSpeaking = false;
        _playbackStartedAt = null;
        _setPhase(
          _muted ? AiVoiceAgentPhase.muted : AiVoiceAgentPhase.listening,
        );
        break;
      case 'processing':
        _setPhase(AiVoiceAgentPhase.processing);
        break;
      case 'speaking':
        _agentSpeaking = true;
        _playbackStartedAt ??= DateTime.now();
        _setPhase(AiVoiceAgentPhase.speaking);
        break;
    }
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
        audioSource: AndroidAudioSource.voiceCommunication,
        speakerphone: true,
        audioManagerMode: AudioManagerMode.modeInCommunication,
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
    _micSub = stream.listen(_onMicBytes, onError: (Object e) {
      debugPrint('Mic stream error: $e');
    });
    _ampSub = _recorder.onAmplitudeChanged(const Duration(milliseconds: 90)).listen(
      _onAmplitude,
      onError: (_) {},
    );
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
    _sendBuffer.add(bytes);
    if (_sendBuffer.length >= 4800) {
      final chunk = Uint8List.fromList(_sendBuffer.takeBytes());
      unawaited(_hub.sendAudioChunk(chunk));
    }
  }

  void _onAmplitude(Amplitude amp) {
    if (_closed || _muted || !_agentSpeaking) {
      _loudFramesWhileSpeaking = 0;
      return;
    }
    final started = _playbackStartedAt;
    if (started == null ||
        DateTime.now().difference(started).inMilliseconds < 450) {
      return;
    }
    if (amp.current > -36) {
      _loudFramesWhileSpeaking++;
    } else {
      _loudFramesWhileSpeaking = 0;
    }
    if (_loudFramesWhileSpeaking >= 3) {
      debugPrint('Voice local barge-in amplitude=${amp.current}');
      unawaited(_handleInterrupt(fromServer: false));
    }
  }

  Future<void> _handleInterrupt({required bool fromServer}) async {
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
  }

  void _setPhase(AiVoiceAgentPhase phase) {
    if (_closed) return;
    _phase = phase;
    onPhase(phase);
  }
}
