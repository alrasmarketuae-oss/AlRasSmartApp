import 'package:alrasmarket/features/company/data/models/my_listing_product_model.dart';
import 'package:alrasmarket/features/company/presentation/models/booking_price_type.dart';

/// FOB / CNF / CIF for Booking ads from API bookingPriceType fields.
class BookingPriceTypeLabel {
  BookingPriceTypeLabel._();

  static bool appliesTo(MyListingProductModel product) {
    final typeId = product.productTypeId;
    if (typeId == 2) return true;
    return product.productTypeName.trim().toLowerCase() == 'booking';
  }

  static String fromProduct(MyListingProductModel product) {
    final name = product.bookingPriceTypeName.trim();
    if (name.isNotEmpty) return name.toUpperCase();

    final fromId = BookingPriceType.fromId(product.bookingPriceTypeId);
    if (fromId != null) return fromId.apiValue;

    return '';
  }
}
