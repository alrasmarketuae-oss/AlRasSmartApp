import 'package:alrasmarket/core/error/failure.dart';
import 'package:alrasmarket/features/clint/data/models/geo_city_model.dart';
import 'package:alrasmarket/features/company/data/models/geo_response_models.dart';
import 'package:alrasmarket/features/company/domain/repository/base_geo_repository.dart';
import 'package:dartz/dartz.dart';

class GetGeoCountriesUseCase {
  GetGeoCountriesUseCase(this._repository);

  final BaseGeoRepository _repository;

  Future<Either<Failure, List<String>>> call() => _repository.getCountries();
}

class GetGeoPortsByCountryUseCase {
  GetGeoPortsByCountryUseCase(this._repository);

  final BaseGeoRepository _repository;

  Future<Either<Failure, GeoPortsResponse>> call(String countryName) {
    return _repository.getPortsByCountry(countryName);
  }
}

class GetGeoCitiesByCountryUseCase {
  GetGeoCitiesByCountryUseCase(this._repository);

  final BaseGeoRepository _repository;

  Future<Either<Failure, GeoCitiesResponse>> call(String countryName) {
    return _repository.getCitiesByCountry(countryName);
  }
}
