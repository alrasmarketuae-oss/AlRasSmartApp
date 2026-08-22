import 'dart:async';
import 'dart:io';

import 'package:alrasmarket/core/cache/api_cache_keys.dart';
import 'package:alrasmarket/core/cache/api_cache_store.dart';
import 'package:alrasmarket/core/error/failure.dart';
import 'package:alrasmarket/core/services/api_constants.dart';
import 'package:alrasmarket/core/services/dio_helper.dart';
import 'package:alrasmarket/core/serveses/catalog_sync_service.dart';
import 'package:alrasmarket/core/serveses/auth_service.dart';
import 'package:alrasmarket/features/clint/data/models/create_order_request.dart';
import 'package:alrasmarket/features/clint/data/models/my_order_model.dart';
import 'package:alrasmarket/features/clint/data/models/my_orders_page_model.dart';
import 'package:alrasmarket/features/company/data/models/my_request_offers_page_model.dart';
import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';

abstract class BaseOrderRemoteDataSource {
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

class OrderRemoteDataSource implements BaseOrderRemoteDataSource {
  @override
  Future<Either<Failure, String>> uploadOrderImage({
    required String productId,
    required String filePath,
    required String token,
  }) async {
    return _uploadFile(
      endPoint: ApiConstants.offerStagingImageUploadEndPoint,
      filePath: filePath,
      token: token,
    );
  }

  @override
  Future<Either<Failure, String>> uploadOrderVideo({
    required String productId,
    required String filePath,
    required String token,
  }) async {
    return _uploadFile(
      endPoint: ApiConstants.offerStagingVideoUploadEndPoint,
      filePath: filePath,
      token: token,
    );
  }

  @override
  Future<Either<Failure, String>> uploadOrderDocument({
    required String productId,
    required String filePath,
    required String token,
  }) async {
    return _uploadFile(
      endPoint: ApiConstants.offerStagingDocumentUploadEndPoint,
      filePath: filePath,
      token: token,
    );
  }

  @override
  Future<Either<Failure, String>> createOrder({
    required CreateOrderRequest request,
    required String token,
  }) async {
    try {
      print('🔵 [Create Order] Request: ${request.toJson()}');
      final response = await DioHelper.postData(
        url: ApiConstants.ordersEndPoint,
        data: request.toJson(),
        token: token,
      );
      print('🔵 [Create Order] Response: $response');
      final status = response?.statusCode ?? 0;
      print('🔵 [Create Order] Status: $status');
      if (status < 200 || status >= 300) {
        print('🔵 [Create Order] Failed to create order ($status)');
        return Left(
          ServerFailure(
            _extractMessage(response?.data) ??
                response?.statusMessage ??
                'Failed to create order ($status)',
          ),
        );
      }

      final data = response?.data;
      final orderId = data is Map<String, dynamic>
          ? _extractCreatedOrderId(data)
          : null;

      // Order is already persisted — never fail the buyer because cache refresh broke.
      await _invalidateOrderCachesAfterMutation();
      if (orderId != null && orderId.isNotEmpty) {
        return Right(orderId);
      }

      // 2xx without a parseable id — still treat as success so UI does not false-fail.
      return const Right('');
    } on DioException catch (e) {
      print('🔵 [Create Order] DioException: ${e.response?.data}');
      print('🔵 [Create Order] DioException: ${e.response?.statusCode}');
      print('🔵 [Create Order] DioException: ${e.response?.statusMessage}');
      return Left(
        ServerFailure(
          _extractMessage(e.response?.data) ?? e.message ?? 'Network error',
        ),
      );
    } catch (e) {
      print('🔵 [Create Order] Error: $e');
      return Left(NetworkFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, MyOrdersPageModel>> getMyOrders({
    required int page,
    required int pageSize,
    required String token,
    bool forceRefresh = true,
  }) async {
    final userId = _userIdFromToken(token);
    final cacheKey = ApiCacheKeys.userOrders(userId, page, pageSize);

    // Always prefer live status from the API. Cache is only an offline fallback.
    if (forceRefresh) {
      await ApiCacheStore.instance.invalidateUserOrders();
    } else if (page == 1) {
      final cached = await ApiCacheStore.instance.read(cacheKey);
      if (cached != null) {
        try {
          final parsed = MyOrdersPageModel.fromJson(
            Map<String, dynamic>.from(cached.data as Map),
          );
          if (!cached.isFresh) {
            unawaited(_getMyOrdersNetwork(
              page: page,
              pageSize: pageSize,
              token: token,
              cacheKey: cacheKey,
              background: true,
            ));
          }
          return Right(parsed);
        } catch (_) {
          await ApiCacheStore.instance.remove(cacheKey);
        }
      }
    }

    return _getMyOrdersNetwork(
      page: page,
      pageSize: pageSize,
      token: token,
      cacheKey: cacheKey,
      background: false,
    );
  }

  Future<Either<Failure, MyOrdersPageModel>> _getMyOrdersNetwork({
    required int page,
    required int pageSize,
    required String token,
    required String cacheKey,
    required bool background,
  }) async {
    try {
      final response = await DioHelper.getData(
        url: ApiConstants.myOrdersEndPoint,
        query: {'page': page, 'pageSize': pageSize},
        token: token,
      );

      final status = response?.statusCode ?? 0;
      if (status < 200 || status >= 300) {
        return _ordersFallbackOrLeft(
          cacheKey,
          ServerFailure(
            _extractMessage(response?.data) ??
                response?.statusMessage ??
                'Failed to load orders ($status)',
          ),
        );
      }

      final data = response?.data;
      if (data is! Map<String, dynamic>) {
        return _ordersFallbackOrLeft(
          cacheKey,
          const ServerFailure('Invalid orders response'),
        );
      }

      if (page == 1) {
        await ApiCacheStore.instance.write(
          cacheKey,
          data,
          ApiCacheTtl.orders,
        );
      }

      if (background) {
        return const Right(MyOrdersPageModel(
          page: 1,
          pageSize: 20,
          totalCount: 0,
          totalPages: 0,
          items: [],
        ));
      }
      return Right(MyOrdersPageModel.fromJson(data));
    } on DioException catch (e) {
      return _ordersFallbackOrLeft(
        cacheKey,
        ServerFailure(
          _extractMessage(e.response?.data) ?? e.message ?? 'Network error',
        ),
      );
    } catch (e) {
      return _ordersFallbackOrLeft(cacheKey, NetworkFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, MyOrdersPageModel>> getMyOffers({
    required int page,
    required int pageSize,
    required String token,
  }) async {
    try {
      final response = await DioHelper.getData(
        url: ApiConstants.myOffersEndPoint,
        query: {'page': page, 'pageSize': pageSize},
        token: token,
      );

      final status = response?.statusCode ?? 0;
      if (status < 200 || status >= 300) {
        return Left(
          ServerFailure(
            _extractMessage(response?.data) ??
                response?.statusMessage ??
                'Failed to load offers ($status)',
          ),
        );
      }

      final data = response?.data;
      if (data is! Map<String, dynamic>) {
        return const Left(ServerFailure('Invalid offers response'));
      }

      return Right(MyOrdersPageModel.fromJson(data));
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

  Future<Either<Failure, MyOrdersPageModel>> _ordersFallbackOrLeft(
    String cacheKey,
    Failure failure,
  ) async {
    final stale = await ApiCacheStore.instance.read(cacheKey, allowStale: true);
    if (stale != null) {
      try {
        return Right(
          MyOrdersPageModel.fromJson(
            Map<String, dynamic>.from(stale.data as Map),
          ),
        );
      } catch (_) {}
    }
    return Left(failure);
  }

  String _userIdFromToken(String token) {
    final id = AuthService.instance.currentUserID;
    if (id != null && id.isNotEmpty) return id;
    return token.hashCode.toRadixString(16);
  }

  @override
  Future<Either<Failure, MyRequestOffersPageModel>> getMyOffersOnMyRequests({
    required int page,
    required int pageSize,
    required String token,
    String? productId,
    int? statusId,
  }) async {
    try {
      final query = <String, dynamic>{
        'page': page,
        'pageSize': pageSize,
      };
      if (productId != null && productId.isNotEmpty) {
        query['productId'] = productId;
      }
      if (statusId != null) {
        query['statusId'] = statusId;
      }

      final response = await DioHelper.getData(
        url: ApiConstants.getMyOffersOnMyRequestsEndPoint,
        query: query,
        token: token,
      );

      final status = response?.statusCode ?? 0;
      if (status < 200 || status >= 300) {
        return Left(
          ServerFailure(
            _extractMessage(response?.data) ??
                response?.statusMessage ??
                'Failed to load request offers ($status)',
          ),
        );
      }

      final data = response?.data;
      if (data is! Map<String, dynamic>) {
        return const Left(ServerFailure('Invalid request offers response'));
      }

      return Right(MyRequestOffersPageModel.fromJson(data));
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
  Future<Either<Failure, MyOrderModel>> getOrderById({
    required int orderId,
    required String token,
  }) async {
    try {
      final response = await DioHelper.getData(
        url: ApiConstants.orderByIdEndPoint(orderId),
        token: token,
      );

      final status = response?.statusCode ?? 0;
      if (status < 200 || status >= 300) {
        return Left(
          ServerFailure(
            _extractMessage(response?.data) ??
                response?.statusMessage ??
                'Failed to load order ($status)',
          ),
        );
      }

      final data = response?.data;
      if (data is! Map<String, dynamic>) {
        return const Left(ServerFailure('Invalid order response'));
      }

      // Status may have changed on the server — drop list cache.
      await ApiCacheStore.instance.invalidateUserOrders();
      return Right(MyOrderModel.fromJson(data));
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
  Future<Either<Failure, String?>> updateOrderStatus({
    required int orderId,
    required int statusId,
    required String token,
  }) async {
    try {
      final response = await DioHelper.patchData(
        url: ApiConstants.orderStatusEndPoint(orderId),
        data: {'statusId': statusId},
        token: token,
      );

      final status = response?.statusCode ?? 0;
      if (status < 200 || status >= 300) {
        return Left(
          ServerFailure(
            _extractMessage(response?.data) ??
                response?.statusMessage ??
                'Failed to update order status ($status)',
          ),
        );
      }

      await ApiCacheStore.instance.invalidateUserOrders();
      unawaited(CatalogSyncService.instance.afterAdMutation());

      final data = response?.data;
      if (data is Map<String, dynamic>) {
        final refundMessage = data['refundMessage']?.toString() ??
            data['refundMessageAr']?.toString();
        return Right(refundMessage);
      }

      return const Right(null);
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
  Future<Either<Failure, MyOrderModel>> requestOrderReturn({
    required int orderId,
    required String reason,
    required List<String> mediaPaths,
    required String token,
  }) async {
    try {
      final formData = FormData();
      formData.fields.add(MapEntry('reason', reason));
      for (final path in mediaPaths) {
        formData.files.add(
          MapEntry(
            'mediaFiles',
            await MultipartFile.fromFile(
              path,
              filename: path.split(Platform.pathSeparator).last,
            ),
          ),
        );
      }

      final response = await DioHelper.uploadFile(
        url: ApiConstants.orderReturnEndPoint(orderId),
        formData: formData,
        token: token,
      );

      final status = response?.statusCode ?? 0;
      if (status < 200 || status >= 300) {
        return Left(
          ServerFailure(
            _extractMessage(response?.data) ??
                response?.statusMessage ??
                'Failed to submit return request ($status)',
          ),
        );
      }

      final data = response?.data;
      if (data is! Map<String, dynamic>) {
        return const Left(ServerFailure('Invalid return response'));
      }

      await ApiCacheStore.instance.invalidateUserOrders();
      return Right(MyOrderModel.fromJson(data));
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

  Future<Either<Failure, String>> _uploadFile({
    required String endPoint,
    required String filePath,
    required String token,
  }) async {
    try {
      print('🔵 [Upload Photo] File Path: $filePath');
      final file = File(filePath);
      if (!await file.exists()) {
        return const Left(ServerFailure('File not found'));
      }

      final formData = FormData.fromMap({
        'File': await MultipartFile.fromFile(
          file.path,
          filename: file.path.split('/').last,
        ),
      });
      print('🔵 [Upload Photo] Form Data:');
      final response = await DioHelper.uploadFile(
        url: endPoint,
        formData: formData,
        token: token,
      );
      print('🔵 [Upload Photo] Response: $response');
      final status = response?.statusCode ?? 0;
      if (status < 200 || status >= 300) {
        return Left(
          ServerFailure(
            _extractMessage(response?.data) ??
                response?.statusMessage ??
                'Upload failed ($status)',
          ),
        );
      }

      final path = _extractUploadedPath(response?.data);
      if (path == null || path.isEmpty) {
        return const Left(ServerFailure('Invalid upload response'));
      }
      print('🔵 [Upload Photo] Path: $path');
      return Right(path);
    } on DioException catch (e) {
      return Left(
        ServerFailure(
          _extractMessage(e.response?.data) ?? e.message ?? 'Upload failed',
        ),
      );
    } catch (e) {
      return Left(NetworkFailure(e.toString()));
    }
  }

  String? _extractCreatedOrderId(Map<String, dynamic> data) {
    final nestedOrder = data['order'];
    final nestedMap = nestedOrder is Map
        ? Map<String, dynamic>.from(nestedOrder)
        : null;
    return data['orderId']?.toString() ??
        data['id']?.toString() ??
        data['orderNumber']?.toString() ??
        nestedMap?['id']?.toString() ??
        nestedMap?['orderId']?.toString() ??
        nestedMap?['Id']?.toString();
  }

  Future<void> _invalidateOrderCachesAfterMutation() async {
    try {
      await ApiCacheStore.instance.invalidateUserOrders();
    } catch (e) {
      print('🔵 [Create Order] Order cache invalidation skipped: $e');
    }
    unawaited(CatalogSyncService.instance.afterAdMutation());
  }

  String? _extractMessage(dynamic data) {
    if (data is Map) {
      final errors = data['errors'];
      if (errors is Map) {
        final messages = <String>[];
        for (final entry in errors.entries) {
          final value = entry.value;
          if (value is List) {
            messages.addAll(value.map((e) => e.toString()));
          } else if (value != null) {
            messages.add(value.toString());
          }
        }
        if (messages.isNotEmpty) return messages.join('\n');
      }

      return data['message']?.toString() ??
          data['title']?.toString() ??
          data['detail']?.toString();
    }
    if (data is String) return data;
    return null;
  }

  String? _extractUploadedPath(dynamic data) {
    if (data is Map) {
      return data['path']?.toString() ??
          data['Path']?.toString() ??
          data['url']?.toString() ??
          data['imageUrl']?.toString() ??
          data['imagePath']?.toString() ??
          data['ImagePath']?.toString() ??
          data['videoPath']?.toString() ??
          data['VideoPath']?.toString();
    }
    if (data is String) return data;
    return null;
  }
}
