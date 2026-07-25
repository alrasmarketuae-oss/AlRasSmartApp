import 'package:alrasmarket/features/company/presentation/models/create_ad_type.dart';
import 'package:alrasmarket/generated/l10n.dart';
import 'package:flutter/material.dart';

enum MyAdsFilter {
  all,
  categories,
  requests,
  offers,
  booking,
  retail;

  static const String categoriesFilterKey = '__with_category__';

  String label(S s) {
    switch (this) {
      case MyAdsFilter.all:
        return s.filterAll;
      case MyAdsFilter.categories:
        return s.categories;
      case MyAdsFilter.requests:
        return s.requests;
      case MyAdsFilter.offers:
        return s.offers;
      case MyAdsFilter.booking:
        return s.booking;
      case MyAdsFilter.retail:
        return s.retail;
    }
  }

  /// `null` means no type filter (show all). English API values for matching.
  String? get productTypeName {
    switch (this) {
      case MyAdsFilter.all:
        return null;
      case MyAdsFilter.categories:
        return categoriesFilterKey;
      case MyAdsFilter.requests:
        return CreateAdType.requests.label;
      case MyAdsFilter.offers:
        return CreateAdType.offers.label;
      case MyAdsFilter.booking:
        return CreateAdType.booking.label;
      case MyAdsFilter.retail:
        return CreateAdType.retail.label;
    }
  }

  IconData get icon {
    switch (this) {
      case MyAdsFilter.all:
        return Icons.apps_rounded;
      case MyAdsFilter.categories:
        return Icons.category_outlined;
      case MyAdsFilter.requests:
        return Icons.description_outlined;
      case MyAdsFilter.offers:
        return Icons.local_offer_outlined;
      case MyAdsFilter.booking:
        return Icons.assignment_outlined;
      case MyAdsFilter.retail:
        return Icons.storefront_outlined;
    }
  }
}
