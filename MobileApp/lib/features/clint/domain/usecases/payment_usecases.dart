import 'package:alrasmarket/core/error/failure.dart';
import 'package:alrasmarket/core/usecase/base_usecase.dart';
import 'package:alrasmarket/features/clint/data/datasource/payment_remote_data_source.dart';
import 'package:alrasmarket/features/clint/data/models/stripe_checkout_model.dart';
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

class CreateStripeCheckoutUseCase
    extends BaseUseCase<StripeCheckoutModel, CreateStripeCheckoutParams> {
  CreateStripeCheckoutUseCase(this._remote);

  final BasePaymentRemoteDataSource _remote;

  @override
  Future<Either<Failure, StripeCheckoutModel>> call(
    CreateStripeCheckoutParams params,
  ) {
    return _remote.createStripeCheckout(
      token: params.token,
      pendingOrderId: params.pendingOrderId,
    );
  }
}

class CreateStripeCheckoutParams extends Equatable {
  const CreateStripeCheckoutParams({
    required this.token,
    required this.pendingOrderId,
  });

  final String token;
  final String pendingOrderId;

  @override
  List<Object?> get props => [token, pendingOrderId];
}

class GetCheckoutStatusUseCase
    extends BaseUseCase<CheckoutStatusModel, GetCheckoutStatusParams> {
  GetCheckoutStatusUseCase(this._remote);

  final BasePaymentRemoteDataSource _remote;

  @override
  Future<Either<Failure, CheckoutStatusModel>> call(
    GetCheckoutStatusParams params,
  ) {
    return _remote.getCheckoutStatus(
      token: params.token,
      sessionId: params.sessionId,
    );
  }
}

class GetCheckoutStatusParams extends Equatable {
  const GetCheckoutStatusParams({
    required this.token,
    required this.sessionId,
  });

  final String token;
  final String sessionId;

  @override
  List<Object?> get props => [token, sessionId];
}
