import 'package:alrasmarket/features/clint/data/models/cart_item_model.dart';
import 'package:alrasmarket/features/clint/domain/entities/cart_entity.dart';

class CartResponseModel {
  const CartResponseModel({
    this.cartId,
    this.items = const [],
  });

  final String? cartId;
  final List<CartItemModel> items;

  factory CartResponseModel.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] as List<dynamic>? ?? const [];
    return CartResponseModel(
      cartId: json['cartId']?.toString(),
      items: rawItems
          .whereType<Map<String, dynamic>>()
          .map(CartItemModel.fromJson)
          .toList(),
    );
  }

  CartEntity toEntity() => CartEntity(
        cartId: cartId,
        items: items.map((item) => item.toEntity()).toList(),
      );
}
