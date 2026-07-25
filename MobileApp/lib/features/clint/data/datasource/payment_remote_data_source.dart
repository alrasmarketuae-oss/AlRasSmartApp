import 'package:alrasmarket/core/error/failure.dart';
import 'package:alrasmarket/core/services/api_constants.dart';
import 'package:alrasmarket/core/services/dio_helper.dart';
import 'package:alrasmarket/features/clint/data/models/stripe_checkout_model.dart';
import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';

abstract class BasePaymentRemoteDataSource {
  Future<Either<Failure, StripeCheckoutModel>> createStripeCheckout({
    required String token,
    required String pendingOrderId,
  });

  Future<Either<Failure, CheckoutStatusModel>> getCheckoutStatus({
    required String token,
    required String sessionId,
  });
}

class PaymentRemoteDataSource implements BasePaymentRemoteDataSource {
  @override
  Future<Either<Failure, StripeCheckoutModel>> createStripeCheckout({
    required String token,
    required String pendingOrderId,
  }) async {
    try {
      final response = await DioHelper.postData(
        url: ApiConstants.createStripeCheckoutEndPoint,
        token: token,
        data: {'orderId': pendingOrderId, 'client': 'mobile'},
      );

      final status = response?.statusCode ?? 0;
      if (status < 200 || status >= 300) {
        return Left(
          ServerFailure(
            _extractMessage(response?.data) ??
                'Failed to create checkout ($status)',
          ),
        );
      }

      final data = response?.data;
      if (data is! Map<String, dynamic>) {
        return const Left(ServerFailure('Invalid checkout response'));
      }

      final model = StripeCheckoutModel.fromJson(data);
      if (model.checkoutUrl.isEmpty) {
        return const Left(ServerFailure('Checkout URL not available'));
      }

      return Right(model);
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
  Future<Either<Failure, CheckoutStatusModel>> getCheckoutStatus({
    required String token,
    required String sessionId,
  }) async {
    try {
      final response = await DioHelper.getData(
        url: ApiConstants.checkoutStatusEndPoint,
        query: {'sessionId': sessionId},
        token: token,
      );

      final status = response?.statusCode ?? 0;
      if (status < 200 || status >= 300) {
        return Left(
          ServerFailure(
            _extractMessage(response?.data) ??
                'Failed to check payment status ($status)',
          ),
        );
      }

      final data = response?.data;
      if (data is! Map<String, dynamic>) {
        return const Left(ServerFailure('Invalid status response'));
      }

      return Right(CheckoutStatusModel.fromJson(data));
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
