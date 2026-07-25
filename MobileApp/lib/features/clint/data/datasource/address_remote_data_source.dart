import 'dart:async';

import 'package:alrasmarket/core/cache/api_cache_keys.dart';
import 'package:alrasmarket/core/cache/api_cache_store.dart';
import 'package:alrasmarket/core/error/failure.dart';
import 'package:alrasmarket/core/services/api_constants.dart';
import 'package:alrasmarket/core/services/dio_helper.dart';
import 'package:alrasmarket/core/serveses/auth_service.dart';
import 'package:alrasmarket/features/clint/data/models/client_address_model.dart';
import 'package:dartz/dartz.dart';

abstract class BaseAddressRemoteDataSource {
  Future<Either<Failure, ClientAddressesResponse>> fetchAddresses({
    required String token,
    bool forceRefresh = false,
  });

  Future<Either<Failure, void>> createAddress({
    required CreateAddressRequest request,
    required String token,
  });
}

class AddressRemoteDataSource implements BaseAddressRemoteDataSource {
  @override
  Future<Either<Failure, ClientAddressesResponse>> fetchAddresses({
    required String token,
    bool forceRefresh = false,
  }) async {
    final userId = AuthService.instance.currentUserID ?? 'anonymous';
    final cacheKey = ApiCacheKeys.userAddresses(userId);

    if (forceRefresh) {
      await ApiCacheStore.instance.remove(cacheKey);
    } else {
      final cached = await ApiCacheStore.instance.read(cacheKey);
      if (cached != null) {
        try {
          final parsed = ClientAddressesResponse.fromJson(
            Map<String, dynamic>.from(cached.data as Map),
          );
          if (!cached.isFresh) {
            unawaited(_fetchAddressesNetwork(token, cacheKey, background: true));
          }
          return Right(parsed);
        } catch (_) {
          await ApiCacheStore.instance.remove(cacheKey);
        }
      }
    }

    return _fetchAddressesNetwork(token, cacheKey, background: false);
  }

  Future<Either<Failure, ClientAddressesResponse>> _fetchAddressesNetwork(
    String token,
    String cacheKey, {
    required bool background,
  }) async {
    try {
      final response = await DioHelper.getData(
        url: ApiConstants.addressesEndPoint,
        token: token,
      );
      final status = response?.statusCode ?? 0;
      if (status < 200 || status >= 300) {
        return _fallbackOrLeft(
          cacheKey,
          ServerFailure(response?.statusMessage ?? 'Request failed ($status)'),
        );
      }

      final data = response?.data;
      if (data is! Map<String, dynamic>) {
        return _fallbackOrLeft(
          cacheKey,
          const ServerFailure('Invalid addresses response'),
        );
      }

      await ApiCacheStore.instance.write(
        cacheKey,
        data,
        ApiCacheTtl.addresses,
      );

      if (background) {
        return const Right(ClientAddressesResponse(items: []));
      }
      return Right(ClientAddressesResponse.fromJson(data));
    } catch (e) {
      return _fallbackOrLeft(cacheKey, NetworkFailure(e.toString()));
    }
  }

  Future<Either<Failure, ClientAddressesResponse>> _fallbackOrLeft(
    String cacheKey,
    Failure failure,
  ) async {
    final stale = await ApiCacheStore.instance.read(cacheKey, allowStale: true);
    if (stale != null) {
      try {
        return Right(
          ClientAddressesResponse.fromJson(
            Map<String, dynamic>.from(stale.data as Map),
          ),
        );
      } catch (_) {}
    }
    return Left(failure);
  }

  @override
  Future<Either<Failure, void>> createAddress({
    required CreateAddressRequest request,
    required String token,
  }) async {
    try {
      final response = await DioHelper.postData(
        url: ApiConstants.addressesEndPoint,
        data: request.toJson(),
        token: token,
      );
      final status = response?.statusCode ?? 0;
      if (status < 200 || status >= 300) {
        return Left(
          ServerFailure(response?.statusMessage ?? 'Request failed ($status)'),
        );
      }

      final userId = AuthService.instance.currentUserID;
      if (userId != null && userId.isNotEmpty) {
        await ApiCacheStore.instance.remove(ApiCacheKeys.userAddresses(userId));
      }
      return const Right(null);
    } catch (e) {
      return Left(NetworkFailure(e.toString()));
    }
  }
}
