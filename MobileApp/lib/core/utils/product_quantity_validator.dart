import 'package:alrasmarket/core/utils/thousands_separator_input_formatter.dart';
import 'package:alrasmarket/features/company/data/models/my_listing_product_model.dart';
import 'package:alrasmarket/generated/l10n.dart';

class ProductQuantityValidator {
  ProductQuantityValidator._();

  static double? _parseQuantity(String? raw) =>
      ThousandsNumberInput.parseDouble(raw);

  static String _format(double quantity) {
    if (quantity == quantity.roundToDouble()) {
      return quantity.toInt().toString();
    }
    return quantity.toString();
  }

  static String? validateRequiredField(String? rawValue, S s) {
    if (rawValue == null || rawValue.trim().isEmpty) {
      return s.thisFieldIsRequired;
    }
    final quantity = _parseQuantity(rawValue);
    if (quantity == null || quantity <= 0) {
      return s.enterValidQuantity;
    }
    return null;
  }

  static String? validateRetailOrderQuantity({
    required String? rawValue,
    required S s,
    required MyListingProductModel product,
  }) {
    final requiredError = validateRequiredField(rawValue, s);
    if (requiredError != null) return requiredError;

    final quantity = _parseQuantity(rawValue)!;
    final available = _parseQuantity(product.quantity) ?? 0;
    if (available > 0 && quantity > available) {
      return s.requestedQuantityExceedsAvailable(
        _format(quantity),
        _format(available),
      );
    }

    final maxOrder = _parseQuantity(product.maximumOrderQuantity) ?? 0;
    if (maxOrder > 0 && quantity > maxOrder) {
      return s.maximumOrderQuantityIs(_format(maxOrder));
    }

    final minOrder = _parseQuantity(product.minimumOrderQuantity) ?? 0;
    if (minOrder > 0 && quantity < minOrder) {
      return s.minimumOrderQuantityIs(_format(minOrder));
    }

    return null;
  }

  /// Validates offer quantity on a Request ad.
  /// Offered quantity may be greater than the requested quantity.
  static String? validateOfferAgainstRequiredQuantity({
    required String? rawValue,
    required S s,
    required MyListingProductModel requestProduct,
    String? offerUnit,
  }) {
    // Request offers can exceed the buyer's stated quantity — only require a
    // positive amount. [requestProduct] / [offerUnit] kept for call-site compatibility.
    return validateRequiredField(rawValue, s);
  }
}
