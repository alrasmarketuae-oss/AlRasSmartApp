import 'package:alrasmarket/core/utils/product_quantity_formatter.dart';
import 'package:alrasmarket/generated/l10n.dart';

class CreateAdPriceLabels {
  CreateAdPriceLabels._();

  static String pricePerUnitLabel(S s, String unit) {
    final localizedUnit = ProductQuantityFormatter.singularUnitLabel(unit, s);
    if (localizedUnit.isEmpty) return s.pricePerUnitGeneric;
    return s.pricePerUnit(localizedUnit);
  }

  static String quantityPerUnitLabel(S s, String unit) {
    final localizedUnit = ProductQuantityFormatter.singularUnitLabel(unit, s);
    if (localizedUnit.isEmpty) return s.quantityPerUnitGeneric;
    return s.quantityPerUnit(localizedUnit);
  }

  static String requiredQuantityPerUnitLabel(S s, String unit) {
    final localizedUnit = ProductQuantityFormatter.singularUnitLabel(unit, s);
    if (localizedUnit.isEmpty) return s.requiredQuantity;
    return s.requiredQuantityPerUnit(localizedUnit);
  }

  /// Tip shown next to the price label, e.g. `Price/kg` or `السعر/كجم`.
  static String priceOverSelectedUnitTip(S s, String unit) {
    final localizedUnit = ProductQuantityFormatter.singularUnitLabel(unit, s);
    if (localizedUnit.isEmpty) return '${s.price}/unit';
    return '${s.price}/$localizedUnit';
  }

  /// Short field hint, e.g. `Price/kg` or `السعر/كجم` — fits AR/EN without overflow.
  static String enterPricePerUnitHint(S s, String unit) {
    return priceOverSelectedUnitTip(s, unit);
  }

  static String targetPricePerUnitLabel(S s, String unit) {
    final localizedUnit = ProductQuantityFormatter.singularUnitLabel(unit, s);
    if (localizedUnit.isEmpty) return s.targetPricePerUnitGeneric;
    return s.targetPricePerUnit(localizedUnit);
  }

  static String offerPricePerUnitLabel(S s, String unit) {
    final localizedUnit = ProductQuantityFormatter.singularUnitLabel(unit, s);
    if (localizedUnit.isEmpty) return s.pricePerUnitGeneric;
    return s.offerPricePerUnit(localizedUnit);
  }
}
