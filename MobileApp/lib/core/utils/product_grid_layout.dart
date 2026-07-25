import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ProductGridLayout {
  ProductGridLayout._();

  static bool isTablet(BuildContext context) =>
      MediaQuery.sizeOf(context).shortestSide >= 600;

  static int crossAxisCount(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width >= 1100) return 4;
    if (isTablet(context)) return 3;
    return 2;
  }

  static double cardImageHeight(BuildContext context) =>
      isTablet(context) ? 130.h : 120.h;

  /// Extra image height reclaimed from the gap above the product title.
  static double cardImageBottomReveal(BuildContext context) =>
      isTablet(context) ? 10.h : 8.h;

  static double cardImageDisplayHeight(BuildContext context) =>
      cardImageHeight(context) + cardImageBottomReveal(context);

  static double cardContentPaddingVertical(BuildContext context) =>
      isTablet(context) ? 10.h : 8.h;

  static double cardContentTopPadding(BuildContext context) {
    final vertical = cardContentPaddingVertical(context);
    final reveal = cardImageBottomReveal(context);
    return (vertical - reveal).clamp(0.0, vertical);
  }

  static EdgeInsets cardContentInsets(BuildContext context) => EdgeInsets.fromLTRB(
        10.w,
        cardContentTopPadding(context),
        10.w,
        cardContentPaddingVertical(context),
      );

  static Color productCardTitleColor(BuildContext context) =>
      const Color(0xFF3A7DC5);

  /// Kept for compatibility; marketplace cards no longer reserve a discount band.
  static double discountBandHeight(BuildContext context) => 0;

  static double cardTitleFontSize(BuildContext context) =>
      isTablet(context) ? 16.5.sp : 15.5.sp;

  static double cardDetailsFontSize(BuildContext context) =>
      isTablet(context) ? 11.5.sp : 11.sp;

  static double cardPriceFontSize(BuildContext context) =>
      isTablet(context) ? 16.sp : 15.sp;

  static double titleBlockHeight(BuildContext context) {
    final fontSize = cardTitleFontSize(context);
    return fontSize * 1.25 * 2;
  }

  static double detailsBlockHeight(BuildContext context) {
    final fontSize = cardDetailsFontSize(context);
    return fontSize * 1.35 * 2;
  }

  static double priceBlockHeight(BuildContext context) {
    final fontSize = cardPriceFontSize(context);
    return fontSize * 1.25 + (isTablet(context) ? 6.h : 4.h);
  }

  static double postedAtBlockHeight(BuildContext context) =>
      isTablet(context) ? 34.h : 32.h;

  static double quantityBlockHeight(BuildContext context) {
    final fontSize = cardDetailsFontSize(context);
    return fontSize * 1.2 + 6.h;
  }

  /// Discount % + countdown row on offer cards.
  static double offerDealBandHeight(BuildContext context) =>
      isTablet(context) ? 24.h : 22.h;

  static double offerTimerBlockHeight(BuildContext context) =>
      isTablet(context) ? 22.h : 20.h;

  static double offerPriceBlockHeight(BuildContext context) {
    return priceBlockHeight(context);
  }

  /// Offer cards share the marketplace layout plus a deal/countdown row.
  static double estimatedOfferCardHeight(BuildContext context) {
    return estimatedCardHeight(context) +
        offerDealBandHeight(context) +
        offerTimerBlockHeight(context) +
        8.h;
  }

  static double offerChildAspectRatioFor(
    BuildContext context, {
    required double horizontalPadding,
    required double crossAxisSpacing,
  }) {
    final width = cellWidth(
      context,
      horizontalPadding: horizontalPadding,
      crossAxisSpacing: crossAxisSpacing,
    );
    final height = estimatedOfferCardHeight(context);
    if (height <= 0) {
      return isTablet(context) ? 0.52 : 157 / 268;
    }
    return width / height;
  }

  static int offerCrossAxisCount(BuildContext context) =>
      crossAxisCount(context);

  static SliverGridDelegateWithFixedCrossAxisCount offerDelegate(
    BuildContext context, {
    required double horizontalPadding,
    double? crossAxisSpacing,
    double? mainAxisSpacing,
  }) {
    final cross = crossAxisSpacing ?? 12.w;
    final main = mainAxisSpacing ?? 12.h;
    return SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: offerCrossAxisCount(context),
      crossAxisSpacing: cross,
      mainAxisSpacing: main,
      childAspectRatio: offerChildAspectRatioFor(
        context,
        horizontalPadding: horizontalPadding,
        crossAxisSpacing: cross,
      ),
    );
  }

  /// Total card height used to size grid cells and avoid clipping on tablet.
  static double estimatedCardHeight(BuildContext context) {
    return cardImageDisplayHeight(context) +
        cardContentPaddingVertical(context) * 2 +
        titleBlockHeight(context) +
        4.h +
        detailsBlockHeight(context) +
        8.h +
        1 + // divider above price
        8.h +
        priceBlockHeight(context) +
        quantityBlockHeight(context) +
        (isTablet(context) ? 8.h : 4.h);
  }

  static double cellWidth(
    BuildContext context, {
    required double horizontalPadding,
    required double crossAxisSpacing,
    int? columns,
  }) {
    final width = MediaQuery.sizeOf(context).width;
    final cols = columns ?? crossAxisCount(context);
    final spacing = (cols - 1) * crossAxisSpacing;
    return (width - horizontalPadding - spacing) / cols;
  }

  static double childAspectRatioFor(
    BuildContext context, {
    required double horizontalPadding,
    required double crossAxisSpacing,
  }) {
    final width = cellWidth(
      context,
      horizontalPadding: horizontalPadding,
      crossAxisSpacing: crossAxisSpacing,
    );
    final height = estimatedCardHeight(context);
    if (height <= 0) {
      return isTablet(context) ? 0.52 : 157 / 268;
    }
    return width / height;
  }

  /// Grid delegate sized to the page's real padding/spacing so cards are not clipped.
  static SliverGridDelegateWithFixedCrossAxisCount delegate(
    BuildContext context, {
    required double horizontalPadding,
    double? crossAxisSpacing,
    double? mainAxisSpacing,
  }) {
    final cross = crossAxisSpacing ?? 12.w;
    final main = mainAxisSpacing ?? 12.h;
    return SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: crossAxisCount(context),
      crossAxisSpacing: cross,
      mainAxisSpacing: main,
      childAspectRatio: childAspectRatioFor(
        context,
        horizontalPadding: horizontalPadding,
        crossAxisSpacing: cross,
      ),
    );
  }

  /// Home products section: parent uses [EdgeInsets.symmetric(horizontal: 24)].
  static double homeHorizontalPadding(BuildContext context) => 48.0;

  /// Category / search pages: [EdgeInsets.fromLTRB(24.w, …, 24.w, …)].
  static double categoryHorizontalPadding(BuildContext context) => 48.w;

  /// Retail service grid: [EdgeInsets.fromLTRB(16.w, …, 16.w, …)].
  static double retailHorizontalPadding(BuildContext context) => 32.w;
}
