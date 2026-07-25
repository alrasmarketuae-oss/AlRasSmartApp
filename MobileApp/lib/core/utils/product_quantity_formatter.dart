import 'package:alrasmarket/features/company/data/models/my_listing_product_model.dart';
import 'package:alrasmarket/generated/l10n.dart';

class ProductQuantityFormatter {
  ProductQuantityFormatter._();

  static String availableQuantityLabel(MyListingProductModel product, S s) {
    final qtyText = product.quantity.trim();
    if (qtyText.isEmpty) return '';

    final qty = double.tryParse(qtyText.replaceAll(',', ''));
    if (qty != null && qty <= 0) {
      return s.soldOut;
    }

    final resolvedQty = qty ?? 1;
    final unit = _displayUnit(product.unitName.trim(), resolvedQty, s);
    return '${s.availableQuantity}: $qtyText $unit';
  }

  static String quantityWithUnit({
    required String quantityText,
    required String unitName,
    required S s,
  }) {
    final qtyText = quantityText.trim();
    if (qtyText.isEmpty && unitName.trim().isEmpty) return '';

    final qty = double.tryParse(qtyText.replaceAll(',', '')) ?? 1;
    final unit = _displayUnit(unitName.trim(), qty, s);
    if (qtyText.isEmpty) return unit;
    if (unit.isEmpty) return qtyText;
    return '$qtyText $unit';
  }

  static String minimumOrderLabel(MyListingProductModel product, S s) {
    final qtyText = product.minimumOrderQuantity.trim().isNotEmpty
        ? product.minimumOrderQuantity.trim()
        : product.quantity.trim();
    final unitName = product.unitName.trim();
    if (qtyText.isEmpty && unitName.isEmpty) return '${s.minimumOrder}: —';

    final qty = double.tryParse(qtyText.replaceAll(',', '')) ?? 1;
    final unit = _displayUnit(unitName, qty, s);
    return '${s.minimumOrder}: $qtyText${unit.isNotEmpty ? ' $unit' : ''}';
  }

  /// Always show short client-facing labels (e.g. Kilogram → kg), never full DB names.
  static String compactUnitLabel(String unitName, {S? s}) {
    switch (unitName.trim().toLowerCase()) {
      case 'kilogram':
      case 'kilograms':
      case 'kg':
      case 'kgs':
      case 'kilo':
      case 'kilos':
      case 'كجم':
      case 'كيلو':
      case 'كيلوجرام':
        return s?.unitKg ?? 'kg';
      case 'gram':
      case 'grams':
      case 'g':
      case 'جرام':
      case 'غرام':
        return s?.unitGram ?? 'Gram';
      case 'ton':
      case 'tons':
      case 'tonne':
      case 'tonnes':
      case 'طن':
      case 'اطنان':
      case 'أطنان':
        return s?.unitTon ?? 'Ton';
      default:
        return unitName.trim();
    }
  }

  /// Localized singular unit label for create-ad price fields (e.g. Ton, Kg).
  static String singularUnitLabel(String unitName, S s) {
    return _displayUnit(unitName.trim(), 1, s);
  }

  static bool _hasArabicScript(String value) {
    for (final code in value.runes) {
      if (code >= 0x0600 && code <= 0x06FF) return true;
    }
    return false;
  }

  static String _displayUnit(String unitName, double quantity, S s) {
    if (unitName.isEmpty) return '';
    final plural = quantity.abs() != 1;
    final normalized = unitName.trim().toLowerCase();

    switch (normalized) {
      case 'dozen':
      case 'dozens':
        return plural ? s.unitDozens : s.unitDozen;
      case 'kilogram':
      case 'kilograms':
      case 'kg':
      case 'kgs':
      case 'kilo':
      case 'kilos':
      case 'كجم':
      case 'كيلو':
      case 'كيلوجرام':
        // Always short form for customers (never "Kilogram" / "كيلوجرام").
        return s.unitKg;
      case 'ton':
      case 'tons':
      case 'tonne':
      case 'tonnes':
      case 'طن':
      case 'اطنان':
      case 'أطنان':
        return plural ? s.unitTons : s.unitTon;
      case 'gram':
      case 'grams':
      case 'g':
      case 'جرام':
      case 'غرام':
        return plural ? s.unitGrams : s.unitGram;
      case 'box':
      case 'boxes':
      case 'صندوق':
      case 'صناديق':
        return plural ? s.unitBoxes : s.unitBox;
      case 'piece':
      case 'pieces':
      case 'pcs':
      case 'pc':
      case 'قطعة':
      case 'قطع':
        return plural ? s.unitPieces : s.unitPiece;
      case 'liter':
      case 'liters':
      case 'litre':
      case 'litres':
      case 'لتر':
      case 'لترات':
        return plural ? s.unitLiters : s.unitLiter;
      case 'carton':
      case 'cartons':
      case 'كرتون':
        return s.unitCarton;
      case 'bag':
      case 'bags':
      case 'كيس':
      case 'أكياس':
        return s.unitBag;
      default:
        // Never append English "s" to Arabic (or other non-Latin) unit labels.
        if (_hasArabicScript(unitName)) return unitName;
        if (!plural) return unitName;
        if (normalized.endsWith('s')) return unitName;
        return '${unitName}s';
    }
  }
}
