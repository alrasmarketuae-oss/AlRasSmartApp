import 'package:alrasmarket/core/error/failure.dart';
import 'package:alrasmarket/features/company/data/models/geo_response_models.dart';
import 'package:alrasmarket/features/clint/data/models/geo_city_model.dart';
import 'package:dartz/dartz.dart';

abstract class BaseGeoRepository {
  Future<Either<Failure, List<String>>> getCountries();
  Future<Either<Failure, List<GeoCountryModel>>> getCountryList();
  Future<Either<Failure, GeoPortsResponse>> getPortsByCountry(String countryName);
  Future<Either<Failure, GeoCitiesResponse>> getCitiesByCountry(String countryName);
  Future<Either<Failure, GeoCitiesResponse>> getCitiesByCountryId(int countryId);
}
