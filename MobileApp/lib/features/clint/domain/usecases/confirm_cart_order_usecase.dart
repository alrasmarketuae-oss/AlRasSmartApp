import 'package:alrasmarket/core/error/failure.dart';
import 'package:alrasmarket/core/usecase/base_usecase.dart';
import 'package:alrasmarket/features/clint/data/models/cart_order_result_model.dart';
import 'package:alrasmarket/features/clint/domain/entities/cart_payment_method.dart';
import 'package:alrasmarket/features/clint/domain/repository/base_cart_repository.dart';
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

class ConfirmCartOrderUseCase
    extends BaseUseCase<CartOrderResultModel, ConfirmCartOrderParams> {
  ConfirmCartOrderUseCase(this._repository);

  final BaseCartRepository _repository;

  @override
  Future<Either<Failure, CartOrderResultModel>> call(
    ConfirmCartOrderParams params,
  ) {
    return _repository.confirmCartOrder(
      token: params.token,
      paymentMethod: params.paymentMethod,
      shippingCostAed: params.shippingCostAed,
      isSelfPickup: params.isSelfPickup,
      addressId: params.addressId,
      cityName: params.cityName,
      addressLine: params.addressLine,
    );
  }
}

class ConfirmCartOrderParams extends Equatable {
  const ConfirmCartOrderParams({
    required this.token,
    required this.paymentMethod,
    required this.shippingCostAed,
    this.isSelfPickup = false,
    this.addressId,
    this.cityName,
    this.addressLine,
  });

  final String token;
  final CartPaymentMethod paymentMethod;
  final double shippingCostAed;
  final bool isSelfPickup;
  final String? addressId;
  final String? cityName;
  final String? addressLine;

  @override
  List<Object?> get props => [
        token,
        paymentMethod,
        shippingCostAed,
        isSelfPickup,
        addressId,
        cityName,
        addressLine,
      ];
}
