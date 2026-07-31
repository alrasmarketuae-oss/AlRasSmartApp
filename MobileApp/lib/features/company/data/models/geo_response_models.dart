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

/// A country row from `GET /Geo/countries`, keeping the id so cities can be
/// looked up and addresses saved without relying on name matching.
class GeoCountryModel {
  const GeoCountryModel({
    required this.countryId,
    required this.nameEn,
    this.nameAr,
    this.iso2Code = '',
  });

  final int countryId;
  final String nameEn;
  final String? nameAr;
  final String iso2Code;

  String displayName(bool isArabic) {
    final arabic = nameAr?.trim() ?? '';
    if (isArabic && arabic.isNotEmpty) return arabic;
    return nameEn;
  }

  factory GeoCountryModel.fromJson(Map<String, dynamic> json) {
    return GeoCountryModel(
      countryId:
          int.tryParse((json['countryId'] ?? json['id'] ?? '').toString()) ?? 0,
      nameEn: (json['countryNameEn'] ?? json['country'] ?? json['name'] ?? '')
          .toString()
          .trim(),
      nameAr: (json['countryNameAr'] as String?)?.trim(),
      iso2Code: (json['iso2Code'] ?? '').toString().trim(),
    );
  }
}

class GeoCountryListResponse {
  const GeoCountryListResponse({required this.items});

  final List<GeoCountryModel> items;

  factory GeoCountryListResponse.fromJson(Map<String, dynamic> json) {
    final itemsJson = json['items'] as List<dynamic>? ??
        json['countries'] as List<dynamic>? ??
        [];

    final items = <GeoCountryModel>[];
    for (final item in itemsJson) {
      if (item is! Map) continue;
      final country =
          GeoCountryModel.fromJson(Map<String, dynamic>.from(item));
      if (country.countryId > 0 && country.nameEn.isNotEmpty) {
        items.add(country);
      }
    }

    return GeoCountryListResponse(items: items);
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
