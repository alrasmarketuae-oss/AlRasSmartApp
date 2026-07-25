import 'package:alrasmarket/core/error/failure.dart';
import 'package:alrasmarket/core/usecase/base_usecase.dart';
import 'package:alrasmarket/features/clint/domain/entities/cart_entity.dart';
import 'package:alrasmarket/features/clint/domain/repository/base_cart_repository.dart';
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

class RemoveCartItemUseCase
    extends BaseUseCase<CartEntity, RemoveCartItemParams> {
  RemoveCartItemUseCase(this._repository);

  final BaseCartRepository _repository;

  @override
  Future<Either<Failure, CartEntity>> call(RemoveCartItemParams params) {
    return _repository.removeCartItem(
      token: params.token,
      cartItemId: params.cartItemId,
    );
  }
}

class RemoveCartItemParams extends Equatable {
  const RemoveCartItemParams({
    required this.token,
    required this.cartItemId,
  });

  final String token;
  final int cartItemId;

  @override
  List<Object?> get props => [token, cartItemId];
}
