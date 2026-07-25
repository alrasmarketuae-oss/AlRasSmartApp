class CreateOrderRequest {
  const CreateOrderRequest({
    required this.toUserId,
    required this.productId,
    required this.supplierEmail,
    required this.unitName,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
    required this.paymentMethodName,
    this.notes = '',
    this.imagePaths = const [],
    this.videoPaths = const [],
    this.documentPaths = const [],
    this.addressLine = '',
    this.cityName = '',
    this.shippingCostAed = 0,
    this.portName,
  });

  final String toUserId;
  final String productId;
  final String supplierEmail;
  final String unitName;
  final double quantity;
  final double unitPrice;
  final double totalPrice;
  final String paymentMethodName;
  final String notes;
  final List<String> imagePaths;
  final List<String> videoPaths;
  final List<String> documentPaths;
  final String addressLine;
  final String cityName;
  final double shippingCostAed;
  final String? portName;
  Map<String, dynamic> toJson() => {
        'toUserId': toUserId,
        'productId': productId,
        'supplierEmail': supplierEmail,
        'unitName': unitName,
        'quantity': quantity,
        'unitPrice': unitPrice,
        'totalPrice': totalPrice,
        'paymentMethodName': paymentMethodName,
        'notes': notes,
        'imagePaths': imagePaths,
        'videoPaths': videoPaths,
        'documentPaths': documentPaths,
        'addressLine': addressLine,
        'cityName': cityName,
        'shippingCostAed': shippingCostAed,
        if (portName != null && portName!.isNotEmpty) 'portName': portName,
      };
}
