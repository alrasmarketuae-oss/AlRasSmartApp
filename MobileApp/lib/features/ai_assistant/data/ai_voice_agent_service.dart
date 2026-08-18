import 'dart:async';
import 'dart:convert';

import 'package:alrasmarket/core/services/api_constants.dart';
import 'package:alrasmarket/core/serveses/auth_service.dart';
import 'package:flutter/foundation.dart';
import 'package:signalr_netcore/signalr_client.dart';

class AiVoiceAgentService {
  HubConnection? _hub;
  bool _closed = false;
  int _connectGeneration = 0;
  String _language = 'ar';
  String _voiceGender = 'female';
  VoidCallback? _onReconnected;

  bool get isConnected =>
      !_closed && _hub?.state == HubConnectionState.Connected;

  Future<void> connect({
    required String language,
    required String voiceGender,
    required void Function(String phase) onStatus,
    required void Function(Uint8List pcm, {required String kind}) onAudio,
    required void Function(String role, String text, {required bool isFinal})
        onTranscript,
    required VoidCallback onInterrupted,
    required void Function(String message) onError,
    required void Function(Map<String, dynamic> metrics) onMetrics,
    required VoidCallback onReconnecting,
    required VoidCallback onReconnected,
  }) async {
    if (_closed) return;
    _language = language;
    _voiceGender = voiceGender;
    _onReconnected = onReconnected;
    final generation = ++_connectGeneration;
    await _stopHubOnly();
    if (_closed || generation != _connectGeneration) return;

    final token = AuthService.instance.currentToken?.trim();
    final builder = HubConnectionBuilder();
    final options = token != null && token.isNotEmpty
        ? HttpConnectionOptions(
            accessTokenFactory: () async =>
                AuthService.instance.currentToken ?? token,
          )
        : HttpConnectionOptions();
    builder.withUrl(ApiConstants.aiVoiceAgentHubUrl, options: options);
    try {
      builder.withAutomaticReconnect(
        retryDelays: [0, 2000, 4000, 8000, 15000],
      );
    } catch (_) {
      try {
        builder.withAutomaticReconnect();
      } catch (_) {}
    }

    final hub = builder.build();
    _hub = hub;

    hub.on('voiceStatus', (args) {
      if (_closed || generation != _connectGeneration) return;
      final phase = _map(args)?['phase']?.toString() ?? '';
      if (phase.isNotEmpty) onStatus(phase);
    });
    hub.on('voiceAudio', (args) {
      if (_closed || generation != _connectGeneration) return;
      final data = _map(args);
      final b64 = data?['pcmBase64']?.toString() ?? data?['PcmBase64']?.toString();
      if (b64 == null || b64.isEmpty) return;
      try {
        final pcm = base64Decode(b64);
        final kind = data?['kind']?.toString() ?? 'response';
        onAudio(pcm, kind: kind);
      } catch (e) {
        debugPrint('Voice audio decode failed: $e');
      }
    });
    hub.on('voiceTranscript', (args) {
      if (_closed || generation != _connectGeneration) return;
      final data = _map(args);
      final text = data?['text']?.toString() ?? '';
      if (text.isEmpty) return;
      onTranscript(
        data?['role']?.toString() ?? 'assistant',
        text,
        isFinal: data?['final'] == true || data?['Final'] == true,
      );
    });
    hub.on('voiceInterrupted', (_) {
      if (_closed || generation != _connectGeneration) return;
      onInterrupted();
    });
    hub.on('voiceError', (args) {
      if (_closed || generation != _connectGeneration) return;
      onError(
        _map(args)?['message']?.toString() ??
            'Voice agent is unavailable right now.',
      );
    });
    hub.on('voiceMetrics', (args) {
      if (_closed || generation != _connectGeneration) return;
      final data = _map(args);
      if (data != null) onMetrics(data);
    });

    hub.onclose(({error}) {
      debugPrint('Voice hub closed: $error');
    });
    hub.onreconnecting(({error}) {
      debugPrint('Voice hub reconnecting: $error');
      onReconnecting();
    });
    hub.onreconnected(({connectionId}) {
      debugPrint('Voice hub reconnected: $connectionId');
      unawaited(_restartSession());
      _onReconnected?.call();
      onReconnected();
    });

    await hub.start();
    if (_closed || generation != _connectGeneration || !identical(_hub, hub)) {
      try {
        await hub.stop();
      } catch (_) {}
      return;
    }
    await hub.invoke('StartSession', args: [_language, _voiceGender]);
  }

  Future<void> sendAudioChunk(Uint8List pcm) async {
    final hub = _hub;
    if (_closed || hub == null || hub.state != HubConnectionState.Connected) {
      return;
    }
    if (pcm.isEmpty) return;
    await hub.invoke('SendAudioChunk', args: [base64Encode(pcm)]);
  }

  Future<void> interruptAgent() async {
    final hub = _hub;
    if (_closed || hub == null || hub.state != HubConnectionState.Connected) {
      return;
    }
    try {
      await hub.invoke('InterruptAgent');
    } catch (_) {}
  }

  Future<void> stopSession() async {
    final hub = _hub;
    if (hub == null) return;
    try {
      if (hub.state == HubConnectionState.Connected) {
        await hub.invoke('StopSession');
      }
    } catch (_) {}
  }

  Future<void> close() async {
    _closed = true;
    _connectGeneration++;
    await stopSession();
    await _stopHubOnly();
  }

  Future<void> _restartSession() async {
    final hub = _hub;
    if (_closed || hub == null || hub.state != HubConnectionState.Connected) {
      return;
    }
    try {
      await hub.invoke('StartSession', args: [_language, _voiceGender]);
    } catch (e) {
      debugPrint('Voice StartSession after reconnect failed: $e');
    }
  }

  Future<void> _stopHubOnly() async {
    final hub = _hub;
    _hub = null;
    if (hub == null) return;
    try {
      await hub.stop();
    } catch (_) {}
  }

  Map<String, dynamic>? _map(List<Object?>? args) {
    if (args == null || args.isEmpty || args.first is! Map) return null;
    return Map<String, dynamic>.from(args.first! as Map);
  }
}
