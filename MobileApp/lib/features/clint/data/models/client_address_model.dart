class ClientAddressModel {
  const ClientAddressModel({
    required this.addressId,
    required this.label,
    this.cityId = '',
    this.cityName = '',
    this.countryId = 0,
    this.countryNameEn = '',
    this.countryNameAr,
    this.addressLine1 = '',
    this.addressLine2,
    this.addressTypeId = 4,
    this.addressTypeNameEn = '',
    this.addressTypeNameAr = '',
    this.area = '',
    this.street = '',
    this.building = '',
    this.floorNo = '',
    this.unitNo = '',
    this.landmark = '',
    this.postalCode = '',
    this.contactPerson = '',
    this.mobileNumber = '',
    this.deliveryInstructions = '',
    this.latitude,
    this.longitude,
    this.formattedAddress = '',
  });

  final String addressId;
  final String label;
  final String cityId;
  final String cityName;
  final int countryId;
  final String countryNameEn;
  final String? countryNameAr;
  final String addressLine1;
  final String? addressLine2;
  final int addressTypeId;
  final String addressTypeNameEn;
  final String addressTypeNameAr;
  final String area;
  final String street;
  final String building;
  final String floorNo;
  final String unitNo;
  final String landmark;
  final String postalCode;
  final String contactPerson;
  final String mobileNumber;
  final String deliveryInstructions;
  final double? latitude;
  final double? longitude;
  final String formattedAddress;

  String countryDisplayName(bool isArabic) {
    final arabic = countryNameAr?.trim() ?? '';
    if (isArabic && arabic.isNotEmpty) return arabic;
    return countryNameEn;
  }

  String typeDisplayName(bool isArabic) {
    final ar = addressTypeNameAr.trim();
    if (isArabic && ar.isNotEmpty) return ar;
    if (addressTypeNameEn.trim().isNotEmpty) return addressTypeNameEn;
    return AddressTypeOption.labelFor(addressTypeId, isArabic);
  }

  String get formattedAddressLine {
    final formatted = formattedAddress.trim();
    if (formatted.isNotEmpty) return formatted;
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
    final formatted = (json['formattedAddress'] as String? ?? '').trim();
    final typeId = int.tryParse((json['addressTypeId'] ?? '').toString()) ?? 4;

    return ClientAddressModel(
      addressId: (json['addressId'] ?? json['id'] ?? '').toString(),
      cityId: (json['cityId'] ?? json['CityId'] ?? '').toString(),
      cityName: city,
      countryId: int.tryParse((json['countryId'] ?? '').toString()) ?? 0,
      countryNameEn: country,
      countryNameAr: (json['countryNameAr'] as String?)?.trim(),
      addressLine1: line1,
      addressLine2: line2.isEmpty ? null : line2,
      addressTypeId: typeId,
      addressTypeNameEn: (json['addressTypeNameEn'] as String? ?? '').trim(),
      addressTypeNameAr: (json['addressTypeNameAr'] as String? ?? '').trim(),
      area: (json['area'] as String? ?? '').trim(),
      street: (json['street'] as String? ?? '').trim(),
      building: (json['building'] as String? ?? '').trim(),
      floorNo: (json['floorNo'] as String? ?? '').trim(),
      unitNo: (json['unitNo'] as String? ?? '').trim(),
      landmark: (json['landmark'] as String? ?? '').trim(),
      postalCode: (json['postalCode'] as String? ?? '').trim(),
      contactPerson: (json['contactPerson'] as String? ?? '').trim(),
      mobileNumber: (json['mobileNumber'] as String? ?? '').trim(),
      deliveryInstructions: (json['deliveryInstructions'] as String? ?? '').trim(),
      latitude: double.tryParse((json['latitude'] ?? '').toString()),
      longitude: double.tryParse((json['longitude'] ?? '').toString()),
      formattedAddress: formatted,
      label: formatted.isNotEmpty
          ? formatted
          : _formatLabel(
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

class AddressTypeOption {
  const AddressTypeOption(this.id, this.nameEn, this.nameAr);

  final int id;
  final String nameEn;
  final String nameAr;

  String label(bool isArabic) => isArabic ? nameAr : nameEn;

  static const List<AddressTypeOption> values = [
    AddressTypeOption(1, 'Company', 'شركة'),
    AddressTypeOption(2, 'Warehouse', 'مستودع'),
    AddressTypeOption(3, 'Shop', 'محل'),
    AddressTypeOption(4, 'Home', 'منزل'),
  ];

  static String labelFor(int id, bool isArabic) {
    for (final item in values) {
      if (item.id == id) return item.label(isArabic);
    }
    return isArabic ? 'منزل' : 'Home';
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
    this.cityId,
    this.countryId,
    this.cityName,
    required this.addressLine1,
    this.addressLine2,
    this.addressTypeId,
    this.area,
    this.street,
    this.building,
    this.floorNo,
    this.unitNo,
    this.landmark,
    this.postalCode,
    this.contactPerson,
    this.mobileNumber,
    this.deliveryInstructions,
    this.latitude,
    this.longitude,
  });

  final String? cityId;
  final int? countryId;
  final String? cityName;
  final String addressLine1;
  final String? addressLine2;
  final int? addressTypeId;
  final String? area;
  final String? street;
  final String? building;
  final String? floorNo;
  final String? unitNo;
  final String? landmark;
  final String? postalCode;
  final String? contactPerson;
  final String? mobileNumber;
  final String? deliveryInstructions;
  final double? latitude;
  final double? longitude;

  Map<String, dynamic> toJson() {
    final city = cityId?.trim() ?? '';
    final name = cityName?.trim() ?? '';
    return {
      if (city.isNotEmpty) 'cityId': city,
      if (countryId != null) 'countryId': countryId,
      if (name.isNotEmpty) 'cityName': name,
      'addressLine1': addressLine1,
      if (addressLine2 != null && addressLine2!.trim().isNotEmpty)
        'addressLine2': addressLine2!.trim(),
      if (addressTypeId != null) 'addressTypeId': addressTypeId,
      if (_has(area)) 'area': area!.trim(),
      if (_has(street)) 'street': street!.trim(),
      if (_has(building)) 'building': building!.trim(),
      if (_has(floorNo)) 'floorNo': floorNo!.trim(),
      if (_has(unitNo)) 'unitNo': unitNo!.trim(),
      if (_has(landmark)) 'landmark': landmark!.trim(),
      if (_has(postalCode)) 'postalCode': postalCode!.trim(),
      if (_has(contactPerson)) 'contactPerson': contactPerson!.trim(),
      if (_has(mobileNumber)) 'mobileNumber': mobileNumber!.trim(),
      if (_has(deliveryInstructions))
        'deliveryInstructions': deliveryInstructions!.trim(),
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
    };
  }

  static bool _has(String? value) => value != null && value.trim().isNotEmpty;
}
