import 'package:alrasmarket/core/utils/thousands_separator_input_formatter.dart';
import 'package:alrasmarket/features/company/data/models/my_listing_product_model.dart';

/// Stock helpers for sellable marketplace products (not request ads).
class ProductStock {
  ProductStock._();

  static double? parseQuantity(String? raw) =>
      ThousandsNumberInput.parseDouble(raw);

  /// True when backend quantity is explicitly zero (or negative).
  /// Request ads are never treated as sold out.
  static bool isSoldOut(
    MyListingProductModel product, {
    bool preferRetail = false,
  }) {
    if (product.isListingSoldOut) return true;
    if (product.isRequestProduct) return false;
    final qty = parseQuantity(
      product.quantityForChannel(preferRetail: preferRetail),
    );
    return qty != null && qty <= 0;
  }
}
