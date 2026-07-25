import 'dart:async';

import 'package:alrasmarket/core/services/api_constants.dart';
import 'package:alrasmarket/core/serveses/auth_service.dart';
import 'package:flutter/foundation.dart';
import 'package:signalr_netcore/signalr_client.dart';

/// Live order details via OrderHub (`/orderhub`).
class AppOrderListenerService {
  AppOrderListenerService._();

  static final AppOrderListenerService instance = AppOrderListenerService._();

  HubConnection? _hubConnection;
  int? _joinedOrderId;
  bool _starting = false;

  final StreamController<int> _orderUpdatedController =
      StreamController<int>.broadcast();

  Stream<int> get orderUpdatedStream => _orderUpdatedController.stream;

  bool get isConnected =>
      _hubConnection?.state == HubConnectionState.Connected;

  Future<void> joinOrder(int orderId) async {
    if (orderId <= 0) return;

    final token = AuthService.instance.currentToken;
    if (token == null || token.isEmpty || token == 'null') {
      return;
    }

    if (_joinedOrderId == orderId && isConnected) {
      return;
    }

    await _ensureConnected(token);
    if (!isConnected) return;

    if (_joinedOrderId != null &&
        _joinedOrderId != orderId &&
        _hubConnection != null) {
      try {
        final previousId = _joinedOrderId!;
        await _hubConnection!.invoke('LeaveOrder', args: <Object>[previousId]);
      } catch (_) {}
    }

    try {
      await _hubConnection!.invoke('JoinOrder', args: <Object>[orderId]);
      _joinedOrderId = orderId;
      debugPrint('AppOrderListenerService joined Order_$orderId');
    } catch (e) {
      debugPrint('AppOrderListenerService JoinOrder failed: $e');
    }
  }

  Future<void> leaveOrder() async {
    final orderId = _joinedOrderId;
    final hub = _hubConnection;
    _joinedOrderId = null;

    if (orderId == null || hub == null) {
      await _stopConnectionOnly();
      return;
    }

    try {
      if (hub.state == HubConnectionState.Connected) {
        await hub.invoke('LeaveOrder', args: <Object>[orderId]);
      }
    } catch (_) {}

    await _stopConnectionOnly();
  }

  Future<void> _ensureConnected(String token) async {
    if (isConnected || _starting) {
      // Wait briefly if another start is in flight.
      if (_starting) {
        for (var i = 0; i < 20 && _starting; i++) {
          await Future<void>.delayed(const Duration(milliseconds: 50));
        }
      }
      if (isConnected) return;
    }

    _starting = true;
    try {
      await _stopConnectionOnly();

      _hubConnection = HubConnectionBuilder()
          .withUrl(
            ApiConstants.orderHubUrl,
            options: HttpConnectionOptions(
              accessTokenFactory: () async =>
                  AuthService.instance.currentToken ?? token,
            ),
          )
          .withAutomaticReconnect()
          .build();

      _hubConnection!.on('orderUpdated', _onOrderUpdated);
      _hubConnection!.onreconnected(({connectionId}) async {
        final orderId = _joinedOrderId;
        if (orderId != null && orderId > 0) {
          try {
            await _hubConnection?.invoke('JoinOrder', args: <Object>[orderId]);
          } catch (_) {}
        }
      });

      await _hubConnection!.start();
      debugPrint('AppOrderListenerService connected');
    } catch (e) {
      debugPrint('AppOrderListenerService start failed: $e');
      await _stopConnectionOnly();
    } finally {
      _starting = false;
    }
  }

  void _onOrderUpdated(List<Object?>? args) {
    if (args == null || args.isEmpty) return;
    final raw = args.first;
    int? orderId;
    if (raw is Map) {
      final value = raw['orderId'] ?? raw['OrderId'];
      if (value is int) {
        orderId = value;
      } else if (value is num) {
        orderId = value.toInt();
      } else {
        orderId = int.tryParse(value?.toString() ?? '');
      }
    } else if (raw is int) {
      orderId = raw;
    } else if (raw is num) {
      orderId = raw.toInt();
    }

    if (orderId == null || orderId <= 0) return;
    if (_joinedOrderId != null && _joinedOrderId != orderId) return;
    _orderUpdatedController.add(orderId);
  }

  Future<void> _stopConnectionOnly() async {
    _starting = false;
    try {
      await _hubConnection?.stop();
    } catch (_) {}
    _hubConnection = null;
  }
}
