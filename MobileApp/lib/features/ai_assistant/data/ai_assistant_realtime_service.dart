import 'dart:math';

import 'package:alrasmarket/core/services/api_constants.dart';
import 'package:alrasmarket/core/serveses/auth_service.dart';
import 'package:signalr_netcore/signalr_client.dart';

class AiAssistantRealtimeService {
  HubConnection? _hub;

  /// Keeps the server-side chat history attached to this screen instead of the
  /// SignalR connection, which changes id on every auto-reconnect.
  final String _sessionId = _newSessionId();

  bool get isConnected => _hub?.state == HubConnectionState.Connected;

  Future<void> connect({
    required void Function(bool value) onThinking,
    required void Function() onResponseStarted,
    required void Function(String value) onDelta,
    required void Function(String answer) onCompleted,
    required void Function(String message) onError,
  }) async {
    if (isConnected) return;
    await close();

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

    _hub = builder.withAutomaticReconnect().build();
    _hub!.on('aiThinking', (args) {
      final data = _map(args);
      onThinking(data?['isThinking'] == true);
    });
    _hub!.on('aiResponseStarted', (_) => onResponseStarted());
    _hub!.on('aiDelta', (args) {
      final value = _map(args)?['text']?.toString() ?? '';
      if (value.isNotEmpty) onDelta(value);
    });
    _hub!.on('aiResponseCompleted', (args) {
      onCompleted(_map(args)?['answer']?.toString() ?? '');
    });
    _hub!.on('aiError', (args) {
      onError(
        _map(args)?['message']?.toString() ??
            'AI Assistant is unavailable right now.',
      );
    });

    await _hub!.start();
  }

  Future<void> ask({required String message, required String language}) async {
    final hub = _hub;
    if (hub == null || hub.state != HubConnectionState.Connected) {
      throw StateError('AI Assistant is not connected.');
    }
    await hub.invoke('AskInSession', args: [message, language, _sessionId]);
  }

  Future<void> close() async {
    final hub = _hub;
    _hub = null;
    if (hub == null) return;
    try {
      if (hub.state == HubConnectionState.Connected) {
        await hub.invoke('ClearSessionById', args: [_sessionId]);
      }
    } catch (_) {
      // The server also removes session history in OnDisconnected.
    }
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
