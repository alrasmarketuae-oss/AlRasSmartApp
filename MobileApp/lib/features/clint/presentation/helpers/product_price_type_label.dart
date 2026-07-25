import 'package:alrasmarket/features/company/data/models/my_listing_product_model.dart';
import 'package:alrasmarket/features/company/presentation/models/request_fulfillment_type.dart';

/// Local / Rexport from backend `requestTypeId` / `requestTypeName`.
///
/// Required for Offers, Requests, and Categories — not Booking or Retail.
class ProductPriceTypeLabel {
  ProductPriceTypeLabel._();

  /// Offers / Requests / Categories (not Booking, not pure Retail).
  static bool appliesTo(MyListingProductModel product) {
    if (product.isOfferProduct || product.isRequestProduct) return true;
    if (product.isCategoryCatalogProduct) return true;
    final type = product.productTypeName.trim().toLowerCase();
    final id = product.productTypeId;
    if (id == 1 || type == 'retail') return false;
    if (id == 2 || type == 'booking') return false;
    if (type == 'offers' || type == 'requests' || type == 'categories') {
      return true;
    }
    return false;
  }

  static String fromProduct(MyListingProductModel product, {required bool isAr}) {
    final fromId = _fromId(product.requestTypeId, isAr: isAr);
    if (fromId.isNotEmpty) return fromId;

    final fromName = _fromKnownValue(product.requestTypeName, isAr: isAr);
    if (fromName.isNotEmpty) return fromName;

    // Legacy ads stored Local / Booking / Reexport in shipping description.
    return _fromKnownValue(product.shippingDescriptionEn, isAr: isAr);
  }

  /// Label for UI: resolves Local/Rexport; empty if unset.
  static String fromRaw(String? raw, {required bool isAr}) =>
      _fromKnownValue(raw, isAr: isAr);

  static String _fromId(int? id, {required bool isAr}) {
    if (id == 1) return isAr ? 'محلي' : 'Local';
    if (id == 2) return isAr ? 'إعادة تصدير' : 'Rexport';
    return '';
  }

  static String _fromKnownValue(String? raw, {required bool isAr}) {
    final value = (raw ?? '').trim();
    if (value.isEmpty) return '';

    final parsed = RequestFulfillmentType.fromApiValue(value);
    if (parsed == RequestFulfillmentType.local) {
      return isAr ? 'محلي' : 'Local';
    }
    if (parsed == RequestFulfillmentType.reexport) {
      return isAr ? 'إعادة تصدير' : 'Rexport';
    }

    final lower = value.toLowerCase().replaceAll('_', ' ').replaceAll('-', ' ');
    final compact = lower.replaceAll(RegExp(r'\s+'), '');

    if (compact == '1' || lower == 'local' || lower == 'محلي' || compact == 'local') {
      return isAr ? 'محلي' : 'Local';
    }
    if (compact == '2' ||
        compact == 'reexport' ||
        compact == 'rexport' ||
        lower == 'export' ||
        lower == 'booking' ||
        lower == 'إعادة تصدير' ||
        lower == 'اعادة تصدير' ||
        compact.contains('reexport') ||
        compact.contains('rexport') ||
        lower.contains('إعادة تصدير') ||
        lower.contains('اعادة تصدير')) {
      return isAr ? 'إعادة تصدير' : 'Rexport';
    }
    // Whole-word "local" (avoid matching random shipping notes wrongly).
    if (RegExp(r'(^|\s)local(\s|$)').hasMatch(lower)) {
      return isAr ? 'محلي' : 'Local';
    }
    return '';
  }
}
