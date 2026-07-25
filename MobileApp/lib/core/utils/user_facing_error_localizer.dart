import 'package:alrasmarket/features/clint/domain/entities/cart_entity.dart';
import 'package:alrasmarket/features/clint/domain/entities/cart_item_entity.dart';
import 'package:alrasmarket/generated/l10n.dart';

class UserFacingErrorLocalizer {
  UserFacingErrorLocalizer._();

  static String formatQuantity(double quantity) {
    if (quantity == quantity.roundToDouble()) {
      return quantity.toInt().toString();
    }
    return quantity.toString();
  }

  static bool isCartStockLimitMessage(String message) {
    final lower = message.toLowerCase();
    return message.contains('CART_MAX_AVAILABLE') ||
        lower.contains('exceeds available');
  }

  static String localizeCartError(
    String? message, {
    double? availableQuantity,
    CartEntity? cart,
    int? cartItemId,
  }) {
    if (message == null || message.trim().isEmpty) {
      return S.current.failedToAddProductToCart;
    }

    if (isCartStockLimitMessage(message)) {
      final available = availableQuantity ??
          _availableFromCart(cart, cartItemId) ??
          0;
      return S.current.cartMaxAvailableInStock(formatQuantity(available));
    }

    final lower = message.toLowerCase();
    if (lower.contains('failed to load cart')) {
      return S.current.failedToLoadCart;
    }
    if (lower.contains('failed to add item to cart') ||
        lower.contains('failed to add product to cart')) {
      return S.current.failedToAddProductToCart;
    }
    if (lower.contains('failed to remove cart item')) {
      return S.current.failedToRemoveCartItem;
    }
    if (lower.contains('failed to reduce cart item quantity')) {
      return S.current.failedToReduceCartQuantity;
    }
    if (lower.contains('failed to confirm order')) {
      return S.current.failedToConfirmOrder;
    }

    return message;
  }

  static double? _availableFromCart(CartEntity? cart, int? cartItemId) {
    if (cart == null || cartItemId == null) return null;
    for (final item in cart.items) {
      if (item.id == cartItemId) {
        return item.availableQuantity;
      }
    }
    return null;
  }
}
