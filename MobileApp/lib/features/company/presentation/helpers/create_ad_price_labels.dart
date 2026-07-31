import 'package:alrasmarket/core/utils/product_quantity_formatter.dart';
import 'package:alrasmarket/generated/l10n.dart';

class CreateAdPriceLabels {
  CreateAdPriceLabels._();

  static String pricePerUnitLabel(S s, String unit) {
    final localizedUnit = ProductQuantityFormatter.singularUnitLabel(unit, s);
    if (localizedUnit.isEmpty) return s.pricePerUnitGeneric;
    return s.pricePerUnit(localizedUnit);
  }

  /// Tip shown next to the price label, e.g. `Price/kg` or `السعر/كجم`.
  static String priceOverSelectedUnitTip(S s, String unit) {
    final localizedUnit = ProductQuantityFormatter.singularUnitLabel(unit, s);
    if (localizedUnit.isEmpty) return '${s.price}/unit';
    return '${s.price}/$localizedUnit';
  }

  static String enterPricePerUnitHint(S s, String unit) {
    final localizedUnit = ProductQuantityFormatter.singularUnitLabel(unit, s);
    if (localizedUnit.isEmpty) return s.enterPricePerUnitGeneric;
    return s.enterPricePerUnit(localizedUnit);
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
