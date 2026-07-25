import 'package:equatable/equatable.dart';

import 'cart_item_entity.dart';

class CartEntity extends Equatable {
  const CartEntity({
    this.cartId,
    this.items = const [],
    this.deliveryFeeAed = 0,
  });

  static const double vatRate = 0.05;

  final String? cartId;
  final List<CartItemEntity> items;
  final double deliveryFeeAed;

  bool get isEmpty => items.isEmpty;

  double get subtotalAed =>
      items.fold(0, (sum, item) => sum + item.totalPriceAed);

  double get vatAed => isEmpty ? 0 : subtotalAed * vatRate;

  double get totalAed =>
      isEmpty ? 0 : subtotalAed + vatAed + deliveryFeeAed;

  double get estimatedWeightKg => items.fold<double>(0, (sum, item) {
        return sum + _lineWeightKg(item.quantity, item.unitName);
      });

  bool get hasWeightOverTenKg => estimatedWeightKg > 10;

  /// Free first 10 kg; each whole excess kg × [excessKgRateAed] + emirate base.
  double shippingFeeWithExcess({
    required double emirateBaseAed,
    required int excessKgRateAed,
    double freeWeightKg = 10,
  }) {
    final excess = estimatedWeightKg - freeWeightKg;
    final billableExcess =
        excess <= 0 ? 0.0 : excess.ceilToDouble();
    final rate = excessKgRateAed.clamp(0, 255).toDouble();
    return emirateBaseAed + (billableExcess * rate);
  }

  static double _lineWeightKg(double quantity, String unitName) {
    if (quantity <= 0) return 0;
    final unit = unitName.trim().toLowerCase();
    switch (unit) {
      case 'kg':
      case 'kilogram':
      case 'kilograms':
      case 'kilo':
      case 'kilos':
      case 'kgs':
        return quantity;
      case 'gram':
      case 'grams':
      case 'g':
        return quantity * 0.001;
      case 'ton':
      case 'tons':
      case 'tonne':
      case 'tonnes':
        return quantity * 1000;
      default:
        return 0;
    }
  }

  String get formattedSubtotal => CartItemEntity.formatAed(subtotalAed);

  String get formattedVat => CartItemEntity.formatAed(vatAed);

  String get formattedDelivery => CartItemEntity.formatAed(deliveryFeeAed);

  String get formattedTotal => CartItemEntity.formatAed(totalAed);

  @override
  List<Object?> get props => [cartId, items, deliveryFeeAed];

  CartEntity copyWith({
    String? cartId,
    List<CartItemEntity>? items,
    double? deliveryFeeAed,
  }) {
    return CartEntity(
      cartId: cartId ?? this.cartId,
      items: items ?? this.items,
      deliveryFeeAed: deliveryFeeAed ?? this.deliveryFeeAed,
    );
  }
}
