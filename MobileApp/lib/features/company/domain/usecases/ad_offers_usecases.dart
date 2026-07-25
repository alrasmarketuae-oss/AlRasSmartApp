import 'package:alrasmarket/core/error/failure.dart';
import 'package:alrasmarket/features/clint/domain/repository/base_order_repository.dart';
import 'package:alrasmarket/features/company/data/models/my_request_offers_page_model.dart';
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

class GetMyOffersOnMyRequestsUseCase {
  GetMyOffersOnMyRequestsUseCase(this._repository);

  final BaseOrderRepository _repository;

  Future<Either<Failure, MyRequestOffersPageModel>> call(
    GetMyOffersOnMyRequestsParams params,
  ) {
    return _repository.getMyOffersOnMyRequests(
      page: params.page,
      pageSize: params.pageSize,
      token: params.token,
      productId: params.productId,
      statusId: params.statusId,
    );
  }
}

class UpdateOrderStatusUseCase {
  UpdateOrderStatusUseCase(this._repository);

  final BaseOrderRepository _repository;

  Future<Either<Failure, String?>> call(UpdateOrderStatusParams params) {
    return _repository.updateOrderStatus(
      orderId: params.orderId,
      statusId: params.statusId,
      token: params.token,
    );
  }
}

class GetMyOffersOnMyRequestsParams extends Equatable {
  const GetMyOffersOnMyRequestsParams({
    required this.page,
    required this.pageSize,
    required this.token,
    this.productId,
    this.statusId,
  });

  final int page;
  final int pageSize;
  final String token;
  final String? productId;
  final int? statusId;

  @override
  List<Object?> get props => [page, pageSize, token, productId, statusId];
}

class UpdateOrderStatusParams extends Equatable {
  const UpdateOrderStatusParams({
    required this.orderId,
    required this.statusId,
    required this.token,
  });

  final int orderId;
  final int statusId;
  final String token;

  @override
  List<Object?> get props => [orderId, statusId, token];
}
