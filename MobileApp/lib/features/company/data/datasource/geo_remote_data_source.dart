import 'dart:async';

import 'package:alrasmarket/core/cache/api_cache_keys.dart';
import 'package:alrasmarket/core/cache/api_cache_store.dart';
import 'package:alrasmarket/core/error/failure.dart';
import 'package:alrasmarket/core/services/api_constants.dart';
import 'package:alrasmarket/core/services/dio_helper.dart';
import 'package:alrasmarket/features/company/data/models/geo_response_models.dart';
import 'package:alrasmarket/features/clint/data/models/geo_city_model.dart';
import 'package:dartz/dartz.dart';

abstract class BaseGeoRemoteDataSource {
  Future<Either<Failure, GeoCountriesResponse>> fetchCountries({
    bool forceRefresh = false,
  });
  Future<Either<Failure, GeoPortsResponse>> fetchPortsByCountry(
    String countryName, {
    bool forceRefresh = false,
  });
  Future<Either<Failure, GeoCitiesResponse>> fetchCitiesByCountry(
    String countryName, {
    bool forceRefresh = false,
  });
  Future<Either<Failure, GeoCountryListResponse>> fetchCountryList({
    bool forceRefresh = false,
  });
  Future<Either<Failure, GeoCitiesResponse>> fetchCitiesByCountryId(
    int countryId, {
    bool forceRefresh = false,
  });
}

class GeoRemoteDataSource implements BaseGeoRemoteDataSource {
  @override
  Future<Either<Failure, GeoCountriesResponse>> fetchCountries({
    bool forceRefresh = false,
  }) async {
    return _loadCachedGet<GeoCountriesResponse>(
      cacheKey: ApiCacheKeys.geoCountries,
      ttl: ApiCacheTtl.geo,
      forceRefresh: forceRefresh,
      parse: (data) => GeoCountriesResponse.fromJson(
        Map<String, dynamic>.from(data as Map),
      ),
      fetch: () async {
        final response = await DioHelper.getData(
          url: ApiConstants.geoCountriesEndPoint,
        );
        _ensureSuccess(response);
        final data = response!.data;
        if (data is! Map<String, dynamic>) {
          throw const FormatException('Invalid countries response');
        }
        return data;
      },
    );
  }

  /// Same payload as [fetchCountries] but keeps the country ids, which the
  /// address flow needs to save a city under the right country.
  @override
  Future<Either<Failure, GeoCountryListResponse>> fetchCountryList({
    bool forceRefresh = false,
  }) async {
    return _loadCachedGet<GeoCountryListResponse>(
      cacheKey: ApiCacheKeys.geoCountries,
      ttl: ApiCacheTtl.geo,
      forceRefresh: forceRefresh,
      parse: (data) => GeoCountryListResponse.fromJson(
        Map<String, dynamic>.from(data as Map),
      ),
      fetch: () async {
        final response = await DioHelper.getData(
          url: ApiConstants.geoCountriesEndPoint,
        );
        _ensureSuccess(response);
        final data = response!.data;
        if (data is! Map<String, dynamic>) {
          throw const FormatException('Invalid countries response');
        }
        return data;
      },
    );
  }

  @override
  Future<Either<Failure, GeoCitiesResponse>> fetchCitiesByCountryId(
    int countryId, {
    bool forceRefresh = false,
  }) async {
    return _loadCachedGet<GeoCitiesResponse>(
      cacheKey: ApiCacheKeys.geoCities('id-$countryId'),
      ttl: ApiCacheTtl.geo,
      forceRefresh: forceRefresh,
      parse: (data) => GeoCitiesResponse.fromJson(
        Map<String, dynamic>.from(data as Map),
      ),
      fetch: () async {
        final response = await DioHelper.getData(
          url: ApiConstants.geoCitiesByCountryEndPoint,
          query: {'countryId': countryId},
        );
        _ensureSuccess(response);
        final data = response!.data;
        if (data is! Map<String, dynamic>) {
          throw const FormatException('Invalid cities response');
        }
        return data;
      },
    );
  }

  @override
  Future<Either<Failure, GeoPortsResponse>> fetchPortsByCountry(
    String countryName, {
    bool forceRefresh = false,
  }) async {
    return _loadCachedGet<GeoPortsResponse>(
      cacheKey: ApiCacheKeys.geoPorts(countryName),
      ttl: ApiCacheTtl.geo,
      forceRefresh: forceRefresh,
      parse: (data) => GeoPortsResponse.fromJson(
        Map<String, dynamic>.from(data as Map),
      ),
      fetch: () async {
        final response = await DioHelper.getData(
          url: ApiConstants.geoPortsByCountryEndPoint(countryName),
        );
        _ensureSuccess(response);
        final data = response!.data;
        if (data is! Map<String, dynamic>) {
          throw const FormatException('Invalid ports response');
        }
        return data;
      },
    );
  }

  @override
  Future<Either<Failure, GeoCitiesResponse>> fetchCitiesByCountry(
    String countryName, {
    bool forceRefresh = false,
  }) async {
    return _loadCachedGet<GeoCitiesResponse>(
      cacheKey: ApiCacheKeys.geoCities(countryName),
      ttl: ApiCacheTtl.geo,
      forceRefresh: forceRefresh,
      parse: (data) => GeoCitiesResponse.fromJson(
        Map<String, dynamic>.from(data as Map),
      ),
      fetch: () async {
        final response = await DioHelper.getData(
          url: ApiConstants.geoCitiesByCountryEndPoint,
          query: {'countryName': countryName},
        );
        _ensureSuccess(response);
        final data = response!.data;
        if (data is! Map<String, dynamic>) {
          throw const FormatException('Invalid cities response');
        }
        return data;
      },
    );
  }

  Future<Either<Failure, T>> _loadCachedGet<T>({
    required String cacheKey,
    required Duration ttl,
    required bool forceRefresh,
    required T Function(dynamic data) parse,
    required Future<Map<String, dynamic>> Function() fetch,
  }) async {
    if (forceRefresh) {
      await ApiCacheStore.instance.remove(cacheKey);
    } else {
      final cached = await ApiCacheStore.instance.read(cacheKey);
      if (cached != null) {
        try {
          final parsed = parse(cached.data);
          if (!cached.isFresh) {
            unawaited(_refreshRaw(cacheKey, ttl, fetch));
          }
          return Right(parsed);
        } catch (_) {
          await ApiCacheStore.instance.remove(cacheKey);
        }
      }
    }

    try {
      final raw = await fetch();
      await ApiCacheStore.instance.write(cacheKey, raw, ttl);
      return Right(parse(raw));
    } catch (e) {
      final stale = await ApiCacheStore.instance.read(cacheKey, allowStale: true);
      if (stale != null) {
        try {
          return Right(parse(stale.data));
        } catch (_) {}
      }
      return Left(NetworkFailure(e.toString()));
    }
  }

  Future<void> _refreshRaw(
    String cacheKey,
    Duration ttl,
    Future<Map<String, dynamic>> Function() fetch,
  ) async {
    try {
      final raw = await fetch();
      await ApiCacheStore.instance.write(cacheKey, raw, ttl);
    } catch (_) {}
  }

  void _ensureSuccess(dynamic response) {
    final status = response?.statusCode ?? 0;
    if (status < 200 || status >= 300) {
      throw Exception(response?.statusMessage ?? 'Request failed ($status)');
    }
  }
}
