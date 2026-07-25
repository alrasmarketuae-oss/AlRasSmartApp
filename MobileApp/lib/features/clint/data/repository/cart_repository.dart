import 'package:alrasmarket/core/error/failure.dart';
import 'package:alrasmarket/features/clint/data/datasource/cart_remote_data_source.dart';
import 'package:alrasmarket/features/clint/data/models/add_cart_item_request.dart';
import 'package:alrasmarket/features/clint/data/models/cart_order_result_model.dart';
import 'package:alrasmarket/features/clint/data/models/confirm_cart_order_request.dart';
import 'package:alrasmarket/features/clint/data/models/reduce_cart_item_request.dart';
import 'package:alrasmarket/features/clint/domain/entities/cart_entity.dart';
import 'package:alrasmarket/features/clint/domain/entities/cart_payment_method.dart';
import 'package:alrasmarket/features/clint/domain/repository/base_cart_repository.dart';
import 'package:dartz/dartz.dart';

class CartRepository implements BaseCartRepository {
  CartRepository({required BaseCartRemoteDataSource remote}) : _remote = remote;

  final BaseCartRemoteDataSource _remote;

  @override
  Future<Either<Failure, CartEntity>> getCart({required String token}) async {
    final result = await _remote.fetchCart(token: token);
    return result.fold(Left.new, (model) => Right(model.toEntity()));
  }

  @override
  Future<Either<Failure, CartEntity>> addCartItem({
    required String token,
    required String productId,
    required double quantity,
    required String unitName,
  }) async {
    final result = await _remote.addCartItem(
      token: token,
      request: AddCartItemRequest(
        productId: productId,
        quantity: quantity,
        unitName: unitName,
      ),
    );
    return result.fold(Left.new, (model) => Right(model.toEntity()));
  }

  @override
  Future<Either<Failure, CartEntity>> removeCartItem({
    required String token,
    required int cartItemId,
  }) async {
    final result = await _remote.removeCartItem(
      token: token,
      cartItemId: cartItemId,
    );
    return result.fold(Left.new, (model) => Right(model.toEntity()));
  }

  @override
  Future<Either<Failure, CartEntity>> reduceCartItemQuantity({
    required String token,
    required int cartItemId,
    required double quantity,
  }) async {
    final result = await _remote.reduceCartItemQuantity(
      token: token,
      cartItemId: cartItemId,
      request: ReduceCartItemRequest(quantity: quantity),
    );
    return result.fold(Left.new, (model) => Right(model.toEntity()));
  }

  @override
  Future<Either<Failure, CartOrderResultModel>> confirmCartOrder({
    required String token,
    required CartPaymentMethod paymentMethod,
    required double shippingCostAed,
    bool isSelfPickup = false,
    String? addressId,
    String? cityName,
    String? addressLine,
  }) async {
    return _remote.confirmCartOrder(
      token: token,
      request: ConfirmCartOrderRequest(
        paymentMethodName: paymentMethod.apiValue,
        shippingCostAed: shippingCostAed,
        isSelfPickup: isSelfPickup,
        addressId: addressId,
        cityName: cityName,
        addressLine: addressLine,
      ),
    );
  }
}
