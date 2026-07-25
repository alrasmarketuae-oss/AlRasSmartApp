class AddCartItemRequest {
  const AddCartItemRequest({
    required this.productId,
    required this.quantity,
    required this.unitName,
  });

  final String productId;
  final double quantity;
  final String unitName;

  Map<String, dynamic> toJson() => {
    'productId': productId,
    'quantity': quantity,
    'unitName': unitName,
  };
}
