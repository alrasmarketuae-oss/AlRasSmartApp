import 'dart:async';

import 'package:alrasmarket/core/services/api_constants.dart';
import 'package:alrasmarket/core/serveses/auth_service.dart';
import 'package:flutter/foundation.dart';
import 'package:signalr_netcore/signalr_client.dart';

/// Live order updates via OrderHub (`/orderhub`).
/// - [startUserOrdersListener]: inbox refresh for orders list + badge count
/// - [joinOrder]: single-order tracking (track order screen)
class AppOrderListenerService {
  AppOrderListenerService._();

  static final AppOrderListenerService instance = AppOrderListenerService._();

  HubConnection? _hubConnection;
  int? _joinedOrderId;
  bool _userOrdersListening = false;
  bool _starting = false;

  final StreamController<int> _orderUpdatedController =
      StreamController<int>.broadcast();
  final StreamController<void> _userOrdersUpdatedController =
      StreamController<void>.broadcast();

  Stream<int> get orderUpdatedStream => _orderUpdatedController.stream;
  Stream<void> get userOrdersUpdatedStream =>
      _userOrdersUpdatedController.stream;

  bool get isConnected =>
      _hubConnection?.state == HubConnectionState.Connected;

  Future<void> startUserOrdersListener() async {
    final token = AuthService.instance.currentToken;
    if (token == null || token.isEmpty || token == 'null') {
      return;
    }

    _userOrdersListening = true;
    await _ensureConnected(token);
    if (!isConnected) return;

    try {
      await _hubConnection!.invoke('JoinUserOrders');
      debugPrint('AppOrderListenerService joined user orders inbox');
    } catch (e) {
      debugPrint('AppOrderListenerService JoinUserOrders failed: $e');
    }
  }

  Future<void> stopUserOrdersListener() async {
    _userOrdersListening = false;
    final hub = _hubConnection;

    if (hub != null && hub.state == HubConnectionState.Connected) {
      try {
        await hub.invoke('LeaveUserOrders');
      } catch (_) {}
    }

    if (_joinedOrderId == null) {
      await _stopConnectionOnly();
    }
  }

  Future<void> stop() async {
    _userOrdersListening = false;
    _joinedOrderId = null;
    await _stopConnectionOnly();
  }

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

    if (orderId != null && hub != null) {
      try {
        if (hub.state == HubConnectionState.Connected) {
          await hub.invoke('LeaveOrder', args: <Object>[orderId]);
        }
      } catch (_) {}
    }

    if (!_userOrdersListening) {
      await _stopConnectionOnly();
    }
  }

  Future<void> _ensureConnected(String token) async {
    if (isConnected || _starting) {
      if (_starting) {
        for (var i = 0; i < 20 && _starting; i++) {
          await Future<void>.delayed(const Duration(milliseconds: 50));
        }
      }
      if (isConnected) return;
    }

    _starting = true;
    try {
      if (_hubConnection == null) {
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
          await _rejoinGroupsAfterReconnect();
        });
      }

      if (_hubConnection!.state != HubConnectionState.Connected) {
        await _hubConnection!.start();
        debugPrint('AppOrderListenerService connected');
      }

      await _rejoinGroupsAfterReconnect();
    } catch (e) {
      debugPrint('AppOrderListenerService start failed: $e');
      if (!_userOrdersListening && _joinedOrderId == null) {
        await _stopConnectionOnly();
      }
    } finally {
      _starting = false;
    }
  }

  Future<void> _rejoinGroupsAfterReconnect() async {
    final hub = _hubConnection;
    if (hub == null || hub.state != HubConnectionState.Connected) {
      return;
    }

    if (_userOrdersListening) {
      try {
        await hub.invoke('JoinUserOrders');
      } catch (_) {}
    }

    final orderId = _joinedOrderId;
    if (orderId != null && orderId > 0) {
      try {
        await hub.invoke('JoinOrder', args: <Object>[orderId]);
      } catch (_) {}
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

    if (_userOrdersListening) {
      _userOrdersUpdatedController.add(null);
    }

    if (_joinedOrderId != null && _joinedOrderId != orderId) return;
    if (_joinedOrderId == null && !_userOrdersListening) return;

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
