import 'package:alrasmarket/core/utils/product_quantity_formatter.dart';
import 'package:equatable/equatable.dart';

class CartItemEntity extends Equatable {
  const CartItemEntity({
    required this.id,
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.unitName,
    required this.unitPriceAed,
    required this.totalPriceAed,
    this.imageUrl,
    this.videoUrl,
    this.videoDurationSeconds,
    this.availableQuantity,
  });

  final int id;
  final String productId;
  final String productName;
  final double quantity;
  final String unitName;
  final double unitPriceAed;
  final double totalPriceAed;
  final String? imageUrl;
  final String? videoUrl;
  final int? videoDurationSeconds;
  final double? availableQuantity;

  bool get canIncrement {
    final max = availableQuantity;
    if (max == null) return true;
    return quantity + 0.0001 < max;
  }

  String get quantityLabel {
    final unit = ProductQuantityFormatter.compactUnitLabel(unitName);
    if (unit.isEmpty) return quantity.toString();
    return '$quantity $unit';
  }

  static String formatAmountOnly(double amount) {
    final rounded = (amount * 100).roundToDouble() / 100;
    if (rounded == rounded.roundToDouble()) {
      return rounded.toInt().toString();
    }
    return rounded.toStringAsFixed(2);
  }

  String get unitPriceAmount => formatAmountOnly(unitPriceAed);

  String get totalPriceAmount => formatAmountOnly(totalPriceAed);

  String get formattedUnitPrice => formatAed(unitPriceAed);

  String get formattedTotalPrice => formatAed(totalPriceAed);

  static String formatAed(double aed) {
    final rounded = (aed * 100).roundToDouble() / 100;
    if (rounded == rounded.roundToDouble()) {
      return '${rounded.toInt()} AED';
    }
    return '${rounded.toStringAsFixed(2)} AED';
  }

  CartItemEntity copyWith({
    double? quantity,
    double? totalPriceAed,
    double? availableQuantity,
  }) {
    return CartItemEntity(
      id: id,
      productId: productId,
      productName: productName,
      quantity: quantity ?? this.quantity,
      unitName: unitName,
      unitPriceAed: unitPriceAed,
      totalPriceAed: totalPriceAed ?? this.totalPriceAed,
      imageUrl: imageUrl,
      videoUrl: videoUrl,
      videoDurationSeconds: videoDurationSeconds,
      availableQuantity: availableQuantity ?? this.availableQuantity,
    );
  }

  @override
  List<Object?> get props => [
        id,
        productId,
        productName,
        quantity,
        unitName,
        unitPriceAed,
        totalPriceAed,
        imageUrl,
        videoUrl,
        videoDurationSeconds,
        availableQuantity,
      ];
}
