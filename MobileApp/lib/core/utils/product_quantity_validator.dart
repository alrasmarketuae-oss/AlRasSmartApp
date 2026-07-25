import 'package:alrasmarket/features/company/presentation/helpers/create_ad_form_mapper.dart';
import 'package:alrasmarket/features/company/data/models/my_listing_product_model.dart';
import 'package:alrasmarket/generated/l10n.dart';

class ProductQuantityValidator {
  ProductQuantityValidator._();

  static double? _parseQuantity(String? raw) {
    if (raw == null) return null;
    final trimmed = raw.replaceAll(',', '').trim();
    if (trimmed.isEmpty) return null;
    return double.tryParse(trimmed);
  }

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

  static String? validateOfferAgainstRequiredQuantity({
    required String? rawValue,
    required S s,
    required MyListingProductModel requestProduct,
    String? offerUnit,
  }) {
    final requiredError = validateRequiredField(rawValue, s);
    if (requiredError != null) return requiredError;

    final quantity = _parseQuantity(rawValue)!;
    final requiredQuantity = _parseQuantity(requestProduct.quantity) ?? 0;
    if (requiredQuantity > 0 && quantity > requiredQuantity) {
      final requestUnit = requestProduct.unitName.trim();
      final submittedUnit = (offerUnit ?? requestUnit).trim();
      if (requestUnit.isEmpty ||
          _unitsMatch(submittedUnit, requestUnit)) {
        return s.quantityExceedsRequired(_format(requiredQuantity));
      }
    }

    return null;
  }

  static bool _unitsMatch(String a, String b) {
    if (a.isEmpty || b.isEmpty) return true;
    return CreateAdFormMapper.mapUnitName(a) == CreateAdFormMapper.mapUnitName(b);
  }
}
