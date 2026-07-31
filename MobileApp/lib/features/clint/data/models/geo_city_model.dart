class GeoCityModel {
  const GeoCityModel({
    required this.cityId,
    required this.cityName,
    this.countryId = 0,
  });

  final String cityId;
  final String cityName;
  final int countryId;

  factory GeoCityModel.fromJson(Map<String, dynamic> json) {
    return GeoCityModel(
      cityId: (json['cityId'] ?? json['id'] ?? '').toString(),
      cityName: json['cityName'] as String? ?? '',
      countryId: int.tryParse((json['countryId'] ?? '').toString()) ?? 0,
    );
  }
}

class GeoCitiesResponse {
  const GeoCitiesResponse({required this.items});

  final List<GeoCityModel> items;

  factory GeoCitiesResponse.fromJson(Map<String, dynamic> json) {
    final itemsJson = json['items'] as List<dynamic>? ?? [];
    return GeoCitiesResponse(
      items: itemsJson
          .map((item) => GeoCityModel.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}
