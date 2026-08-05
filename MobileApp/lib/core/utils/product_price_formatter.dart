import 'package:alrasmarket/core/serveses/auth_service.dart';
import 'package:alrasmarket/core/utils/thousands_separator_input_formatter.dart';
import 'package:alrasmarket/features/company/data/models/my_listing_product_model.dart';

class ProductPriceFormatter {
  static bool get canShowPrices => AuthService.instance.isAuthenticated;

  static String amount(
    MyListingProductModel product, {
    bool preferRetail = false,
  }) {
    return formatAmountText(product.priceForChannel(preferRetail: preferRetail));
  }

  /// Formats a raw price string for display (e.g. `1150` → `1,150`).
  static String formatAmountText(String? raw) {
    final text = raw?.trim() ?? '';
    if (text.isEmpty) return '';
    final formatted = ThousandsNumberInput.formatRaw(text, allowDecimal: true);
    return formatted.isEmpty ? text : formatted;
  }

  static String currencyCode(MyListingProductModel product) {
    final code = product.currency.trim().toUpperCase();
    return code.isEmpty ? 'USD' : code;
  }

  static String unitSuffix(
    MyListingProductModel product, {
    bool preferRetail = false,
  }) {
    final unit = product.unitNameForChannel(preferRetail: preferRetail).trim();
    final displayUnit = unit.toLowerCase() == 'kilogram' ? 'kg' : unit;
    return displayUnit.isEmpty ? '' : ' / $displayUnit';
  }

  static String priceWithCurrency(
    MyListingProductModel product, {
    bool preferRetail = false,
  }) {
    final price = amount(product, preferRetail: preferRetail);
    if (price.isEmpty) return '';
    return '$price ${currencyCode(product)}';
  }

  static String unitPriceLabel(
    MyListingProductModel product, {
    bool preferRetail = false,
  }) {
    final price = amount(product, preferRetail: preferRetail);
    if (price.isEmpty) return '';
    final suffix = unitSuffix(product, preferRetail: preferRetail);
    return '$price ${currencyCode(product)}$suffix';
  }

  static String totalLabel(MyListingProductModel product, double total) {
    final formatted = ThousandsNumberInput.format(total, allowDecimal: true);
    return '$formatted ${currencyCode(product)}';
  }
}
