import 'package:alrasmarket/core/services/api_constants.dart';
import 'package:alrasmarket/features/clint/domain/entities/cart_item_entity.dart';

class CartItemModel {
  const CartItemModel({
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

  factory CartItemModel.fromJson(Map<String, dynamic> json) {
    final quantity = _parseDouble(json['quantity']);
    final unitPriceAed = _parseDouble(json['unitPriceAed']);
    final totalPriceAed = json['totalPriceAed'] != null
        ? _parseDouble(json['totalPriceAed'])
        : unitPriceAed * quantity;

    return CartItemModel(
      id: _parseInt(json['id']),
      productId: json['productId']?.toString() ?? '',
      productName: json['productName']?.toString() ?? '',
      quantity: quantity,
      unitName: json['unit']?.toString() ?? json['unitName']?.toString() ?? '',
      unitPriceAed: unitPriceAed,
      totalPriceAed: totalPriceAed,
      imageUrl: _resolveMediaUrl(json['imageUrl']?.toString()),
      videoUrl: _resolveMediaUrl(json['videoUrl']?.toString()),
      videoDurationSeconds: _parseOptionalInt(json['videoDurationSeconds']),
      availableQuantity: json['availableQuantity'] != null
          ? _parseDouble(json['availableQuantity'])
          : null,
    );
  }

  CartItemEntity toEntity() => CartItemEntity(
        id: id,
        productId: productId,
        productName: productName,
        quantity: quantity,
        unitName: unitName,
        unitPriceAed: unitPriceAed,
        totalPriceAed: totalPriceAed,
        imageUrl: imageUrl,
        videoUrl: videoUrl,
        videoDurationSeconds: videoDurationSeconds,
        availableQuantity: availableQuantity,
      );

  static int _parseInt(dynamic value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static double _parseDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  static String? _resolveMediaUrl(String? path) {
    if (path != null && path.startsWith('assets/')) return path;
    final url = ApiConstants.resolveMediaUrl(path);
    return url.isEmpty ? null : url;
  }

  static int? _parseOptionalInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value > 0 ? value : null;
    final parsed = int.tryParse(value.toString());
    if (parsed == null || parsed <= 0) return null;
    return parsed;
  }
}
