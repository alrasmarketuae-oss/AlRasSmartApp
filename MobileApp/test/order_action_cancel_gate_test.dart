import 'package:alrasmarket/core/services/order_action_cancel_gate.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late OrderActionCancelGate gate;

  setUp(() {
    gate = OrderActionCancelGate();
  });

  test('cancel after arm marks action cancelled and cancels token', () {
    final token = gate.arm();
    final id = gate.actionId;

    expect(gate.isCancelledFor(id, token), isFalse);

    gate.cancel();

    expect(gate.cancelledByUser, isTrue);
    expect(token.isCancelled, isTrue);
    expect(gate.isCancelledFor(id, token), isTrue);
  });

  test('cancel survives clearToken so late HTTP success is still cancelled', () {
    final token = gate.arm();
    final id = gate.actionId;

    gate.cancel();
    gate.clearToken();

    expect(gate.token, isNull);
    expect(gate.isCancelledFor(id, token), isTrue);
  });

  test('arm after cancel starts a fresh non-cancelled action', () {
    gate.arm();
    gate.cancel();

    final token = gate.arm();
    final id = gate.actionId;

    expect(gate.cancelledByUser, isFalse);
    expect(token.isCancelled, isFalse);
    expect(gate.isCancelledFor(id, token), isFalse);
  });

  test('cancel before HTTP start makes Dio reject with cancel type', () async {
    final token = gate.arm();
    gate.cancel();

    final dio = Dio(
      BaseOptions(
        baseUrl: 'https://example.com',
        connectTimeout: const Duration(seconds: 2),
      ),
    );

    await expectLater(
      dio.get<void>('/slow', cancelToken: token),
      throwsA(
        isA<DioException>().having(
          (e) => e.type,
          'type',
          DioExceptionType.cancel,
        ),
      ),
    );
  });

  test('simulated create flow does not treat success after cancel', () async {
    final token = gate.arm();
    final id = gate.actionId;

    // Start "HTTP" work.
    final pending = Future<String>.delayed(
      const Duration(milliseconds: 80),
      () => 'order-99',
    );

    // User hits Cancel immediately.
    await Future<void>.delayed(const Duration(milliseconds: 10));
    gate.cancel();

    final orderId = await pending;
    final cancelled = gate.isCancelledFor(id, token);

    expect(orderId, 'order-99');
    expect(cancelled, isTrue);
    // UI must ignore orderId when cancelled.
    final shouldNavigateToSuccess = !cancelled && orderId.isNotEmpty;
    expect(shouldNavigateToSuccess, isFalse);
  });
}
