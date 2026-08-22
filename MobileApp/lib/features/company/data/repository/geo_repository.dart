import 'package:alrasmarket/core/error/failure.dart';
import 'package:alrasmarket/features/clint/data/models/geo_city_model.dart';
import 'package:alrasmarket/features/company/data/datasource/geo_remote_data_source.dart';
import 'package:alrasmarket/features/company/data/models/geo_response_models.dart';
import 'package:alrasmarket/features/company/domain/repository/base_geo_repository.dart';
import 'package:dartz/dartz.dart';

class GeoRepository implements BaseGeoRepository {
  GeoRepository({required BaseGeoRemoteDataSource remote}) : _remote = remote;

  final BaseGeoRemoteDataSource _remote;

  @override
  Future<Either<Failure, List<String>>> getCountries() async {
    final result = await _remote.fetchCountries();
    return result.fold(Left.new, (response) => Right(response.countries));
  }

  @override
  Future<Either<Failure, List<GeoCountryModel>>> getCountryList() async {
    final result = await _remote.fetchCountryList();
    return result.fold(Left.new, (response) => Right(response.items));
  }

  @override
  Future<Either<Failure, GeoCitiesResponse>> getCitiesByCountryId(
    int countryId,
  ) async {
    final result = await _remote.fetchCitiesByCountryId(countryId);
    return result.fold(Left.new, Right.new);
  }

  @override
  Future<Either<Failure, GeoPortsResponse>> getPortsByCountry(
    String countryName, {
    bool forceRefresh = false,
  }) async {
    final result = await _remote.fetchPortsByCountry(
      countryName,
      forceRefresh: forceRefresh,
    );
    return result.fold(Left.new, Right.new);
  }

  @override
  Future<Either<Failure, GeoCitiesResponse>> getCitiesByCountry(
    String countryName,
  ) async {
    final result = await _remote.fetchCitiesByCountry(countryName);
    return result.fold(Left.new, Right.new);
  }
}
