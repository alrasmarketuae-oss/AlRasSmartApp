class GeoCityModel {
  const GeoCityModel({
    required this.cityId,
    required this.cityName,
  });

  final String cityId;
  final String cityName;

  factory GeoCityModel.fromJson(Map<String, dynamic> json) {
    return GeoCityModel(
      cityId: (json['cityId'] ?? json['id'] ?? '').toString(),
      cityName: json['cityName'] as String? ?? '',
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
