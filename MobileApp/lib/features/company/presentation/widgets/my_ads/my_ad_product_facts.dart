import 'package:alrasmarket/core/theme/app_fonts.dart';
import 'package:alrasmarket/core/theme/colors.dart';
import 'package:alrasmarket/core/utils/product_price_formatter.dart';
import 'package:alrasmarket/core/utils/product_quantity_formatter.dart';
import 'package:alrasmarket/core/widgets/product_price_text.dart';
import 'package:alrasmarket/features/clint/presentation/helpers/booking_price_type_label.dart';
import 'package:alrasmarket/features/clint/presentation/helpers/product_price_type_label.dart';
import 'package:alrasmarket/features/company/data/models/my_listing_product_model.dart';
import 'package:alrasmarket/features/company/presentation/models/create_ad_type.dart';
import 'package:alrasmarket/generated/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Shared product facts block for My Ads cards — same layout for every ad type:
/// price (prominent) → specs → quantity (+ currency is shown with the price).
class MyAdProductFacts extends StatelessWidget {
  const MyAdProductFacts({
    super.key,
    required this.product,
    required this.adType,
    this.preferRetail = false,
    this.compact = false,
  });

  final MyListingProductModel product;
  final CreateAdType? adType;
  final bool preferRetail;
  final bool compact;

  static double factsBlockHeight({required bool compact}) =>
      compact ? 78.h : 94.h;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final fontFamily = AppFonts.familyFor(Localizations.localeOf(context));
    final isAr = Localizations.localeOf(context).languageCode.toLowerCase() == 'ar';
    final bodySize = compact ? 10.sp : 12.sp;
    final priceSize = compact ? 14.sp : 16.sp;
    final metaHeight = compact ? 22.h : 26.h;

    final amount = ProductPriceFormatter.amount(
      product,
      preferRetail: preferRetail,
    );
    final hasPrice =
        ProductPriceFormatter.canShowPrices && amount.trim().isNotEmpty;

    final priceTypeLabel = _resolvePriceTypeLabel(isAr);
    final routeText = adType == CreateAdType.booking ? _bookingRouteText() : '';
    final showDiscount =
        adType == CreateAdType.offers && product.isDiscountActive;

    final quantityText = _quantityLabel(s);

    return SizedBox(
      height: factsBlockHeight(compact: compact),
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: compact ? 22.h : 26.h,
            width: double.infinity,
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: hasPrice
                  ? FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: AlignmentDirectional.centerStart,
                      child: ProductPriceText.unitPrice(
                        product,
                        preferRetail: preferRetail,
                        amountStyle: TextStyle(
                          color: LightColor.defaultColor,
                          fontFamily: AppFonts.cairo,
                          fontSize: priceSize,
                          fontWeight: FontWeight.w700,
                          height: 1.15,
                        ),
                        matchCurrencyToAmount: true,
                        scaleToFit: true,
                      ),
                    )
                  : Text(
                      '—',
                      style: TextStyle(
                        fontFamily: fontFamily,
                        fontSize: priceSize,
                        fontWeight: FontWeight.w700,
                        color: LightColor.greyTextColor,
                        height: 1.15,
                      ),
                    ),
            ),
          ),
          SizedBox(
            height: metaHeight,
            width: double.infinity,
            child: _SpecsRow(
              fontFamily: fontFamily,
              bodySize: bodySize,
              compact: compact,
              priceTypeLabel: priceTypeLabel,
              routeText: routeText,
              showDiscount: showDiscount,
              discountPercentage: product.discountPercentage.trim().isNotEmpty
                  ? product.discountPercentage.trim()
                  : product.discountPercentValue.toString(),
            ),
          ),
          Expanded(
            child: Align(
              alignment: AlignmentDirectional.topStart,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (quantityText.isNotEmpty)
                    Text(
                      quantityText,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: fontFamily,
                        fontSize: bodySize,
                        color: const Color.fromRGBO(107, 114, 128, 1),
                        height: 1.2,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _resolvePriceTypeLabel(bool isAr) {
    final showType = adType == CreateAdType.booking ||
        adType == CreateAdType.categories ||
        adType == CreateAdType.offers ||
        adType == CreateAdType.requests ||
        (product.categoryId != null && product.categoryId! > 0);
    if (!showType) return '';

    return adType == CreateAdType.booking
        ? BookingPriceTypeLabel.fromProduct(product)
        : ProductPriceTypeLabel.fromProduct(product, isAr: isAr);
  }

  String _bookingRouteText() {
    return [
      product.shipping.routeFromCountry.trim(),
      product.shipping.routeToCountry.trim(),
    ].where((part) => part.isNotEmpty).join(' → ');
  }

  String _quantityLabel(S s) {
    final qty = ProductQuantityFormatter.quantityWithUnit(
      quantityText: adType == CreateAdType.requests
          ? product.quantity
          : product.quantityForChannel(preferRetail: preferRetail),
      unitName: adType == CreateAdType.requests
          ? product.unitName
          : product.unitNameForChannel(preferRetail: preferRetail),
      s: s,
    );

    if (qty.isEmpty) {
      return adType == CreateAdType.requests ? s.requestedQuantity : '';
    }

    if (adType == CreateAdType.requests) {
      return '${s.requestedQuantity} $qty';
    }

    return qty;
  }
}

class _SpecsRow extends StatelessWidget {
  const _SpecsRow({
    required this.fontFamily,
    required this.bodySize,
    required this.compact,
    required this.priceTypeLabel,
    required this.routeText,
    required this.showDiscount,
    required this.discountPercentage,
  });

  final String fontFamily;
  final double bodySize;
  final bool compact;
  final String priceTypeLabel;
  final String routeText;
  final bool showDiscount;
  final String discountPercentage;

  @override
  Widget build(BuildContext context) {
    final items = <Widget>[
      if (priceTypeLabel.isNotEmpty)
        Flexible(
          fit: FlexFit.loose,
          child: _SpecChip(
            label: priceTypeLabel,
            fontFamily: fontFamily,
            compact: compact,
          ),
        ),
      if (routeText.isNotEmpty)
        Flexible(
          child: Text(
            routeText,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: fontFamily,
              fontSize: bodySize,
              color: AppColors.titleColor,
              height: 1.2,
            ),
          ),
        ),
      if (showDiscount)
        MyAdDiscountBadge(
          discountPercentage: discountPercentage,
          compact: compact,
        ),
    ];

    if (items.isEmpty) {
      return const SizedBox.shrink();
    }

    return Row(
      children: [
        for (var i = 0; i < items.length; i++) ...[
          if (i > 0) SizedBox(width: 6.w),
          items[i],
        ],
      ],
    );
  }
}

class _SpecChip extends StatelessWidget {
  const _SpecChip({
    required this.label,
    required this.fontFamily,
    required this.compact,
  });

  final String label;
  final String fontFamily;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 6.w : 8.w,
        vertical: compact ? 2.h : 3.h,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F4FD),
        borderRadius: BorderRadius.circular(6.r),
        border: Border.all(color: const Color(0xFF3A7DC5), width: 1),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontFamily: fontFamily,
          fontSize: compact ? 10.sp : 12.sp,
          fontWeight: FontWeight.w700,
          color: const Color(0xFF1E6BB8),
          height: 1.2,
        ),
      ),
    );
  }
}

class MyAdDiscountBadge extends StatelessWidget {
  const MyAdDiscountBadge({
    super.key,
    required this.discountPercentage,
    this.compact = false,
  });

  final String discountPercentage;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 6 : 8,
        vertical: compact ? 2 : 4,
      ),
      decoration: BoxDecoration(
        color: const Color.fromRGBO(249, 112, 102, 1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            discountPercentage,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white,
              fontFamily: 'Inter',
              fontSize: compact ? 12.sp : 16.sp,
              fontWeight: FontWeight.w600,
              height: 1.2,
            ),
          ),
          SizedBox(width: compact ? 2 : 5),
          Icon(
            Icons.percent,
            color: Colors.white,
            size: compact ? 12 : 15,
          ),
        ],
      ),
    );
  }
}
