class ClientAddressModel {
  const ClientAddressModel({
    required this.addressId,
    required this.label,
    this.cityId = '',
    this.cityName = '',
    this.countryNameEn = '',
    this.addressLine1 = '',
    this.addressLine2,
  });

  final String addressId;
  final String label;
  final String cityId;
  final String cityName;
  final String countryNameEn;
  final String addressLine1;
  final String? addressLine2;

  String get formattedAddressLine {
    final line1 = addressLine1.trim();
    final line2 = addressLine2?.trim() ?? '';
    if (line1.isEmpty) return line2;
    if (line2.isEmpty) return line1;
    return '$line1, $line2';
  }

  factory ClientAddressModel.fromJson(Map<String, dynamic> json) {
    final country = (json['countryNameEn'] as String? ?? '').trim();
    final city = (json['cityName'] as String? ?? '').trim();
    final line1 = (json['addressLine1'] as String? ?? '').trim();
    final line2 = (json['addressLine2'] as String? ?? '').trim();

    return ClientAddressModel(
      addressId: (json['addressId'] ?? json['id'] ?? '').toString(),
      cityId: (json['cityId'] ?? json['CityId'] ?? '').toString(),
      cityName: city,
      countryNameEn: country,
      addressLine1: line1,
      addressLine2: line2.isEmpty ? null : line2,
      label: _formatLabel(
        country: country,
        city: city,
        line1: line1,
        line2: line2,
      ),
    );
  }

  static String _formatLabel({
    required String country,
    required String city,
    required String line1,
    required String line2,
  }) {
    final parts = <String>[
      if (country.isNotEmpty) country,
      if (city.isNotEmpty) city,
      if (line1.isNotEmpty) line1,
      if (line2.isNotEmpty) line2,
    ];
    return parts.join(' - ');
  }
}

class ClientAddressesResponse {
  const ClientAddressesResponse({required this.items});

  final List<ClientAddressModel> items;

  factory ClientAddressesResponse.fromJson(Map<String, dynamic> json) {
    final itemsJson = json['items'] as List<dynamic>? ?? [];
    return ClientAddressesResponse(
      items: itemsJson
          .map(
            (item) =>
                ClientAddressModel.fromJson(item as Map<String, dynamic>),
          )
          .toList(),
    );
  }
}

class CreateAddressRequest {
  const CreateAddressRequest({
    required this.cityId,
    required this.addressLine1,
    this.addressLine2,
  });

  final String cityId;
  final String addressLine1;
  final String? addressLine2;

  Map<String, dynamic> toJson() {
    return {
      'cityId': cityId,
      'addressLine1': addressLine1,
      if (addressLine2 != null && addressLine2!.trim().isNotEmpty)
        'addressLine2': addressLine2!.trim(),
    };
  }
}
