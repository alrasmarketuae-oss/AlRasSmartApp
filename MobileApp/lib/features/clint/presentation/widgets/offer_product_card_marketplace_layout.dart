import 'dart:async';

import 'package:alrasmarket/core/theme/app_fonts.dart';
import 'package:alrasmarket/core/utils/product_grid_layout.dart';
import 'package:alrasmarket/core/utils/product_price_formatter.dart';
import 'package:alrasmarket/core/utils/product_stock.dart';
import 'package:alrasmarket/core/utils/thousands_separator_input_formatter.dart';
import 'package:alrasmarket/core/widgets/currency_icon.dart';
import 'package:alrasmarket/core/widgets/product_posted_at_text.dart';
import 'package:alrasmarket/core/widgets/product_price_text.dart';
import 'package:alrasmarket/features/company/data/models/my_listing_product_model.dart';
import 'package:alrasmarket/generated/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class OfferProductCardMarketplaceLayout extends StatefulWidget {
  const OfferProductCardMarketplaceLayout({
    super.key,
    required this.product,
    this.title,
    this.fillHeight = false,
  });

  final MyListingProductModel product;
  final String? title;
  final bool fillHeight;

  @override
  State<OfferProductCardMarketplaceLayout> createState() =>
      _OfferProductCardMarketplaceLayoutState();
}

class _OfferProductCardMarketplaceLayoutState
    extends State<OfferProductCardMarketplaceLayout> {
  Timer? _timer;
  Duration _remaining = Duration.zero;
  bool _dealActive = false;

  @override
  void initState() {
    super.initState();
    _syncCountdown();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      _syncCountdown();
    });
  }

  @override
  void didUpdateWidget(covariant OfferProductCardMarketplaceLayout oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.product.productId != widget.product.productId) {
      _syncCountdown();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _syncCountdown() {
    final product = widget.product;
    setState(() {
      _dealActive = product.isDiscountActive && product.discountPercentValue > 0;
      _remaining = product.discountRemaining ?? Duration.zero;
    });
  }

  String _countdownText() {
    if (_remaining.inSeconds <= 0) return '00:00:00';
    final days = _remaining.inDays;
    final hours = _remaining.inHours.remainder(24).toString().padLeft(2, '0');
    final minutes =
        _remaining.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds =
        _remaining.inSeconds.remainder(60).toString().padLeft(2, '0');
    if (days > 0) {
      return '${days}d $hours:$minutes:$seconds';
    }
    return '$hours:$minutes:$seconds';
  }

  String _formatAmount(double value) {
    return ThousandsNumberInput.format(value, allowDecimal: true);
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final fontFamily = AppFonts.familyFor(Localizations.localeOf(context));
    final product = widget.product;
    final displayTitle = (widget.title ?? product.productName).trim();
    final soldOut = ProductStock.isSoldOut(product);
    final details = soldOut ? s.soldOut : product.description.trim();
    final discount = product.discountPercentValue;
    final showDeal = _dealActive && discount > 0 && product.salePriceValue > 0;
    final showTimer = showDeal && product.discountDaysValue > 0;
    final currency = ProductPriceFormatter.currencyCode(product);
    final sale = product.salePriceValue;
    final original = product.originalPriceValue;
    final displayPrice = showDeal ? sale : (original > 0 ? original : sale);
    final titleFontSize = ProductGridLayout.cardTitleFontSize(context);
    final detailsFontSize = ProductGridLayout.cardDetailsFontSize(context);
    final priceFontSize = ProductGridLayout.cardPriceFontSize(context);
    final isTablet = ProductGridLayout.isTablet(context);
    final smallPriceFontSize = isTablet ? 11.5.sp : 11.sp;

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: ProductGridLayout.offerDealBandHeight(context),
          child: showDeal
              ? Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF0F0),
                    borderRadius: BorderRadius.circular(6.r),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          s.limitedTimeDeal,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: fontFamily,
                            fontSize: isTablet ? 10.5.sp : 10.sp,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFFCC0C39),
                          ),
                        ),
                      ),
                      SizedBox(width: 6.w),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 6.w,
                          vertical: 2.h,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFCC0C39),
                          borderRadius: BorderRadius.circular(4.r),
                        ),
                        child: Text(
                          '-$discount%',
                          style: TextStyle(
                            fontFamily: fontFamily,
                            fontSize: 10.sp,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              : null,
        ),
        SizedBox(
          height: ProductGridLayout.titleBlockHeight(context),
          width: double.infinity,
          child: Text(
            displayTitle.isEmpty ? 'Product' : displayTitle,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: fontFamily,
              fontSize: titleFontSize,
              fontWeight: FontWeight.w700,
              color: ProductGridLayout.productCardTitleColor(context),
              height: 1.25,
            ),
          ),
        ),
        SizedBox(
          height: ProductGridLayout.detailsBlockHeight(context),
          width: double.infinity,
          child: Text(
            details,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: fontFamily,
              fontSize: detailsFontSize,
              fontWeight: soldOut ? FontWeight.w700 : FontWeight.w400,
              color: soldOut
                  ? const Color(0xFFDC2626)
                  : const Color(0xFF6B7280),
              height: 1.35,
            ),
          ),
        ),
        if (widget.fillHeight) const Spacer(),
        if (ProductPriceFormatter.canShowPrices)
          SizedBox(
            height: ProductGridLayout.offerPriceBlockHeight(context),
            width: double.infinity,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (showDeal && original > sale) ...[
                  Align(
                    alignment: Alignment.bottomLeft,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            _formatAmount(original),
                            style: TextStyle(
                              fontFamily: fontFamily,
                              fontSize: smallPriceFontSize,
                              color: const Color(0xFF565959),
                              decoration: TextDecoration.lineThrough,
                              decorationColor: const Color(0xFF565959),
                              height: 1.1,
                            ),
                          ),
                          SizedBox(width: 4.w),
                          CurrencyIcon(
                            currency: currency,
                            size: smallPriceFontSize,
                            matchTextSize: true,
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 3.h),
                ],
                Align(
                  alignment: Alignment.bottomLeft,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: ProductPriceText(
                      amount: _formatAmount(displayPrice),
                      currency: currency,
                      suffix: ProductPriceFormatter.unitSuffix(product),
                      amountStyle: TextStyle(
                        fontFamily: fontFamily,
                        fontSize: priceFontSize,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF619D50),
                        height: 1.1,
                      ),
                      iconSize: priceFontSize,
                      matchCurrencyToAmount: true,
                      scaleToFit: true,
                    ),
                  ),
                ),
              ],
            ),
          ),
        SizedBox(
          height: ProductGridLayout.offerTimerBlockHeight(context),
          child: showTimer
              ? Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: AlignmentDirectional.centerStart,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.timer_outlined,
                          size: isTablet ? 15.sp : 14.sp,
                          color: const Color(0xFFCC0C39),
                        ),
                        SizedBox(width: 4.w),
                        Text(
                          _countdownText(),
                          maxLines: 1,
                          style: TextStyle(
                            fontFamily: fontFamily,
                            fontSize: isTablet ? 12.sp : 11.5.sp,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFFCC0C39),
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : null,
        ),
        if (product.createdAt.trim().isNotEmpty) ...[
          SizedBox(height: 2.h),
          SizedBox(
            height: ProductGridLayout.postedAtBlockHeight(context),
            width: double.infinity,
            child: ProductPostedAtText(
              createdAt: product.createdAt,
              fontFamily: fontFamily,
              fontSize: detailsFontSize,
            ),
          ),
        ],
      ],
    );

    if (widget.fillHeight) {
      return SizedBox(width: double.infinity, child: content);
    }

    return content;
  }
}
