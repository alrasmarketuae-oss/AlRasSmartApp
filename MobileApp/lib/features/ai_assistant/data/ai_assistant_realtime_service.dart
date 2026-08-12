import 'dart:math';

import 'package:alrasmarket/core/services/api_constants.dart';
import 'package:alrasmarket/core/serveses/auth_service.dart';
import 'package:signalr_netcore/signalr_client.dart';

class AiAssistantRealtimeService {
  AiAssistantRealtimeService({String? sessionId})
      : _sessionId = sessionId ?? _newSessionId();

  HubConnection? _hub;

  /// Keeps the server-side chat history attached to this screen instead of the
  /// SignalR connection, which changes id on every auto-reconnect.
  String _sessionId;

  String get sessionId => _sessionId;

  /// Resume a saved conversation so the hub loads that session's DB history.
  void attachToSession(String sessionId) {
    final clean = sessionId.trim();
    if (clean.isEmpty || clean.length > 64) return;
    _sessionId = clean;
  }

  /// Set when the AI screen is leaving so an in-flight connect cannot orphan a hub.
  bool _closed = false;
  int _connectGeneration = 0;

  bool get isConnected =>
      !_closed && _hub?.state == HubConnectionState.Connected;

  Future<void> connect({
    required void Function(bool value) onThinking,
    required void Function(String step) onThinkingStep,
    required void Function() onResponseStarted,
    required void Function(String value) onDelta,
    required void Function(String answer) onCompleted,
    required void Function(String message) onError,
  }) async {
    if (_closed) return;
    if (isConnected) return;

    final generation = ++_connectGeneration;
    await _stopHubOnly();
    if (_closed || generation != _connectGeneration) return;

    final token = AuthService.instance.currentToken?.trim();
    final builder = HubConnectionBuilder();
    if (token != null && token.isNotEmpty) {
      builder.withUrl(
        ApiConstants.aiAssistantHubUrl,
        options: HttpConnectionOptions(
          accessTokenFactory: () async =>
              AuthService.instance.currentToken ?? token,
        ),
      );
    } else {
      builder.withUrl(ApiConstants.aiAssistantHubUrl);
    }

    // No automatic reconnect: this hub is screen-scoped and must die on exit.
    final hub = builder.build();
    _hub = hub;

    hub.on('aiThinking', (args) {
      if (_closed || generation != _connectGeneration) return;
      final data = _map(args);
      onThinking(data?['isThinking'] == true);
    });
    hub.on('aiThinkingStep', (args) {
      if (_closed || generation != _connectGeneration) return;
      final value = _map(args)?['text']?.toString().trim() ?? '';
      if (value.isNotEmpty) onThinkingStep(value);
    });
    hub.on('aiResponseStarted', (_) {
      if (_closed || generation != _connectGeneration) return;
      onResponseStarted();
    });
    hub.on('aiDelta', (args) {
      if (_closed || generation != _connectGeneration) return;
      final value = _map(args)?['text']?.toString() ?? '';
      if (value.isNotEmpty) onDelta(value);
    });
    hub.on('aiResponseCompleted', (args) {
      if (_closed || generation != _connectGeneration) return;
      onCompleted(_map(args)?['answer']?.toString() ?? '');
    });
    hub.on('aiError', (args) {
      if (_closed || generation != _connectGeneration) return;
      onError(
        _map(args)?['message']?.toString() ??
            'AI Assistant is unavailable right now.',
      );
    });

    await hub.start();
    if (_closed || generation != _connectGeneration || !identical(_hub, hub)) {
      try {
        await hub.stop();
      } catch (_) {}
      return;
    }
  }

  Future<void> ask({required String message, required String language}) async {
    if (_closed) {
      throw StateError('AI Assistant session was closed.');
    }
    final hub = _hub;
    if (hub == null || hub.state != HubConnectionState.Connected) {
      throw StateError('AI Assistant is not connected.');
    }
    await hub.invoke('AskInSession', args: [message, language, _sessionId]);
  }

  /// Stops the SignalR connection. Conversation history stays in the database.
  Future<void> close() async {
    _closed = true;
    _connectGeneration++;
    final hub = _hub;
    _hub = null;
    if (hub == null) return;
    try {
      await hub.stop();
    } catch (_) {}
  }

  Future<void> _stopHubOnly() async {
    final hub = _hub;
    _hub = null;
    if (hub == null) return;
    try {
      await hub.stop();
    } catch (_) {}
  }

  static String _newSessionId() {
    final random = Random.secure();
    return List.generate(
      16,
      (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0'),
    ).join();
  }

  Map<String, dynamic>? _map(List<Object?>? args) {
    if (args == null || args.isEmpty || args.first is! Map) return null;
    return Map<String, dynamic>.from(args.first! as Map);
  }
}
