class StripeCheckoutModel {
  const StripeCheckoutModel({
    required this.sessionId,
    required this.checkoutUrl,
  });

  final String sessionId;
  final String checkoutUrl;

  factory StripeCheckoutModel.fromJson(Map<String, dynamic> json) {
    return StripeCheckoutModel(
      sessionId: (json['sessionId'] ?? '').toString(),
      checkoutUrl: (json['checkoutUrl'] ?? '').toString(),
    );
  }
}

class CheckoutStatusModel {
  const CheckoutStatusModel({
    required this.status,
    this.orderGroupId,
    this.orderStatusId,
  });

  final String status;
  final String? orderGroupId;
  final int? orderStatusId;

  bool get isPending => status == 'pending';

  /// Stripe webhook received payment; backend is creating split orders.
  bool get isProcessing => status == 'processing';

  /// Orders exist only after webhook + CreateOrdersFromPendingOrderAsync.
  bool get isCompleted =>
      status == 'completed' &&
      orderGroupId != null &&
      orderGroupId!.isNotEmpty;

  factory CheckoutStatusModel.fromJson(Map<String, dynamic> json) {
    return CheckoutStatusModel(
      status: (json['status'] ?? 'pending').toString(),
      orderGroupId: json['orderGroupId']?.toString(),
      orderStatusId: json['orderStatusId'] as int?,
    );
  }
}
