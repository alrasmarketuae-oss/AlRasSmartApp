import 'dart:async';
import 'dart:math' as math;

import 'package:alrasmarket/core/theme/app_fonts.dart';
import 'package:alrasmarket/core/theme/colors.dart';
import 'package:alrasmarket/core/utils/product_grid_layout.dart';
import 'package:alrasmarket/core/utils/product_price_formatter.dart';
import 'package:alrasmarket/core/utils/product_quantity_formatter.dart';
import 'package:alrasmarket/core/utils/product_stock.dart';
import 'package:alrasmarket/core/utils/string_display_format.dart';
import 'package:alrasmarket/core/utils/thousands_separator_input_formatter.dart';
import 'package:alrasmarket/core/widgets/currency_icon.dart';
import 'package:alrasmarket/core/widgets/product_price_text.dart';
import 'package:alrasmarket/features/clint/presentation/helpers/booking_price_type_label.dart';
import 'package:alrasmarket/features/clint/presentation/helpers/product_price_type_label.dart';
import 'package:alrasmarket/features/clint/presentation/widgets/product_card_theme.dart';
import 'package:alrasmarket/features/company/data/models/my_listing_product_model.dart';
import 'package:alrasmarket/generated/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Marketplace card body matching the unified product-card design.
class ProductCardMarketplaceLayout extends StatefulWidget {
  const ProductCardMarketplaceLayout({
    super.key,
    required this.product,
    this.title,
    this.fillHeight = false,
    this.theme,
    this.showOfferExtras = false,
    this.showSubjectToReconfirm = true,
  });

  final MyListingProductModel product;
  final String? title;
  final bool fillHeight;
  final ProductCardTheme? theme;
  final bool showOfferExtras;
  final bool showSubjectToReconfirm;

  @override
  State<ProductCardMarketplaceLayout> createState() =>
      _ProductCardMarketplaceLayoutState();
}

class _ProductCardMarketplaceLayoutState
    extends State<ProductCardMarketplaceLayout> {
  Timer? _timer;
  Duration _remaining = Duration.zero;
  bool _dealActive = false;

  bool get _offerMode =>
      widget.showOfferExtras || widget.product.isOfferProduct;

  @override
  void initState() {
    super.initState();
    if (_offerMode) {
      _syncCountdown();
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted) return;
        _syncCountdown();
      });
    }
  }

  @override
  void didUpdateWidget(covariant ProductCardMarketplaceLayout oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.product.productId != widget.product.productId ||
        oldWidget.showOfferExtras != widget.showOfferExtras) {
      _timer?.cancel();
      _timer = null;
      if (_offerMode) {
        _syncCountdown();
        _timer = Timer.periodic(const Duration(seconds: 1), (_) {
          if (!mounted) return;
          _syncCountdown();
        });
      }
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
    if (days > 0) return '${days}d $hours:$minutes:$seconds';
    return '$hours:$minutes:$seconds';
  }

  String _formatAmount(double value) {
    return ThousandsNumberInput.format(value, allowDecimal: true);
  }

  Widget _detailsText({
    required String details,
    required bool soldOut,
    required String fontFamily,
    required double detailsFontSize,
    required int? maxLines,
  }) {
    return Text(
      details.isEmpty ? '—' : details,
      maxLines: maxLines,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        fontFamily: fontFamily,
        fontSize: detailsFontSize,
        fontWeight: soldOut ? FontWeight.w700 : FontWeight.w400,
        color: soldOut ? const Color(0xFFDC2626) : AppColors.subtitle(context),
        height: 1.35,
      ),
    );
  }

  Widget _priceBlock({
    required String fontFamily,
    required double priceFontSize,
    required double detailsFontSize,
    required bool showDeal,
    required String currency,
    required double sale,
    required double original,
    required String unit,
  }) {
    if (!ProductPriceFormatter.canShowPrices) {
      return const SizedBox.shrink();
    }

    final child = showDeal
        ? Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _formatAmount(sale),
                style: TextStyle(
                  fontFamily: fontFamily,
                  fontSize: priceFontSize,
                  fontWeight: FontWeight.w800,
                  color: AppColors.title(context),
                  height: 1.15,
                ),
              ),
              SizedBox(width: 4.w),
              CurrencyIcon(
                currency: currency,
                size: priceFontSize * 0.9,
              ),
              if (unit.isNotEmpty)
                Text(
                  unit.startsWith('/') ? unit : ' $unit',
                  style: TextStyle(
                    fontFamily: fontFamily,
                    fontSize: detailsFontSize,
                    fontWeight: FontWeight.w400,
                    color: AppColors.subtitle(context),
                  ),
                ),
              if (original > sale) ...[
                SizedBox(width: 8.w),
                Text(
                  _formatAmount(original),
                  style: TextStyle(
                    fontFamily: fontFamily,
                    fontSize: detailsFontSize,
                    color: const Color(0xFF9CA3AF),
                    decoration: TextDecoration.lineThrough,
                    decorationColor: const Color(0xFF9CA3AF),
                  ),
                ),
              ],
            ],
          )
        : ProductPriceText.unitPrice(
            widget.product,
            amountStyle: TextStyle(
              fontFamily: fontFamily,
              fontSize: priceFontSize,
              fontWeight: FontWeight.w800,
              color: AppColors.title(context),
              height: 1.15,
            ),
            iconSize: priceFontSize,
            matchCurrencyToAmount: true,
            scaleToFit: true,
          );

    return SizedBox(
      width: double.infinity,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final fontFamily = AppFonts.familyFor(Localizations.localeOf(context));
    final cardTheme = widget.theme ?? ProductCardTheme.forProduct(widget.product);
    final titleColor = ProductGridLayout.productCardTitleColor(context);
    final displayTitle =
        (widget.title ?? widget.product.productName).capitalizeFirst();
    final soldOut = ProductStock.isSoldOut(widget.product);
    final details = soldOut ? s.soldOut : widget.product.description.trim();
    final titleFontSize = ProductGridLayout.cardTitleFontSize(context);
    final detailsFontSize = ProductGridLayout.cardDetailsFontSize(context);
    final priceFontSize = ProductGridLayout.cardPriceFontSize(context);
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final quantityWithUnit = ProductQuantityFormatter.quantityWithUnit(
      quantityText: widget.product.quantity,
      unitName: widget.product.unitName,
      s: s,
    );
    final priceTypeLabel = BookingPriceTypeLabel.appliesTo(widget.product)
        ? BookingPriceTypeLabel.fromProduct(widget.product)
        : ProductPriceTypeLabel.fromProduct(
            widget.product,
            isAr: isAr,
          );
    final showPriceType = (BookingPriceTypeLabel.appliesTo(widget.product) &&
            priceTypeLabel.isNotEmpty) ||
        (ProductPriceTypeLabel.appliesTo(widget.product) &&
            priceTypeLabel.isNotEmpty);

    final discount = widget.product.discountPercentValue;
    final showDeal =
        _offerMode && _dealActive && discount > 0 && widget.product.salePriceValue > 0;
    final currency = ProductPriceFormatter.currencyCode(widget.product);
    final sale = widget.product.salePriceValue;
    final original = widget.product.originalPriceValue;
    final unit = ProductPriceFormatter.unitSuffix(
      widget.product,
      s: S.of(context),
    );

    final titleWidget = Text(
      displayTitle.isEmpty ? 'Product' : displayTitle,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        fontFamily: fontFamily,
        fontSize: titleFontSize,
        fontWeight: FontWeight.w700,
        color: titleColor,
        height: 1.25,
      ),
    );

    final dealRow = showDeal
        ? Padding(
            padding: EdgeInsets.only(top: 6.h),
            child: Row(
              children: [
                Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
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
                SizedBox(width: 6.w),
                const Icon(
                  Icons.timer_outlined,
                  size: 14,
                  color: Color(0xFFCC0C39),
                ),
                SizedBox(width: 3.w),
                Expanded(
                  child: Text(
                    _countdownText(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: fontFamily,
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFFCC0C39),
                    ),
                  ),
                ),
              ],
            ),
          )
        : const SizedBox.shrink();

    final showPriceOnCard = ProductPriceFormatter.canShowPrices &&
        (!widget.product.isRequestProduct ||
            ProductPriceFormatter.amountValue(widget.product) > 0);
    final showReconfirm =
        widget.showSubjectToReconfirm && !widget.product.isRequestProduct;

    final footer = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        dealRow,
        SizedBox(height: 8.h),
        const Divider(height: 1, thickness: 1, color: Color(0xFFEEF0F3)),
        SizedBox(height: 8.h),
        if (showPriceOnCard)
          _priceBlock(
            fontFamily: fontFamily,
            priceFontSize: priceFontSize,
            detailsFontSize: detailsFontSize,
            showDeal: showDeal,
            currency: currency,
            sale: sale,
            original: original,
            unit: unit,
          ),
        if (quantityWithUnit.isNotEmpty) ...[
          SizedBox(height: showPriceOnCard ? 6.h : 8.h),
          Text(
            quantityWithUnit,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: fontFamily,
              fontSize: detailsFontSize,
              fontWeight: FontWeight.w400,
              color: const Color.fromRGBO(107, 114, 128, 1),
              height: 1.2,
            ),
          ),
        ],
        if (showReconfirm) ...[
          SizedBox(height: quantityWithUnit.isNotEmpty ? 4.h : 6.h),
          Text(
            S.of(context).subjectToReconfirm,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: fontFamily,
              fontSize: detailsFontSize,
              fontWeight: FontWeight.w600,
              color: const Color.fromRGBO(220, 38, 38, 1),
              height: 1.2,
            ),
          ),
        ],
        if (showPriceType) ...[
          SizedBox(height: 4.h),
          Text(
            priceTypeLabel,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: fontFamily,
              fontSize: detailsFontSize,
              fontWeight: FontWeight.w600,
              color: titleColor,
              height: 1.2,
            ),
          ),
        ],
      ],
    );

    if (widget.fillHeight) {
      return SizedBox(
        width: double.infinity,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            titleWidget,
            SizedBox(height: 4.h),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final style = TextStyle(
                    fontFamily: fontFamily,
                    fontSize: detailsFontSize,
                    fontWeight: soldOut ? FontWeight.w700 : FontWeight.w400,
                    height: 1.35,
                  );
                  final probe = TextPainter(
                    text: TextSpan(text: 'Ag', style: style),
                    textDirection: Directionality.of(context),
                    maxLines: 1,
                  )..layout();
                  final lineHeight = math.max(probe.height, 1.0);
                  final maxLines =
                      math.max(1, (constraints.maxHeight / lineHeight).floor());
                  return Align(
                    alignment: Alignment.topLeft,
                    child: _detailsText(
                      details: details,
                      soldOut: soldOut,
                      fontFamily: fontFamily,
                      detailsFontSize: detailsFontSize,
                      maxLines: maxLines,
                    ),
                  );
                },
              ),
            ),
            footer,
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        titleWidget,
        SizedBox(height: 4.h),
        _detailsText(
          details: details,
          soldOut: soldOut,
          fontFamily: fontFamily,
          detailsFontSize: detailsFontSize,
          maxLines: 2,
        ),
        footer,
      ],
    );
  }
}
