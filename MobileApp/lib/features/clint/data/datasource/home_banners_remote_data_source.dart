import 'dart:async';

import 'package:alrasmarket/core/cache/api_cache_keys.dart';
import 'package:alrasmarket/core/cache/api_cache_store.dart';
import 'package:alrasmarket/core/error/failure.dart';
import 'package:alrasmarket/core/services/api_constants.dart';
import 'package:alrasmarket/core/services/dio_helper.dart';
import 'package:alrasmarket/features/clint/data/models/home_banners_response.dart';
import 'package:dartz/dartz.dart';

abstract class BaseHomeBannersRemoteDataSource {
  Future<Either<Failure, HomeBannersResponse>> fetchHomeBanners({
    bool forceRefresh = false,
  });
}

class HomeBannersRemoteDataSource implements BaseHomeBannersRemoteDataSource {
  @override
  Future<Either<Failure, HomeBannersResponse>> fetchHomeBanners({
    bool forceRefresh = false,
  }) async {
    final cacheKey = ApiCacheKeys.homeBanners;
    if (forceRefresh) {
      await ApiCacheStore.instance.remove(cacheKey);
    } else {
      final cached = await ApiCacheStore.instance.read(cacheKey);
      if (cached != null) {
        try {
          final parsed = HomeBannersResponse.fromJson(
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

  Future<Either<Failure, HomeBannersResponse>> _fetchFromNetwork(
    String cacheKey, {
    required bool emitOnly,
  }) async {
    try {
      final url = ApiConstants.homeBannersAbsoluteUrl;
      final response = await DioHelper.getFullUrl(url);
      final status = response.statusCode ?? 0;
      if (status < 200 || status >= 300) {
        return _fallbackOrLeft(
          cacheKey,
          ServerFailure(response.statusMessage ?? 'Request failed ($status)'),
        );
      }

      final data = response.data;
      if (data is! Map<String, dynamic>) {
        return _fallbackOrLeft(cacheKey, const ServerFailure('Invalid response'));
      }

      await ApiCacheStore.instance.write(
        cacheKey,
        data,
        ApiCacheTtl.catalog,
      );

      if (emitOnly) {
        return Right(HomeBannersResponse(count: 0, items: []));
      }
      return Right(HomeBannersResponse.fromJson(data));
    } catch (e) {
      return _fallbackOrLeft(cacheKey, NetworkFailure(e.toString()));
    }
  }

  Future<Either<Failure, HomeBannersResponse>> _fallbackOrLeft(
    String cacheKey,
    Failure failure,
  ) async {
    final stale = await ApiCacheStore.instance.read(cacheKey, allowStale: true);
    if (stale != null) {
      try {
        return Right(
          HomeBannersResponse.fromJson(
            Map<String, dynamic>.from(stale.data as Map),
          ),
        );
      } catch (_) {}
    }
    return Left(failure);
  }
}
