import 'dart:async';

import 'package:alrasmarket/core/cache/api_cache_keys.dart';
import 'package:alrasmarket/core/cache/api_cache_store.dart';
import 'package:alrasmarket/core/error/failure.dart';
import 'package:alrasmarket/core/services/api_constants.dart';
import 'package:alrasmarket/core/services/dio_helper.dart';
import 'package:alrasmarket/features/clint/data/models/category_model.dart';
import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';

abstract class BaseCategoriesRemoteDataSource {
  Future<Either<Failure, CategoriesResponse>> fetchCategories({
    bool forceRefresh = false,
  });
}

class CategoriesRemoteDataSource implements BaseCategoriesRemoteDataSource {
  static Future<Either<Failure, CategoriesResponse>>? _inFlightNetwork;

  @override
  Future<Either<Failure, CategoriesResponse>> fetchCategories({
    bool forceRefresh = false,
  }) async {
    final cacheKey = ApiCacheKeys.categories;
    if (forceRefresh) {
      await ApiCacheStore.instance.remove(cacheKey);
    } else {
      final cached = await ApiCacheStore.instance.read(
        cacheKey,
        allowStale: true,
      );
      if (cached != null) {
        final parsed = _parseCached(cached.data);
        if (parsed != null) {
          if (!cached.isFresh) {
            unawaited(_fetchFromNetwork(cacheKey, emitOnly: true));
          }
          return Right(parsed);
        }
        await ApiCacheStore.instance.remove(cacheKey);
      }
    }

    return _fetchFromNetwork(cacheKey, emitOnly: false);
  }

  CategoriesResponse? _parseCached(dynamic data) {
    if (data is! Map) return null;
    try {
      final parsed = CategoriesResponse.fromJson(
        Map<String, dynamic>.from(data),
      );
      if (parsed.items.isEmpty) return null;
      return parsed;
    } catch (_) {
      return null;
    }
  }

  Future<Either<Failure, CategoriesResponse>> _fetchFromNetwork(
    String cacheKey, {
    required bool emitOnly,
  }) async {
    _inFlightNetwork ??= _fetchFromNetworkImpl(cacheKey).whenComplete(() {
      _inFlightNetwork = null;
    });
    final result = await _inFlightNetwork!;
    if (emitOnly) return const Right(CategoriesResponse(count: 0, items: []));
    return result;
  }

  Future<Either<Failure, CategoriesResponse>> _fetchFromNetworkImpl(
    String cacheKey,
  ) async {
    try {
      final response = await DioHelper.getData(
        url: ApiConstants.categoriesEndPoint,
        receiveTimeout: const Duration(seconds: 60),
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
          const ServerFailure('Invalid categories response'),
        );
      }

      final parsed = CategoriesResponse.fromJson(data);
      if (parsed.items.isEmpty) {
        return _fallbackOrLeft(
          cacheKey,
          const ServerFailure('Invalid categories response'),
        );
      }

      await ApiCacheStore.instance.write(
        cacheKey,
        data,
        ApiCacheTtl.catalog,
      );

      return Right(parsed);
    } on DioException catch (e) {
      final String message;
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.sendTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        message = 'Request timed out. Please try again.';
      } else if (e.type == DioExceptionType.connectionError) {
        message = 'Please check your internet connection.';
      } else {
        message = e.message ?? e.toString();
      }
      return _fallbackOrLeft(cacheKey, NetworkFailure(message));
    } catch (e) {
      return _fallbackOrLeft(cacheKey, NetworkFailure(e.toString()));
    }
  }

  Future<Either<Failure, CategoriesResponse>> _fallbackOrLeft(
    String cacheKey,
    Failure failure,
  ) async {
    final stale = await ApiCacheStore.instance.read(cacheKey, allowStale: true);
    final parsed = stale != null ? _parseCached(stale.data) : null;
    if (parsed != null) return Right(parsed);
    return Left(failure);
  }
}
