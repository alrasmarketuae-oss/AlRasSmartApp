import 'package:alrasmarket/core/error/failure.dart';
import 'package:alrasmarket/core/usecase/base_usecase.dart';
import 'package:alrasmarket/features/clint/domain/entities/cart_entity.dart';
import 'package:alrasmarket/features/clint/domain/repository/base_cart_repository.dart';
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

class ReduceCartItemQuantityUseCase
    extends BaseUseCase<CartEntity, ReduceCartItemQuantityParams> {
  ReduceCartItemQuantityUseCase(this._repository);

  final BaseCartRepository _repository;

  @override
  Future<Either<Failure, CartEntity>> call(
    ReduceCartItemQuantityParams params,
  ) {
    return _repository.reduceCartItemQuantity(
      token: params.token,
      cartItemId: params.cartItemId,
      quantity: params.quantity,
    );
  }
}

class ReduceCartItemQuantityParams extends Equatable {
  const ReduceCartItemQuantityParams({
    required this.token,
    required this.cartItemId,
    required this.quantity,
  });

  final String token;
  final int cartItemId;
  final double quantity;

  @override
  List<Object?> get props => [token, cartItemId, quantity];
}
