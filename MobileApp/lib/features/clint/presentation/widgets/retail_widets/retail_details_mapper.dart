import 'package:alrasmarket/core/utils/product_price_formatter.dart';
import 'package:alrasmarket/core/utils/product_quantity_formatter.dart';
import 'package:alrasmarket/features/company/data/models/my_listing_product_model.dart';
import 'package:alrasmarket/generated/l10n.dart';

class RetailDetailsMapper {
  RetailDetailsMapper._();

  static String weightLabel(MyListingProductModel product, {S? s}) {
    if (s != null) {
      return ProductQuantityFormatter.availableQuantityLabel(product, s);
    }
    final qty = product.quantityForChannel(preferRetail: true).trim();
    final unit = product.unitNameForChannel(preferRetail: true).trim();
    if (qty.isNotEmpty && unit.isNotEmpty) return '$qty $unit';
    if (unit.isNotEmpty) return unit;
    if (qty.isNotEmpty) return qty;
    return '';
  }

  static String priceText(
    MyListingProductModel product, {
    bool preferRetail = false,
  }) {
    final label = ProductPriceFormatter.priceWithCurrency(
      product,
      preferRetail: preferRetail,
    );
    return label.isEmpty ? '—' : label;
  }

  static double unitPrice(
    MyListingProductModel product, {
    bool preferRetail = false,
  }) =>
      ProductPriceFormatter.amountValue(
        product,
        preferRetail: preferRetail,
      );

  static String formatTotal(MyListingProductModel product, double total) =>
      ProductPriceFormatter.totalLabel(product, total);
}
