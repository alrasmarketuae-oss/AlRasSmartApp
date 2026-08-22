import 'package:alrasmarket/core/utils/product_stock.dart';
import 'package:alrasmarket/features/company/data/models/my_listing_product_model.dart';
import 'package:alrasmarket/features/company/presentation/models/my_ads_listing_status_filter.dart';

/// Mirrors backend [ProductStatusCodes.Normalize]:
/// Under Review (1) → Active (2) → Paused (3) | Rejected (5); legacy 4 → Under Review.
class ProductListingStatus {
  ProductListingStatus._();

  static const int underReview = 1;
  static const int active = 2;
  static const int paused = 3;
  static const int rejected = 5;

  static int normalize({
    int? rawStatusCode,
    bool? isApproved,
    String? statusNameEn,
  }) {
    if (rawStatusCode != null && rawStatusCode > 0) {
      return _normalizeRaw(rawStatusCode, isApproved: isApproved);
    }
    return _normalizeFromCanonical(statusNameEn, isApproved: isApproved);
  }

  static int normalizedFor(MyListingProductModel product) => normalize(
        rawStatusCode: product.listingStatusCode,
        isApproved: product.isListingApproved,
        statusNameEn: product.statusNameEn,
      );

  static bool matchesFilter(
    MyListingProductModel product,
    MyAdsListingStatusFilter filter, {
    bool preferRetail = false,
  }) {
    final code = normalizedFor(product);
    final soldOut = ProductStock.isSoldOut(
      product,
      preferRetail: preferRetail,
    );

    switch (filter) {
      case MyAdsListingStatusFilter.all:
        return true;
      case MyAdsListingStatusFilter.active:
        return code == active && !soldOut;
      case MyAdsListingStatusFilter.paused:
        // Seller-paused only — sold-out listings belong under Sold out.
        return code == paused && !soldOut;
      case MyAdsListingStatusFilter.underReview:
        return code == underReview;
      case MyAdsListingStatusFilter.soldOut:
        return soldOut;
    }
  }

  static int _normalizeRaw(int raw, {bool? isApproved}) {
    switch (raw) {
      case active:
        return active;
      case paused:
        return paused;
      case rejected:
        return rejected;
      case 4:
        return underReview;
      case underReview:
        return isApproved == true ? active : underReview;
      default:
        return underReview;
    }
  }

  static int _normalizeFromCanonical(String? statusNameEn, {bool? isApproved}) {
    final value = (statusNameEn ?? '').trim().toLowerCase();
    if (value == 'active' || value.contains('نشط')) {
      return active;
    }
    if (value == 'paused' || value.contains('متوقف')) {
      return paused;
    }
    if (value == 'rejected' || value.contains('مرفوض')) {
      return rejected;
    }
    if (value.contains('review') || value.contains('مراجع')) {
      return isApproved == true ? active : underReview;
    }
    return underReview;
  }
}
