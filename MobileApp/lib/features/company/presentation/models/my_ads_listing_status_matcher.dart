import 'package:alrasmarket/core/utils/product_listing_status.dart';
import 'package:alrasmarket/features/company/data/models/my_listing_product_model.dart';
import 'package:alrasmarket/features/company/presentation/models/my_ads_listing_status_filter.dart';

/// Shared status-filter matching for My Ads (chips + cubit state).
class MyAdsListingStatusMatcher {
  MyAdsListingStatusMatcher._();

  static bool matchesApiFilter(
    MyListingProductModel product,
    String? statusFilter, {
    bool preferRetail = false,
  }) {
    if (statusFilter == null || statusFilter.isEmpty) return true;

    final filter = switch (statusFilter) {
      'active' => MyAdsListingStatusFilter.active,
      'paused' => MyAdsListingStatusFilter.paused,
      'review' => MyAdsListingStatusFilter.underReview,
      'sold_out' => MyAdsListingStatusFilter.soldOut,
      _ => MyAdsListingStatusFilter.all,
    };
    if (filter == MyAdsListingStatusFilter.all) return true;

    return ProductListingStatus.matchesFilter(
      product,
      filter,
      preferRetail: preferRetail,
    );
  }
}
