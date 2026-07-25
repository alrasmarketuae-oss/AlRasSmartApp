import 'package:alrasmarket/core/error/failure.dart';
import 'package:alrasmarket/features/clint/data/datasource/order_remote_data_source.dart';
import 'package:alrasmarket/features/clint/data/models/create_order_request.dart';
import 'package:alrasmarket/features/clint/data/models/my_order_model.dart';
import 'package:alrasmarket/features/clint/data/models/my_orders_page_model.dart';
import 'package:alrasmarket/features/company/data/models/my_request_offers_page_model.dart';
import 'package:alrasmarket/features/clint/domain/repository/base_order_repository.dart';
import 'package:dartz/dartz.dart';

class OrderRepository implements BaseOrderRepository {
  OrderRepository({required BaseOrderRemoteDataSource remote}) : _remote = remote;

  final BaseOrderRemoteDataSource _remote;

  @override
  Future<Either<Failure, String>> uploadOrderImage({
    required String productId,
    required String filePath,
    required String token,
  }) {
    return _remote.uploadOrderImage(
      productId: productId,
      filePath: filePath,
      token: token,
    );
  }

  @override
  Future<Either<Failure, String>> uploadOrderVideo({
    required String productId,
    required String filePath,
    required String token,
  }) {
    return _remote.uploadOrderVideo(
      productId: productId,
      filePath: filePath,
      token: token,
    );
  }

  @override
  Future<Either<Failure, String>> uploadOrderDocument({
    required String productId,
    required String filePath,
    required String token,
  }) {
    return _remote.uploadOrderDocument(
      productId: productId,
      filePath: filePath,
      token: token,
    );
  }

  @override
  Future<Either<Failure, String>> createOrder({
    required CreateOrderRequest request,
    required String token,
  }) {
    return _remote.createOrder(request: request, token: token);
  }

  @override
  Future<Either<Failure, MyOrdersPageModel>> getMyOrders({
    required int page,
    required int pageSize,
    required String token,
    bool forceRefresh = true,
  }) {
    return _remote.getMyOrders(
      page: page,
      pageSize: pageSize,
      token: token,
      forceRefresh: forceRefresh,
    );
  }

  @override
  Future<Either<Failure, MyOrdersPageModel>> getMyOffers({
    required int page,
    required int pageSize,
    required String token,
  }) {
    return _remote.getMyOffers(
      page: page,
      pageSize: pageSize,
      token: token,
    );
  }

  @override
  Future<Either<Failure, MyOrderModel>> getOrderById({
    required int orderId,
    required String token,
  }) {
    return _remote.getOrderById(orderId: orderId, token: token);
  }

  @override
  Future<Either<Failure, MyRequestOffersPageModel>> getMyOffersOnMyRequests({
    required int page,
    required int pageSize,
    required String token,
    String? productId,
    int? statusId,
  }) {
    return _remote.getMyOffersOnMyRequests(
      page: page,
      pageSize: pageSize,
      token: token,
      productId: productId,
      statusId: statusId,
    );
  }

  @override
  Future<Either<Failure, String?>> updateOrderStatus({
    required int orderId,
    required int statusId,
    required String token,
  }) {
    return _remote.updateOrderStatus(
      orderId: orderId,
      statusId: statusId,
      token: token,
    );
  }

  @override
  Future<Either<Failure, MyOrderModel>> requestOrderReturn({
    required int orderId,
    required String reason,
    required List<String> mediaPaths,
    required String token,
  }) {
    return _remote.requestOrderReturn(
      orderId: orderId,
      reason: reason,
      mediaPaths: mediaPaths,
      token: token,
    );
  }
}
