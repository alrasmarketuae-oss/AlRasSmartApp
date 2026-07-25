import 'dart:async';

import 'package:alrasmarket/core/cache/api_cache_keys.dart';
import 'package:alrasmarket/core/cache/api_cache_store.dart';
import 'package:alrasmarket/core/error/failure.dart';
import 'package:alrasmarket/core/services/api_constants.dart';
import 'package:alrasmarket/core/services/dio_helper.dart';
import 'package:alrasmarket/features/clint/data/models/category_model.dart';
import 'package:dartz/dartz.dart';

abstract class BaseCategoriesRemoteDataSource {
  Future<Either<Failure, CategoriesResponse>> fetchCategories({
    bool forceRefresh = false,
  });
}

class CategoriesRemoteDataSource implements BaseCategoriesRemoteDataSource {
  @override
  Future<Either<Failure, CategoriesResponse>> fetchCategories({
    bool forceRefresh = false,
  }) async {
    final cacheKey = ApiCacheKeys.categories;
    if (forceRefresh) {
      await ApiCacheStore.instance.remove(cacheKey);
    } else {
      final cached = await ApiCacheStore.instance.read(cacheKey);
      if (cached != null) {
        try {
          final parsed = CategoriesResponse.fromJson(
            Map<String, dynamic>.from(cached.data as Map),
          );
          if (!cached.isFresh) {
            unawaited(_fetchFromNetwork(cacheKey, emitOnly: true));
          }
          return Right(parsed);
        } catch (_) {
          await ApiCacheStore.instance.remove(cacheKey);
        }
      }
    }

    return _fetchFromNetwork(cacheKey, emitOnly: false);
  }

  Future<Either<Failure, CategoriesResponse>> _fetchFromNetwork(
    String cacheKey, {
    required bool emitOnly,
  }) async {
    try {
      final response = await DioHelper.getData(url: ApiConstants.categoriesEndPoint);
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

      await ApiCacheStore.instance.write(
        cacheKey,
        data,
        ApiCacheTtl.catalog,
      );

      if (emitOnly) return const Right(CategoriesResponse(count: 0, items: []));
      return Right(CategoriesResponse.fromJson(data));
    } catch (e) {
      return _fallbackOrLeft(cacheKey, NetworkFailure(e.toString()));
    }
  }

  Future<Either<Failure, CategoriesResponse>> _fallbackOrLeft(
    String cacheKey,
    Failure failure,
  ) async {
    final stale = await ApiCacheStore.instance.read(cacheKey, allowStale: true);
    if (stale != null) {
      try {
        return Right(
          CategoriesResponse.fromJson(
            Map<String, dynamic>.from(stale.data as Map),
          ),
        );
      } catch (_) {}
    }
    return Left(failure);
  }
}
