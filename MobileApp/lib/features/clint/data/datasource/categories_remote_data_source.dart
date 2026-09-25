import 'dart:async';

import 'package:alrasmarket/core/cache/api_cache_keys.dart';
import 'package:alrasmarket/core/cache/api_cache_store.dart';
import 'package:alrasmarket/core/error/failure.dart';
import 'package:alrasmarket/core/services/api_constants.dart';
import 'package:alrasmarket/core/services/dio_helper.dart';
import 'package:alrasmarket/core/utils/dio_user_facing_message.dart';
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
      // Prefer fresh cache (no network). Fall back to stale while revalidating.
      final fresh = await ApiCacheStore.instance.read(cacheKey);
      if (fresh != null) {
        final parsed = _parseCached(fresh.data);
        if (parsed != null) {
          return Right(parsed);
        }
        await ApiCacheStore.instance.remove(cacheKey);
      }

      final stale = await ApiCacheStore.instance.read(
        cacheKey,
        allowStale: true,
      );
      if (stale != null) {
        final parsed = _parseCached(stale.data);
        if (parsed != null) {
          unawaited(_fetchFromNetwork(cacheKey, emitOnly: true));
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
    if (emitOnly) {
      // Disk already updated inside the impl; callers that only revalidate
      // in the background do not need the payload again.
      return result.isRight()
          ? result
          : const Right(CategoriesResponse(count: 0, items: []));
    }
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
          ServerFailure(
            DioUserFacingMessage.fromHttpResponse(
              statusCode: status,
              data: response?.data,
              fallback: response?.statusMessage,
            ),
          ),
        );
      }

      final data = response?.data;
      if (data is! Map) {
        return _fallbackOrLeft(
          cacheKey,
          const ServerFailure('Invalid categories response'),
        );
      }

      final map = Map<String, dynamic>.from(data);
      final parsed = CategoriesResponse.fromJson(map);
      if (parsed.items.isEmpty) {
        return _fallbackOrLeft(
          cacheKey,
          const ServerFailure('Invalid categories response'),
        );
      }

      await ApiCacheStore.instance.write(
        cacheKey,
        map,
        ApiCacheTtl.catalog,
      );

      return Right(parsed);
    } on DioException catch (e) {
      return _fallbackOrLeft(
        cacheKey,
        NetworkFailure(DioUserFacingMessage.fromDio(e)),
      );
    } catch (e) {
      return _fallbackOrLeft(
        cacheKey,
        NetworkFailure(DioUserFacingMessage.sanitize(e)),
      );
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
