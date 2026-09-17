import 'package:equatable/equatable.dart';

abstract class Failure extends Equatable {
  final String message;
  const Failure(this.message);
  @override
  List<Object> get props => [message];
}

// General failures
class ServerFailure extends Failure {
  const ServerFailure(super.message);
}

class CacheFailure extends Failure {
  const CacheFailure(super.message);
}

class NetworkFailure extends Failure {
  const NetworkFailure(super.message);
}

/// User aborted an in-flight order/offer/accept request.
class CancelledFailure extends Failure {
  const CancelledFailure([super.message = code]);

  static const code = '__CANCELLED__';

  static bool matches(Failure failure) =>
      failure is CancelledFailure || failure.message == code;
}
