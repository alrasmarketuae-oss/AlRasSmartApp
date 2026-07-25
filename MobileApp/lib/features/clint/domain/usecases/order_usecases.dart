import 'package:alrasmarket/core/error/failure.dart';
import 'package:alrasmarket/core/usecase/base_usecase.dart';
import 'package:alrasmarket/features/clint/data/models/create_order_request.dart';
import 'package:alrasmarket/features/clint/data/models/my_order_model.dart';
import 'package:alrasmarket/features/clint/data/models/my_orders_page_model.dart';
import 'package:alrasmarket/features/clint/domain/repository/base_order_repository.dart';
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

class UploadOrderImageUseCase
    extends BaseUseCase<String, UploadOrderFileParams> {
  UploadOrderImageUseCase(this._repository);

  final BaseOrderRepository _repository;

  @override
  Future<Either<Failure, String>> call(UploadOrderFileParams params) {
    return _repository.uploadOrderImage(
      productId: params.productId,
      filePath: params.filePath,
      token: params.token,
    );
  }
}

class UploadOrderVideoUseCase
    extends BaseUseCase<String, UploadOrderFileParams> {
  UploadOrderVideoUseCase(this._repository);

  final BaseOrderRepository _repository;

  @override
  Future<Either<Failure, String>> call(UploadOrderFileParams params) {
    return _repository.uploadOrderVideo(
      productId: params.productId,
      filePath: params.filePath,
      token: params.token,
    );
  }
}

class UploadOrderDocumentUseCase
    extends BaseUseCase<String, UploadOrderFileParams> {
  UploadOrderDocumentUseCase(this._repository);

  final BaseOrderRepository _repository;

  @override
  Future<Either<Failure, String>> call(UploadOrderFileParams params) {
    return _repository.uploadOrderDocument(
      productId: params.productId,
      filePath: params.filePath,
      token: params.token,
    );
  }
}

class CreateOrderUseCase extends BaseUseCase<String, CreateOrderParams> {
  CreateOrderUseCase(this._repository);

  final BaseOrderRepository _repository;

  @override
  Future<Either<Failure, String>> call(CreateOrderParams params) {
    return _repository.createOrder(
      request: params.request,
      token: params.token,
    );
  }
}

class UploadOrderFileParams extends Equatable {
  const UploadOrderFileParams({
    required this.productId,
    required this.filePath,
    required this.token,
  });

  final String productId;
  final String filePath;
  final String token;

  @override
  List<Object?> get props => [productId, filePath, token];
}

class GetMyOrdersUseCase
    extends BaseUseCase<MyOrdersPageModel, GetMyOrdersParams> {
  GetMyOrdersUseCase(this._repository);

  final BaseOrderRepository _repository;

  @override
  Future<Either<Failure, MyOrdersPageModel>> call(GetMyOrdersParams params) {
    return _repository.getMyOrders(
      page: params.page,
      pageSize: params.pageSize,
      token: params.token,
    );
  }
}

class GetMyOrdersParams extends Equatable {
  const GetMyOrdersParams({
    required this.page,
    required this.pageSize,
    required this.token,
  });

  final int page;
  final int pageSize;
  final String token;

  @override
  List<Object?> get props => [page, pageSize, token];
}

class GetMyOffersUseCase
    extends BaseUseCase<MyOrdersPageModel, GetMyOffersParams> {
  GetMyOffersUseCase(this._repository);

  final BaseOrderRepository _repository;

  @override
  Future<Either<Failure, MyOrdersPageModel>> call(GetMyOffersParams params) {
    return _repository.getMyOffers(
      page: params.page,
      pageSize: params.pageSize,
      token: params.token,
    );
  }
}

class GetMyOffersParams extends Equatable {
  const GetMyOffersParams({
    required this.page,
    required this.pageSize,
    required this.token,
  });

  final int page;
  final int pageSize;
  final String token;

  @override
  List<Object?> get props => [page, pageSize, token];
}

class GetOrderByIdUseCase extends BaseUseCase<MyOrderModel, GetOrderByIdParams> {
  GetOrderByIdUseCase(this._repository);

  final BaseOrderRepository _repository;

  @override
  Future<Either<Failure, MyOrderModel>> call(GetOrderByIdParams params) {
    return _repository.getOrderById(
      orderId: params.orderId,
      token: params.token,
    );
  }
}

class GetOrderByIdParams extends Equatable {
  const GetOrderByIdParams({
    required this.orderId,
    required this.token,
  });

  final int orderId;
  final String token;

  @override
  List<Object?> get props => [orderId, token];
}

class CreateOrderParams extends Equatable {
  const CreateOrderParams({
    required this.request,
    required this.token,
  });

  final CreateOrderRequest request;
  final String token;

  @override
  List<Object?> get props => [request, token];
}

class RequestOrderReturnUseCase
    extends BaseUseCase<MyOrderModel, RequestOrderReturnParams> {
  RequestOrderReturnUseCase(this._repository);

  final BaseOrderRepository _repository;

  @override
  Future<Either<Failure, MyOrderModel>> call(RequestOrderReturnParams params) {
    return _repository.requestOrderReturn(
      orderId: params.orderId,
      reason: params.reason,
      mediaPaths: params.mediaPaths,
      token: params.token,
    );
  }
}

class RequestOrderReturnParams extends Equatable {
  const RequestOrderReturnParams({
    required this.orderId,
    required this.reason,
    required this.mediaPaths,
    required this.token,
  });

  final int orderId;
  final String reason;
  final List<String> mediaPaths;
  final String token;

  @override
  List<Object?> get props => [orderId, reason, mediaPaths, token];
}
