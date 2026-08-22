import 'package:alrasmarket/core/utils/product_listing_status.dart';
import 'package:alrasmarket/core/utils/product_stock.dart';
import 'package:alrasmarket/features/company/data/models/my_listing_product_model.dart';
import 'package:alrasmarket/generated/l10n.dart';
import 'package:flutter/material.dart';

enum MyAdsListingStatusFilter {
  all,
  active,
  paused,
  underReview,
  soldOut;

  String label(S s) {
    switch (this) {
      case MyAdsListingStatusFilter.all:
        return s.filterAll;
      case MyAdsListingStatusFilter.active:
        return s.listingActive;
      case MyAdsListingStatusFilter.paused:
        return s.listingPaused;
      case MyAdsListingStatusFilter.underReview:
        return s.underReviewAds;
      case MyAdsListingStatusFilter.soldOut:
        return s.soldOut;
    }
  }

  bool matches(
    MyListingProductModel product, {
    bool preferRetail = false,
  }) =>
      ProductListingStatus.matchesFilter(
        product,
        this,
        preferRetail: preferRetail,
      );

  IconData get icon {
    switch (this) {
      case MyAdsListingStatusFilter.all:
        return Icons.apps_rounded;
      case MyAdsListingStatusFilter.active:
        return Icons.check_circle_outline_rounded;
      case MyAdsListingStatusFilter.paused:
        return Icons.pause_circle_outline_rounded;
      case MyAdsListingStatusFilter.underReview:
        return Icons.hourglass_top_rounded;
      case MyAdsListingStatusFilter.soldOut:
        return Icons.cancel_outlined;
    }
  }

  /// Outline / fill accent for Account status chips.
  Color get accentColor {
    switch (this) {
      case MyAdsListingStatusFilter.all:
        return const Color(0xFF3A7DC5);
      case MyAdsListingStatusFilter.active:
        return const Color(0xFF22A06B);
      case MyAdsListingStatusFilter.paused:
        return const Color(0xFFE67E22);
      case MyAdsListingStatusFilter.underReview:
        return const Color(0xFF7C5CFC);
      case MyAdsListingStatusFilter.soldOut:
        return const Color(0xFFE53935);
    }
  }
}

/// Badge labels derived from normalized listing status codes.
class MyAdsListingStatusPresentation {
  MyAdsListingStatusPresentation._();

  static String labelFor(MyListingProductModel product, S s) {
    if (ProductStock.isSoldOut(product)) return s.soldOut;
    if (ProductListingStatus.isSellerPaused(product)) return s.listingPaused;
    switch (ProductListingStatus.normalizedFor(product)) {
      case ProductListingStatus.active:
        return s.listingActive;
      case ProductListingStatus.paused:
        return s.listingActive;
      case ProductListingStatus.rejected:
        return s.rejectedAds;
      case ProductListingStatus.underReview:
        return s.underReviewAds;
      default:
        final value = product.statusCanonical.trim();
        return value.isEmpty ? '—' : value;
    }
  }
}
