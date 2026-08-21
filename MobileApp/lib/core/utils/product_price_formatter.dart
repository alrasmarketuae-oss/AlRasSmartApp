import 'package:alrasmarket/core/serveses/auth_service.dart';
import 'package:alrasmarket/core/utils/product_quantity_formatter.dart';
import 'package:alrasmarket/core/utils/thousands_separator_input_formatter.dart';
import 'package:alrasmarket/features/clint/presentation/helpers/product_ownership_helper.dart';
import 'package:alrasmarket/features/company/data/models/my_listing_product_model.dart';
import 'package:alrasmarket/features/company/presentation/models/create_ad_currency.dart';
import 'package:alrasmarket/generated/l10n.dart';

class ProductPriceFormatter {
  static bool get canShowPrices => AuthService.instance.isAuthenticated;

  static bool _isOwner(MyListingProductModel product) =>
      ProductOwnershipHelper.isOwnedByCurrentUser(product);

  /// Raw unit price text for the current viewer (owner = set price, else marked-up).
  static String rawAmount(
    MyListingProductModel product, {
    bool preferRetail = false,
  }) {
    if (_isOwner(product)) {
      if (preferRetail && product.hasRetailPricing) {
        final retail = product.ownerRetailPrice.trim();
        if (retail.isNotEmpty) return retail;
      }
      final owner = product.ownerPrice.trim();
      if (owner.isNotEmpty) return owner;
      final ownerUsd = product.ownerUsdPrice.trim();
      if (ownerUsd.isNotEmpty) return ownerUsd;
      return product.ownerListingPrice;
    }
    return product.priceForChannel(preferRetail: preferRetail);
  }

  static String amount(
    MyListingProductModel product, {
    bool preferRetail = false,
  }) {
    return formatAmountText(rawAmount(product, preferRetail: preferRetail));
  }

  /// Numeric unit price for order math (unit × quantity).
  /// Always strips thousand separators / currency text before parsing.
  static double amountValue(
    MyListingProductModel product, {
    bool preferRetail = false,
  }) {
    final candidates = <String>[
      rawAmount(product, preferRetail: preferRetail),
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

  /// Offer sale price for the current viewer (owner sees set price).
  static double saleAmountValue(MyListingProductModel product) {
    final owned = amountValue(product);
    if (owned > 0 && _isOwner(product)) return owned;
    return product.salePriceValue;
  }

  /// Pre-discount price for the current viewer.
  static double originalAmountValue(MyListingProductModel product) {
    if (_isOwner(product)) {
      final sale = saleAmountValue(product);
      final pct = product.discountPercentValue;
      if (sale <= 0 || pct <= 0 || pct >= 100) return sale;
      return sale / (1 - (pct / 100));
    }
    return product.originalPriceValue;
  }

  /// Formats a raw price string for display (e.g. `1150` → `1,150`).
  static String formatAmountText(String? raw) {
    final text = raw?.trim() ?? '';
    if (text.isEmpty) return '';
    final formatted = ThousandsNumberInput.formatRaw(text, allowDecimal: true);
    return formatted.isEmpty ? text : formatted;
  }

  static String currencyCode(MyListingProductModel product) {
    if (_isOwner(product)) {
      final ownerCode = product.ownerCurrency.trim().toUpperCase();
      if (ownerCode.isNotEmpty) return ownerCode;
    }
    final code = product.currency.trim().toUpperCase();
    return code.isEmpty ? 'USD' : code;
  }

  /// Owner wholesale / main listing price currency (matches create-ad rules).
  static String wholesaleCurrencyCode(MyListingProductModel product) {
    if (product.isPureRetailProduct) return CreateAdCurrency.aed;
    if (product.isBookingProduct) return CreateAdCurrency.usd;
    return CreateAdCurrency.normalize(currencyCode(product));
  }

  /// Hybrid category retail price is always AED.
  static String retailCurrencyCode(MyListingProductModel product) =>
      CreateAdCurrency.aed;

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
