import 'package:alrasmarket/core/error/failure.dart';
import 'package:alrasmarket/core/services/api_constants.dart';
import 'package:alrasmarket/core/services/dio_helper.dart';
import 'package:alrasmarket/features/clint/data/models/add_cart_item_request.dart';
import 'package:alrasmarket/features/clint/data/models/cart_response_model.dart';
import 'package:alrasmarket/features/clint/data/models/cart_order_result_model.dart';
import 'package:alrasmarket/features/clint/data/models/confirm_cart_order_request.dart';
import 'package:alrasmarket/features/clint/data/models/reduce_cart_item_request.dart';
import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';

abstract class BaseCartRemoteDataSource {
  Future<Either<Failure, CartResponseModel>> fetchCart({required String token});

  Future<Either<Failure, CartResponseModel>> addCartItem({
    required String token,
    required AddCartItemRequest request,
  });

  Future<Either<Failure, CartOrderResultModel>> confirmCartOrder({
    required String token,
    required ConfirmCartOrderRequest request,
  });

  Future<Either<Failure, CartResponseModel>> removeCartItem({
    required String token,
    required int cartItemId,
  });

  Future<Either<Failure, CartResponseModel>> reduceCartItemQuantity({
    required String token,
    required int cartItemId,
    required ReduceCartItemRequest request,
  });
}

class CartRemoteDataSource implements BaseCartRemoteDataSource {
  @override
  Future<Either<Failure, CartResponseModel>> fetchCart({
    required String token,
  }) async {
    try {
      final response = await DioHelper.getData(
        url: ApiConstants.cartMeEndPoint,
        token: token,
      );

      final status = response?.statusCode ?? 0;
      if (status < 200 || status >= 300) {
        return Left(
          ServerFailure(
            _extractMessage(response?.data) ??
                response?.statusMessage ??
                'Failed to load cart ($status)',
          ),
        );
      }

      final data = response?.data;
      if (data is! Map<String, dynamic>) {
        return const Left(ServerFailure('Invalid cart response'));
      }

      return Right(CartResponseModel.fromJson(data));
    } on DioException catch (e) {
      return Left(
        ServerFailure(
          _extractMessage(e.response?.data) ?? e.message ?? 'Network error',
        ),
      );
    } catch (e) {
      return Left(NetworkFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, CartResponseModel>> addCartItem({
    required String token,
    required AddCartItemRequest request,
  }) async {
    try {
      print("request: ${request.toJson()}");
      final response = await DioHelper.postData(
        url: ApiConstants.cartItemsEndPoint,
        data: request.toJson(),
        token: token,
      );

      final status = response?.statusCode ?? 0;
      if (status < 200 || status >= 300) {
        print("response?.data: ${response?.data}");
        return Left(
          ServerFailure(
            _extractMessage(response?.data) ??
                response?.statusMessage ??
                'Failed to add item to cart ($status)',
          ),
        );
      }

      return fetchCart(token: token);
    } on DioException catch (e) {
      print("e: ${e.response?.data}");
      return Left(
        ServerFailure(
          _extractMessage(e.response?.data) ?? e.message ?? 'Network error',
        ),
      );
    } catch (e) {
      print("e: ${e.toString()}");
      return Left(NetworkFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, CartResponseModel>> removeCartItem({
    required String token,
    required int cartItemId,
  }) async {
    try {
      final response = await DioHelper.deleteData(
        url: ApiConstants.cartItemByIdEndPoint(cartItemId.toString()),
        token: token,
      );

      final status = response?.statusCode ?? 0;
      if (status < 200 || status >= 300) {
        return Left(
          ServerFailure(
            _extractMessage(response?.data) ??
                response?.statusMessage ??
                'Failed to remove cart item ($status)',
          ),
        );
      }

      return fetchCart(token: token);
    } on DioException catch (e) {
      return Left(
        ServerFailure(
          _extractMessage(e.response?.data) ?? e.message ?? 'Network error',
        ),
      );
    } catch (e) {
      return Left(NetworkFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, CartResponseModel>> reduceCartItemQuantity({
    required String token,
    required int cartItemId,
    required ReduceCartItemRequest request,
  }) async {
    try {
      final response = await DioHelper.patchData(
        url: ApiConstants.cartItemByIdEndPoint(cartItemId.toString()),
        data: request.toJson(),
        token: token,
      );

      final status = response?.statusCode ?? 0;
      if (status < 200 || status >= 300) {
        return Left(
          ServerFailure(
            _extractMessage(response?.data) ??
                response?.statusMessage ??
                'Failed to reduce cart item quantity ($status)',
          ),
        );
      }

      return fetchCart(token: token);
    } on DioException catch (e) {
      return Left(
        ServerFailure(
          _extractMessage(e.response?.data) ?? e.message ?? 'Network error',
        ),
      );
    } catch (e) {
      return Left(NetworkFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, CartOrderResultModel>> confirmCartOrder({
    required String token,
    required ConfirmCartOrderRequest request,
  }) async {
    try {
      final response = await DioHelper.postData(
        url: ApiConstants.ordersEndPoint,
        data: request.toJson(),
        token: token,
      );

      final status = response?.statusCode ?? 0;
      if (status < 200 || status >= 300) {
        return Left(
          ServerFailure(
            _extractMessage(response?.data) ??
                response?.statusMessage ??
                'Failed to confirm order ($status)',
          ),
        );
      }

      final data = response?.data;
      if (data is Map<String, dynamic>) {
        return Right(CartOrderResultModel.fromJson(data));
      }

      return const Left(ServerFailure('Invalid order response'));
    } on DioException catch (e) {
      return Left(
        ServerFailure(
          _extractMessage(e.response?.data) ?? e.message ?? 'Network error',
        ),
      );
    } catch (e) {
      return Left(NetworkFailure(e.toString()));
    }
  }

  String? _extractMessage(dynamic data) {
    if (data is Map) {
      return data['message']?.toString() ?? data['title']?.toString();
    }
    if (data is String) return data;
    return null;
  }
}
