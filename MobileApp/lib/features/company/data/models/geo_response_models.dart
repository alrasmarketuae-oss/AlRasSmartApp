import 'package:alrasmarket/core/utils/localized_product_text.dart';

import 'geo_port_model.dart';

class GeoPortsResponse {
  const GeoPortsResponse({
    required this.country,
    required this.ports,
  });

  final String country;
  final List<GeoPortModel> ports;

  factory GeoPortsResponse.fromJson(Map<String, dynamic> json) {
    final portsJson = json['ports'] as List<dynamic>? ?? [];
    return GeoPortsResponse(
      country: LocalizedProductText.pickCountry(
        nameEn: json['countryNameEn']?.toString() ?? json['country']?.toString(),
        nameAr: json['countryNameAr']?.toString(),
        fallback: json['country']?.toString(),
      ),
      ports: portsJson
          .whereType<Map>()
          .map((item) => GeoPortModel.fromJson(Map<String, dynamic>.from(item)))
          .toList(),
    );
  }
}

class GeoCountriesResponse {
  const GeoCountriesResponse({required this.countries});

  final List<String> countries;

  factory GeoCountriesResponse.fromJson(Map<String, dynamic> json) {
    final countriesJson = json['items'] as List<dynamic>? ??
        json['countries'] as List<dynamic>? ??
        [];

    final countries = <String>[];
    for (final item in countriesJson) {
      if (item is String) {
        final value = item.trim();
        if (value.isNotEmpty) countries.add(value);
        continue;
      }
      if (item is Map) {
        final map = Map<String, dynamic>.from(item);
        final localized = LocalizedProductText.pick(
          json: map,
          arKeys: const ['countryNameAr', 'CountryNameAr'],
          enKeys: const [
            'countryNameEn',
            'CountryNameEn',
            'country',
            'name',
          ],
        );
        if (localized.isNotEmpty) countries.add(localized);
      }
    }

    return GeoCountriesResponse(countries: countries);
  }
}
