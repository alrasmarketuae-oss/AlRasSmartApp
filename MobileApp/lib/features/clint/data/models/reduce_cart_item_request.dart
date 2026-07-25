class ReduceCartItemRequest {
  const ReduceCartItemRequest({required this.quantity});

  final double quantity;

  Map<String, dynamic> toJson() => {
        'quantity': quantity,
      };
}
