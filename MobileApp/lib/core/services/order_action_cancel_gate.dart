import 'package:dio/dio.dart';

/// Single gate for in-flight purchase / offer / accept cancel.
///
/// Rules:
/// - [arm] starts a new action and clears prior cancel.
/// - [cancel] marks cancelled and aborts the Dio [CancelToken].
/// - Cancel stays true until the next [arm] (survives token clear / end).
/// - [isCancelledFor] also fails if the action id was invalidated by cancel.
class OrderActionCancelGate {
  int _actionId = 0;
  bool _cancelledByUser = false;
  CancelToken? _token;

  int get actionId => _actionId;
  CancelToken? get token => _token;
  bool get cancelledByUser => _cancelledByUser;

  CancelToken arm() {
    _cancelledByUser = false;
    _actionId++;
    final previous = _token;
    if (previous != null && !previous.isCancelled) {
      previous.cancel('replaced');
    }
    final token = CancelToken();
    _token = token;
    return token;
  }

  void cancel([String reason = 'user_cancelled']) {
    _cancelledByUser = true;
    _actionId++;
    final token = _token;
    if (token != null && !token.isCancelled) {
      token.cancel(reason);
    }
  }

  void clearToken() {
    _token = null;
  }

  bool isCancelledFor(int actionId, [CancelToken? token]) {
    if (_cancelledByUser) return true;
    if (actionId != _actionId) return true;
    final active = token ?? _token;
    return active?.isCancelled == true;
  }
}
