import 'package:alrasmarket/core/error/failure.dart';
import 'package:alrasmarket/core/usecase/base_usecase.dart';
import 'package:alrasmarket/features/clint/domain/entities/cart_entity.dart';
import 'package:alrasmarket/features/clint/domain/repository/base_cart_repository.dart';
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

class GetCartUseCase extends BaseUseCase<CartEntity, GetCartParams> {
  GetCartUseCase(this._repository);

  final BaseCartRepository _repository;

  @override
  Future<Either<Failure, CartEntity>> call(GetCartParams params) {
    return _repository.getCart(token: params.token);
  }
}

class GetCartParams extends Equatable {
  const GetCartParams({required this.token});

  final String token;

  @override
  List<Object?> get props => [token];
}
