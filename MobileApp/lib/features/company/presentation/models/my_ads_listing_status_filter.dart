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

  bool matches(MyListingProductModel product) {
    final status = product.statusCanonical.toLowerCase();
    switch (this) {
      case MyAdsListingStatusFilter.all:
        return true;
      case MyAdsListingStatusFilter.active:
        return (status == 'active' || status.contains('نشط')) &&
            !ProductStock.isSoldOut(product);
      case MyAdsListingStatusFilter.paused:
        return status.contains('paused') ||
            status.contains('inactive') ||
            status.contains('متوقف');
      case MyAdsListingStatusFilter.underReview:
        return status.contains('review') || status.contains('مراجع');
      case MyAdsListingStatusFilter.soldOut:
        return ProductStock.isSoldOut(product) ||
            status.contains('sold') ||
            status.contains('out of stock') ||
            status.contains('نفد');
    }
  }

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
