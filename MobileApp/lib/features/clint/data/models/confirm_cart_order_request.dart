class ConfirmCartOrderRequest {
  const ConfirmCartOrderRequest({
    required this.paymentMethodName,
    required this.shippingCostAed,
    this.isSelfPickup = false,
    this.addressId,
    this.cityName,
    this.addressLine,
  });

  final String paymentMethodName;
  final double shippingCostAed;
  final bool isSelfPickup;
  final String? addressId;
  final String? cityName;
  final String? addressLine;

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'paymentMethodName': paymentMethodName,
      'shippingCostAed': shippingCostAed,
      'isSelfPickup': isSelfPickup,
    };

    final addressIdValue = addressId?.trim();
    if (addressIdValue != null && addressIdValue.isNotEmpty) {
      json['addressId'] = addressIdValue;
    }

    final city = cityName?.trim();
    if (city != null && city.isNotEmpty) {
      json['cityName'] = city;
    }

    final address = addressLine?.trim();
    if (address != null && address.isNotEmpty) {
      json['addressLine'] = address;
    }

    return json;
  }
}
