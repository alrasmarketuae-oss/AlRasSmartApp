import 'package:alrasmarket/core/error/failure.dart';
import 'package:alrasmarket/core/usecase/base_usecase.dart';
import 'package:alrasmarket/features/clint/domain/entities/cart_entity.dart';
import 'package:alrasmarket/features/clint/domain/repository/base_cart_repository.dart';
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

class AddCartItemUseCase extends BaseUseCase<CartEntity, AddCartItemParams> {
  AddCartItemUseCase(this._repository);

  final BaseCartRepository _repository;

  @override
  Future<Either<Failure, CartEntity>> call(AddCartItemParams params) {
    return _repository.addCartItem(
      token: params.token,
      productId: params.productId,
      quantity: params.quantity,
      unitName: params.unitName,
    );
  }
}

class AddCartItemParams extends Equatable {
  const AddCartItemParams({
    required this.token,
    required this.productId,
    required this.quantity,
    required this.unitName,
  });

  final String token;
  final String productId;
  final double quantity;
  final String unitName;

  @override
  List<Object?> get props => [token, productId, quantity, unitName];
}
