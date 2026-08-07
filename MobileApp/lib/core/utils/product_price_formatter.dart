import 'package:alrasmarket/core/serveses/auth_service.dart';
import 'package:alrasmarket/core/utils/product_quantity_formatter.dart';
import 'package:alrasmarket/core/utils/thousands_separator_input_formatter.dart';
import 'package:alrasmarket/features/company/data/models/my_listing_product_model.dart';
import 'package:alrasmarket/generated/l10n.dart';

class ProductPriceFormatter {
  static bool get canShowPrices => AuthService.instance.isAuthenticated;

  static String amount(
    MyListingProductModel product, {
    bool preferRetail = false,
  }) {
    return formatAmountText(product.priceForChannel(preferRetail: preferRetail));
  }

  /// Numeric unit price for order math (unit × quantity).
  /// Always strips thousand separators / currency text before parsing.
  static double amountValue(
    MyListingProductModel product, {
    bool preferRetail = false,
  }) {
    final candidates = <String>[
      product.priceForChannel(preferRetail: preferRetail),
      if (preferRetail) product.retailPrice,
      product.displayPrice,
      product.priceUsd,
      product.ownerListingPrice,
    ];
    for (final candidate in candidates) {
      final value = ThousandsNumberInput.parseDouble(candidate);
      if (value != null && value > 0) return value;
    }
    return 0;
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
    S? s,
  }) {
    final unit = product.unitNameForChannel(preferRetail: preferRetail).trim();
    if (unit.isEmpty) return '';
    final displayUnit = s != null
        ? ProductQuantityFormatter.singularUnitLabel(unit, s)
        : ProductQuantityFormatter.compactUnitLabel(unit);
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
    S? s,
  }) {
    final price = amount(product, preferRetail: preferRetail);
    if (price.isEmpty) return '';
    final suffix = unitSuffix(product, preferRetail: preferRetail, s: s);
    return '$price ${currencyCode(product)}$suffix';
  }

  static String totalLabel(MyListingProductModel product, double total) {
    final formatted = ThousandsNumberInput.format(total, allowDecimal: true);
    return '$formatted ${currencyCode(product)}';
  }
}
