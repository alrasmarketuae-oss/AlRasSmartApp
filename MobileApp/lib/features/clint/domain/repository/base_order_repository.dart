import 'package:alrasmarket/core/error/failure.dart';
import 'package:alrasmarket/features/clint/data/models/create_order_request.dart';
import 'package:alrasmarket/features/clint/data/models/my_order_model.dart';
import 'package:alrasmarket/features/clint/data/models/my_orders_page_model.dart';
import 'package:alrasmarket/features/company/data/models/my_request_offers_page_model.dart';
import 'package:dartz/dartz.dart';

abstract class BaseOrderRepository {
  Future<Either<Failure, String>> uploadOrderImage({
    required String productId,
    required String filePath,
    required String token,
  });

  Future<Either<Failure, String>> uploadOrderVideo({
    required String productId,
    required String filePath,
    required String token,
  });

  Future<Either<Failure, String>> uploadOrderDocument({
    required String productId,
    required String filePath,
    required String token,
  });

  Future<Either<Failure, String>> createOrder({
    required CreateOrderRequest request,
    required String token,
  });

  Future<Either<Failure, MyOrdersPageModel>> getMyOrders({
    required int page,
    required int pageSize,
    required String token,
    bool forceRefresh = true,
  });

  Future<Either<Failure, MyOrdersPageModel>> getMyOffers({
    required int page,
    required int pageSize,
    required String token,
  });

  Future<Either<Failure, MyOrderModel>> getOrderById({
    required int orderId,
    required String token,
  });

  Future<Either<Failure, MyRequestOffersPageModel>> getMyOffersOnMyRequests({
    required int page,
    required int pageSize,
    required String token,
    String? productId,
    int? statusId,
  });

  Future<Either<Failure, String?>> updateOrderStatus({
    required int orderId,
    required int statusId,
    required String token,
  });

  Future<Either<Failure, MyOrderModel>> requestOrderReturn({
    required int orderId,
    required String reason,
    required List<String> mediaPaths,
    required String token,
  });
}
