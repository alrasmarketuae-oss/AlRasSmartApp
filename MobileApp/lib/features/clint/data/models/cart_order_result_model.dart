class CartOrderResultModel {
  const CartOrderResultModel({
    this.orderId,
    this.orderGroupId,
    this.pendingOrderId,
    this.paymentMethod = 'CashOnDelivery',
    this.status = 'OrderRequested',
    this.createdOrderIds = const [],
  });

  final String? orderId;
  final String? orderGroupId;
  final String? pendingOrderId;
  final String paymentMethod;
  final String status;
  final List<int> createdOrderIds;

  int? get firstCreatedOrderId =>
      createdOrderIds.isNotEmpty ? createdOrderIds.first : int.tryParse(orderId ?? '');

  bool get isOnlinePending =>
      paymentMethod.toLowerCase() == 'online' &&
      status == 'PendingPayment' &&
      pendingOrderId != null &&
      pendingOrderId!.isNotEmpty;

  factory CartOrderResultModel.fromJson(Map<String, dynamic> json) {
    final createdOrderIds = <int>[];
    final orders = json['orders'];
    if (orders is List) {
      for (final item in orders) {
        if (item is Map<String, dynamic>) {
          final id = int.tryParse(item['id']?.toString() ?? '');
          if (id != null && id > 0) {
            createdOrderIds.add(id);
          }
        }
      }
    }

    return CartOrderResultModel(
      orderId: json['orderId']?.toString() ?? json['id']?.toString(),
      orderGroupId: json['orderGroupId']?.toString(),
      pendingOrderId: json['pendingOrderId']?.toString(),
      paymentMethod: json['paymentMethod']?.toString() ?? 'CashOnDelivery',
      status: json['status']?.toString() ?? 'OrderRequested',
      createdOrderIds: createdOrderIds,
    );
  }
}
