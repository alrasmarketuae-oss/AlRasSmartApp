part of 'ai_assistant_view.dart';

mixin _AiAssistantVoiceMixin on _AiAssistantViewStateBase {
  Future<void> _initVoice() async {
    try {
      final male = await AiAssistantVoicePrefs.isMale();
      _voiceGender = male ? AiVoiceGender.male : AiVoiceGender.female;
    } catch (_) {}

    try {
      // iOS requires explicit audio category for TTS to produce sound.
      await _tts.setIosAudioCategory(
        IosTextToSpeechAudioCategory.playback,
        [
          IosTextToSpeechAudioCategoryOptions.allowBluetooth,
          IosTextToSpeechAudioCategoryOptions.allowBluetoothA2DP,
          IosTextToSpeechAudioCategoryOptions.defaultToSpeaker,
          IosTextToSpeechAudioCategoryOptions.mixWithOthers,
        ],
      );
      await _tts.setSpeechRate(AiAssistantTtsVoice.femaleSpeechRate);
      await _tts.setPitch(AiAssistantTtsVoice.femalePitch);
      await _tts.setVolume(1.0);
      await _tts.awaitSpeakCompletion(true);
      _tts.setCompletionHandler(() {
        _assistantSpeaking = false;
        if (mounted) setState(() {});
      });
      _tts.setCancelHandler(() {
        _assistantSpeaking = false;
        if (mounted) setState(() {});
      });
      _tts.setErrorHandler((msg) {
        debugPrint('TTS error: $msg');
        _assistantSpeaking = false;
        if (mounted) setState(() {});
        unawaited(_onAssistantSpeechFinished());
      });
      _voiceReady = true;
      if (mounted) {
        final langCode = Localizations.localeOf(context).languageCode;
        await _applyAssistantVoice(langCode, force: true);
      }
    } catch (e) {
      debugPrint('TTS init error: $e');
      _voiceReady = false;
    }

    if (mounted) setState(() {});
    if (widget.startInVoiceCall && mounted) {
      await _setVoiceConversationMode(true);
    }
  }

  Future<void> _setVoiceConversationMode(bool enabled) async {
    setState(() {
      _voiceConversationMode = enabled;
      if (!enabled) {
        _micMuted = false;
        _micListening = false;
        _micTranscribing = false;
        _assistantSpeaking = false;
        _voiceAgentPhase = AiVoiceAgentPhase.connecting;
      }
    });
    if (!enabled) {
      await _tts.stop();
      _assistantSpeaking = false;
      _composerKey.currentState?.cancelVoiceCapture();
      _flushVoiceTranscriptIfNeeded(AiVoiceAgentPhase.listening);
      final agent = _voiceAgent;
      _voiceAgent = null;
      await agent?.dispose();
      return;
    }

    _composerKey.currentState?.cancelVoiceCapture();
    await _tts.stop();
    await _startRealtimeVoiceAgent();
  }

  Future<void> _startRealtimeVoiceAgent() async {
    await _voiceAgent?.dispose();
    _voiceAgent = null;
    _voiceAssistantBuffer = '';
    if (!mounted || !_voiceConversationMode) return;
    final langCode = Localizations.localeOf(context).languageCode;
    final agent = AiVoiceAgentController(
      language: langCode == 'en' ? 'en' : 'ar',
      voiceGender: _voiceGender == AiVoiceGender.male ? 'male' : 'female',
      onPhase: (phase) {
        if (!mounted) return;
        _flushVoiceTranscriptIfNeeded(phase);
        setState(() {
          _voiceAgentPhase = phase;
          _micListening = phase == AiVoiceAgentPhase.listening;
          _assistantSpeaking = phase == AiVoiceAgentPhase.speaking;
          _micTranscribing = phase == AiVoiceAgentPhase.processing;
          if (phase == AiVoiceAgentPhase.muted) {
            _micMuted = true;
          } else if (phase == AiVoiceAgentPhase.listening ||
              phase == AiVoiceAgentPhase.speaking ||
              phase == AiVoiceAgentPhase.processing) {
            _micMuted = false;
          }
        });
      },
      onUserTranscript: (text) {
        if (!mounted || text.trim().isEmpty) return;
        setState(() {
          _messages.add(AiChatMessage(text: text.trim(), isUser: true));
        });
        _scrollToEnd();
      },
      onAssistantTranscript: (text) {
        _voiceAssistantBuffer += text;
      },
      onError: (message) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      },
    );
    _voiceAgent = agent;
    await agent.start();
  }

  void _flushVoiceTranscriptIfNeeded(AiVoiceAgentPhase phase) {
    if (phase != AiVoiceAgentPhase.listening) {
      return;
    }
    final text = _voiceAssistantBuffer.trim();
    if (text.isEmpty) return;
    _voiceAssistantBuffer = '';
    if (!mounted) return;
    setState(() {
      _messages.add(AiChatMessage(text: text, isUser: false));
    });
    _scrollToEnd();
  }

  Future<void> _toggleMicMute() async {
    setState(() => _micMuted = !_micMuted);
    final agent = _voiceAgent;
    if (agent != null) {
      await agent.setMuted(_micMuted);
      return;
    }
    if (_micMuted) {
      _composerKey.currentState?.cancelVoiceCapture();
      setState(() => _micListening = false);
      return;
    }
    if (!_isThinking && !_assistantSpeaking) {
      await _beginVoiceConversationLoop();
    }
  }

  Future<void> _toggleOverlayMic() async {
    if (_voiceAgent != null) {
      await _toggleMicMute();
      return;
    }
    if (_micMuted || _isThinking || _assistantSpeaking) return;
    final composer = _composerKey.currentState;
    if (composer == null) return;
    if (composer.isListening) {
      await composer.finishVoiceTurn();
    } else {
      await composer.beginVoiceTurn(autoSend: true);
    }
  }

  Future<void> _beginVoiceConversationLoop() async {
    if (_voiceAgent != null) return;
    if (!mounted ||
        !_voiceConversationMode ||
        _micMuted ||
        _isThinking ||
        _assistantSpeaking) {
      return;
    }
    await Future<void>.delayed(const Duration(milliseconds: 80));
    if (!mounted ||
        !_voiceConversationMode ||
        _micMuted ||
        _isThinking ||
        _assistantSpeaking) {
      return;
    }
    await _composerKey.currentState?.beginVoiceTurn(autoSend: true);
  }

  Future<void> _onAssistantSpeechFinished() async {
    if (!mounted || !_voiceConversationMode || _isThinking) return;
    await _beginVoiceConversationLoop();
  }

  String _textForSpeech(String text) {
    var clean = text.trim();
    clean = clean.replaceAll(RegExp(r'\[([^\]]+)\]\([^)]+\)'), r'$1');
    clean = clean.replaceAll('**', '').replaceAll('*', '');
    clean = clean.replaceAll(RegExp(r'\s+'), ' ').trim();
    return clean;
  }

  Future<void> _setVoiceGender(AiVoiceGender gender) async {
    if (_voiceGender == gender) return;
    setState(() => _voiceGender = gender);
    try {
      await AiAssistantVoicePrefs.setMale(gender == AiVoiceGender.male);
    } catch (_) {}

    if (!_voiceReady || !mounted) return;
    await _tts.stop();
    if (!mounted) return;
    _assistantSpeaking = false;
    final langCode = Localizations.localeOf(context).languageCode;
    await _applyAssistantVoice(langCode, force: true);
    if (_voiceConversationMode && _voiceAgent != null) {
      unawaited(_startRealtimeVoiceAgent());
      return;
    }
    await _previewAssistantVoice(langCode);
    if (mounted) setState(() {});
  }

  Future<void> _previewAssistantVoice(String langCode) async {
    if (!_voiceReady || !mounted) return;
    try {
      if (Platform.isIOS) {
        await _tts.setIosAudioCategory(
          IosTextToSpeechAudioCategory.playback,
          [
            IosTextToSpeechAudioCategoryOptions.allowBluetooth,
            IosTextToSpeechAudioCategoryOptions.allowBluetoothA2DP,
            IosTextToSpeechAudioCategoryOptions.defaultToSpeaker,
            IosTextToSpeechAudioCategoryOptions.mixWithOthers,
          ],
        );
      }
      await _ensureTtsLanguage(langCode);
      await _applyAssistantVoice(langCode, force: true);
      await _tts.setVolume(1.0);
      await _tts.speak(AiAssistantTtsVoice.previewPhrase(langCode));
    } catch (e) {
      debugPrint('TTS preview error: $e');
    }
  }

  Future<bool> _ensureTtsLanguage(String langCode) async {
    // Try Arabic first, then fall back to English so the user always hears something.
    final candidates = langCode == 'ar'
        ? const ['ar-SA', 'ar-AE', 'ar-EG', 'ar', 'en-US', 'en-GB', 'en']
        : const ['en-US', 'en-GB', 'en', 'ar-SA', 'ar'];
    for (final locale in candidates) {
      try {
        final ok = await _tts.isLanguageAvailable(locale);
        if (ok == true) {
          await _tts.setLanguage(locale);
          return true;
        }
      } catch (_) {}
    }
    // Last resort: set without checking availability.
    try {
      await _tts.setLanguage('en-US');
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> _applyAssistantVoice(String langCode, {bool force = false}) async {
    final isFemale = _voiceGender == AiVoiceGender.female;
    await _tts.setPitch(AiAssistantTtsVoice.pitchFor(isFemale: isFemale));
    await _tts.setSpeechRate(AiAssistantTtsVoice.speechRateFor(isFemale: isFemale));

    try {
      final voices = await _tts.getVoices;
      if (voices is! List || voices.isEmpty) return;

      final payload = AiAssistantTtsVoice.pickVoicePayload(
        voices: voices,
        isFemale: isFemale,
        langCode: langCode,
      );
      if (payload == null) return;

      final signature = AiAssistantTtsVoice.signature(payload);
      if (!force &&
          signature == _appliedVoiceSignature &&
          _voiceGender == _appliedVoiceGender) {
        return;
      }

      await _tts.setVoice(payload);
      _appliedVoiceSignature = signature;
      _appliedVoiceGender = _voiceGender;
    } catch (_) {
      // getVoices/setVoice failed; pitch and rate still apply.
    }
  }

  Future<void> _speakAssistantReply(String text) async {
    if (!_voiceConversationMode) return;
    final clean = _textForSpeech(text);
    if (clean.isEmpty) {
      unawaited(_onAssistantSpeechFinished());
      return;
    }

    if (!_voiceReady) {
      unawaited(_onAssistantSpeechFinished());
      return;
    }

    if (!mounted) return;
    final langCode = Localizations.localeOf(context).languageCode;
    _composerKey.currentState?.cancelVoiceCapture();

    try {
      await _tts.stop();
      if (Platform.isIOS) {
        await _tts.setIosAudioCategory(
          IosTextToSpeechAudioCategory.playback,
          [
            IosTextToSpeechAudioCategoryOptions.allowBluetooth,
            IosTextToSpeechAudioCategoryOptions.allowBluetoothA2DP,
            IosTextToSpeechAudioCategoryOptions.defaultToSpeaker,
            IosTextToSpeechAudioCategoryOptions.mixWithOthers,
          ],
        );
      }
      await _ensureTtsLanguage(langCode);
      await _applyAssistantVoice(langCode);
      await _tts.setVolume(1.0);
      if (!mounted) return;
      setState(() => _assistantSpeaking = true);
      await _tts.speak(clean);
      if (!mounted) return;
      setState(() => _assistantSpeaking = false);
      await _onAssistantSpeechFinished();
    } catch (e) {
      debugPrint('TTS speak error: $e');
      _assistantSpeaking = false;
      if (mounted) setState(() {});
      unawaited(_onAssistantSpeechFinished());
    }
  }

  AiCallPhase get _callPhase {
    if (_voiceConversationMode && _voiceAgent != null) {
      return switch (_voiceAgentPhase) {
        AiVoiceAgentPhase.muted => AiCallPhase.muted,
        AiVoiceAgentPhase.speaking => AiCallPhase.speaking,
        AiVoiceAgentPhase.listening => AiCallPhase.listening,
        AiVoiceAgentPhase.processing => AiCallPhase.thinking,
        AiVoiceAgentPhase.connecting => AiCallPhase.waiting,
        AiVoiceAgentPhase.error => AiCallPhase.waiting,
      };
    }
    if (_micMuted) return AiCallPhase.muted;
    if (_assistantSpeaking) return AiCallPhase.speaking;
    if (_micListening) return AiCallPhase.listening;
    if (_voiceConversationMode && (_isThinking || _micTranscribing)) {
      return AiCallPhase.waiting;
    }
    if (_isThinking || _micTranscribing) return AiCallPhase.thinking;
    return AiCallPhase.waiting;
  }

  bool get _voiceCallProcessing =>
      _voiceConversationMode &&
      (_voiceAgentPhase == AiVoiceAgentPhase.connecting ||
          _voiceAgentPhase == AiVoiceAgentPhase.processing ||
          ((_micTranscribing || _isThinking) &&
              _voiceAgent == null &&
              !_micListening &&
              !_assistantSpeaking &&
              !_micMuted));

  String? get _voiceGenderLabel {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    return _voiceGender == AiVoiceGender.female
        ? (isAr ? 'صوت سول — أنثى' : 'Soul voice — female')
        : (isAr ? 'صوت سول — ذكر' : 'Soul voice — male');
  }
}
