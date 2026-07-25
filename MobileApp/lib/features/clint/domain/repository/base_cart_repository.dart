import 'package:alrasmarket/core/error/failure.dart';
import 'package:alrasmarket/features/clint/data/models/cart_order_result_model.dart';
import 'package:alrasmarket/features/clint/domain/entities/cart_entity.dart';
import 'package:alrasmarket/features/clint/domain/entities/cart_payment_method.dart';
import 'package:dartz/dartz.dart';

abstract class BaseCartRepository {
  Future<Either<Failure, CartEntity>> getCart({required String token});

  Future<Either<Failure, CartEntity>> addCartItem({
    required String token,
    required String productId,
    required double quantity,
    required String unitName,
  });

  Future<Either<Failure, CartOrderResultModel>> confirmCartOrder({
    required String token,
    required CartPaymentMethod paymentMethod,
    required double shippingCostAed,
    bool isSelfPickup = false,
    String? addressId,
    String? cityName,
    String? addressLine,
  });

  Future<Either<Failure, CartEntity>> removeCartItem({
    required String token,
    required int cartItemId,
  });

  Future<Either<Failure, CartEntity>> reduceCartItemQuantity({
    required String token,
    required int cartItemId,
    required double quantity,
  });
}
