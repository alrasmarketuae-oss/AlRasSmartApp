import 'package:alrasmarket/core/utils/product_price_formatter.dart';
import 'package:alrasmarket/core/utils/product_quantity_formatter.dart';
import 'package:alrasmarket/core/utils/product_stock.dart';
import 'package:alrasmarket/core/utils/string_display_format.dart';
import 'package:alrasmarket/core/utils/relative_time_formatter.dart';
import 'package:alrasmarket/core/utils/thousands_separator_input_formatter.dart';
import 'package:alrasmarket/core/widgets/animated_discount_price_text.dart';
import 'package:alrasmarket/core/widgets/currency_icon.dart';
import 'package:alrasmarket/core/widgets/product_price_text.dart';
import 'package:alrasmarket/features/clint/presentation/helpers/product_price_type_label.dart';
import 'package:alrasmarket/features/clint/presentation/widgets/ad_hero_description_text.dart';
import 'package:alrasmarket/features/clint/presentation/widgets/booking_widets/booking_details_design.dart';
import 'package:alrasmarket/features/clint/presentation/widgets/product_detail/product_detail_copy_code.dart';
import 'package:alrasmarket/features/clint/presentation/widgets/booking_widets/booking_details_mapper.dart';
import 'package:alrasmarket/features/clint/presentation/widgets/product_media/product_media_thumbnail.dart';
import 'package:alrasmarket/features/company/data/models/my_listing_product_model.dart';
import 'package:alrasmarket/features/company/presentation/helpers/create_ad_price_labels.dart';
import 'package:alrasmarket/generated/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Offer product details layout (no supplier header).
class OfferAdDetailsBody extends StatelessWidget {
  const OfferAdDetailsBody({
    super.key,
    required this.product,
    required this.fontFamily,
    required this.quantityController,
    required this.quantityFormKey,
    required this.total,
    required this.onQuantityChanged,
    required this.quantityValidator,
  });

  final MyListingProductModel product;
  final String fontFamily;
  final TextEditingController quantityController;
  final GlobalKey<FormState> quantityFormKey;
  final double total;
  final VoidCallback onQuantityChanged;
  final String? Function(String?) quantityValidator;

  @override
  Widget build(BuildContext context) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final description = BookingDetailsMapper.descriptionText(product);
    final mediaItems = BookingDetailsMapper.mediaItems(product);
    final unit = product.unitName.trim();
    final category = product.categoryName.trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _OfferHero(
          product: product,
          fontFamily: fontFamily,
          mediaCount: mediaItems.length,
          categoryLabel: category,
          description: description,
          isAr: isAr,
        ),
        SizedBox(height: 14.h),
        _OfferAdDetailsCard(
          product: product,
          fontFamily: fontFamily,
          unit: unit,
          isAr: isAr,
        ),
        SizedBox(height: 14.h),
        Form(
          key: quantityFormKey,
          child: _QuantityAndTotalRow(
            product: product,
            fontFamily: fontFamily,
            quantityController: quantityController,
            unit: unit == 'Kilogram' ? 'Kg' : unit,
            total: total,
            onQuantityChanged: onQuantityChanged,
            quantityValidator: quantityValidator,
            isAr: isAr,
          ),
        ),
      ],
    );
  }
}

class _OfferHero extends StatelessWidget {
  const _OfferHero({
    required this.product,
    required this.fontFamily,
    required this.mediaCount,
    required this.categoryLabel,
    required this.description,
    required this.isAr,
  });

  final MyListingProductModel product;
  final String fontFamily;
  final int mediaCount;
  final String categoryLabel;
  final String description;
  final bool isAr;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final imageHeight = 132.w;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: BookingDetailsDesign.cardBg,
        borderRadius: BorderRadius.circular(BookingDetailsDesign.cardRadius),
        border: Border.all(color: BookingDetailsDesign.border),
        boxShadow: BookingDetailsDesign.cardShadow,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              ProductMediaThumbnail(
                product: product,
                width: 118.w,
                height: imageHeight,
                borderRadius: BorderRadius.circular(14.r),
              ),
              if (mediaCount > 0)
                Positioned(
                  top: 8.h,
                  left: 8.w,
                  child: Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 7.w, vertical: 4.h),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.55),
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.photo_camera_outlined,
                          size: 11.sp,
                          color: Colors.white,
                        ),
                        SizedBox(width: 3.w),
                        Text(
                          isAr ? '$mediaCount صور' : '$mediaCount Photos',
                          style: TextStyle(
                            color: Colors.white,
                            fontFamily: fontFamily,
                            fontSize: 10.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: SizedBox(
              height: imageHeight,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (categoryLabel.isNotEmpty && categoryLabel != '—')
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 10.w,
                        vertical: 4.h,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F1FB),
                        borderRadius: BorderRadius.circular(20.r),
                      ),
                      child: Text(
                        categoryLabel,
                        style: TextStyle(
                          color: BookingDetailsDesign.brandSoft,
                          fontFamily: fontFamily,
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  if (categoryLabel.isNotEmpty && categoryLabel != '—')
                    SizedBox(height: 8.h),
                  Text(
                    product.productName.isEmpty
                        ? s.product
                        : product.productName.capitalizeFirst(),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: BookingDetailsDesign.text,
                      fontFamily: fontFamily,
                      fontSize: 17.sp,
                      fontWeight: FontWeight.w800,
                      height: 1.25,
                    ),
                  ),
                  if (description.isNotEmpty) ...[
                    SizedBox(height: 6.h),
                    Expanded(
                      child: AdHeroDescriptionText(
                        text: description,
                        fontFamily: fontFamily,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OfferAdDetailsCard extends StatelessWidget {
  const _OfferAdDetailsCard({
    required this.product,
    required this.fontFamily,
    required this.unit,
    required this.isAr,
  });

  final MyListingProductModel product;
  final String fontFamily;
  final String unit;
  final bool isAr;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final main = <Widget>[];
    final meta = <Widget>[];

    if (ProductPriceFormatter.canShowProductPrice(product) &&
        ProductPriceFormatter.amount(product).isNotEmpty) {
      final sale = ProductPriceFormatter.saleAmountValue(product);
      final original = ProductPriceFormatter.originalAmountValue(product);
      final animateDiscount = product.isDiscountActive &&
          original > sale &&
          sale > 0;
      final priceStyle = TextStyle(
        color: BookingDetailsDesign.priceGreen,
        fontFamily: fontFamily,
        fontSize: 13.sp,
        fontWeight: FontWeight.w700,
      );
      final currency = ProductPriceFormatter.currencyCode(product);
      main.add(
        BookingDetailsFactTile(
          icon: Icons.sell_outlined,
          label: CreateAdPriceLabels.offerPricePerUnitLabel(s, unit),
          fontFamily: fontFamily,
          valueWidget: animateDiscount
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          ThousandsNumberInput.format(
                            original,
                            allowDecimal: true,
                          ),
                          style: TextStyle(
                            fontFamily: fontFamily,
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFFDC2626),
                            decoration: TextDecoration.lineThrough,
                            decorationColor: const Color(0xFFDC2626),
                            height: 1.2,
                          ),
                        ),
                        SizedBox(width: 4.w),
                        CurrencyIcon(
                          currency: currency,
                          size: 13.sp,
                          matchTextSize: true,
                        ),
                      ],
                    ),
                    SizedBox(height: 4.h),
                    AnimatedDiscountPriceText(
                      key: ValueKey(
                        'offer-price-${product.productId}-$original-$sale',
                      ),
                      fromAmount: original,
                      toAmount: sale,
                      currency: currency,
                      amountStyle: priceStyle,
                      matchCurrencyToAmount: true,
                    ),
                  ],
                )
              : ProductPriceText.fromProduct(
                  product,
                  amountStyle: priceStyle,
                  matchCurrencyToAmount: true,
                ),
        ),
      );
    }

    final qty = _quantityValue(s);
    if (qty.isNotEmpty) {
      main.add(
        BookingDetailsFactTile(
          icon: Icons.inventory_2_outlined,
          label: s.availableQuantity,
          fontFamily: fontFamily,
          value: qty,
          valueColor: BookingDetailsDesign.brandSoft,
        ),
      );
    }

    final priceType = ProductPriceTypeLabel.fromProduct(product, isAr: isAr);
    main.add(
      BookingDetailsFactTile(
        icon: Icons.local_offer_outlined,
        label: s.requestFulfillment,
        fontFamily: fontFamily,
        value: priceType.isNotEmpty ? priceType : '—',
        valueColor: const Color(0xFF7C3AED),
      ),
    );

    main.add(
      BookingDetailsFactTile(
        icon: Icons.handshake_outlined,
        label: s.negotiable,
        fontFamily: fontFamily,
        value: product.isNegotiable
            ? s.negotiable
            : (isAr ? 'لا — سعر ثابت' : 'No — fixed price'),
        valueColor: const Color(0xFFEA580C),
      ),
    );

    final code = product.productCode.trim();
    if (code.isNotEmpty) {
      meta.add(
        BookingDetailsFactTile(
          icon: Icons.description_outlined,
          label: s.productCode,
          fontFamily: fontFamily,
          valueWidget: ProductDetailCopyCode(code: code, fontFamily: fontFamily, isAr: isAr),
        ),
      );
    }
    final postedAt = product.createdAt.trim();
    if (postedAt.isNotEmpty) {
      meta.add(
        BookingDetailsFactTile(
          icon: Icons.calendar_today_outlined,
          label: isAr ? 'تاريخ ووقت الإضافة' : 'Posted Date & Time',
          fontFamily: fontFamily,
          value: RelativeTimeFormatter.format(s, postedAt),
        ),
      );
    }

    return BookingDetailsSectionCard(
      title: s.adDetails,
      icon: Icons.description_outlined,
      fontFamily: fontFamily,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          BookingDetailsFactsGrid(tiles: main),
          if (meta.isNotEmpty) BookingDetailsFactsGrid(tiles: meta),
        ],
      ),
    );
  }

  String _quantityValue(S s) {
    if (ProductStock.isSoldOut(product)) return s.soldOut;
    final qty = product.quantity.trim();
    if (qty.isEmpty) return '';
    return ProductQuantityFormatter.quantityWithUnit(
      quantityText: qty,
      unitName: product.unitName,
      s: s,
    );
  }
}

class _QuantityAndTotalRow extends StatelessWidget {
  const _QuantityAndTotalRow({
    required this.product,
    required this.fontFamily,
    required this.quantityController,
    required this.unit,
    required this.total,
    required this.onQuantityChanged,
    required this.quantityValidator,
    required this.isAr,
  });

  final MyListingProductModel product;
  final String fontFamily;
  final TextEditingController quantityController;
  final String unit;
  final double total;
  final VoidCallback onQuantityChanged;
  final String? Function(String?) quantityValidator;
  final bool isAr;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: BookingDetailsSectionCard(
            title: s.quantity,
            icon: Icons.inventory_2_outlined,
            fontFamily: fontFamily,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: quantityController,
                  textAlign: TextAlign.start,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    ThousandsSeparatorInputFormatter(allowDecimal: true),
                  ],
                  onChanged: (_) => onQuantityChanged(),
                  validator: quantityValidator,
                  style: TextStyle(
                    fontFamily: fontFamily,
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w700,
                    color: BookingDetailsDesign.text,
                    height: 1.2,
                  ),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    isDense: true,
                    hintText: '0',
                    hintStyle: TextStyle(
                      fontFamily: fontFamily,
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                      color: BookingDetailsDesign.muted,
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 14.w,
                      vertical: 14.h,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.r),
                      borderSide: BorderSide(
                        color: BookingDetailsDesign.brandSoft,
                        width: 1.5,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.r),
                      borderSide: const BorderSide(
                        color: BookingDetailsDesign.brand,
                        width: 2,
                      ),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.r),
                      borderSide: const BorderSide(
                        color: Color(0xFFE53935),
                        width: 1.5,
                      ),
                    ),
                    focusedErrorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.r),
                      borderSide: const BorderSide(
                        color: Color(0xFFE53935),
                        width: 2,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 10.h),
                Container(
                  width: double.infinity,
                  padding:
                      EdgeInsets.symmetric(horizontal: 10.w, vertical: 10.h),
                  decoration: BoxDecoration(
                    color: BookingDetailsDesign.iconBg,
                    borderRadius: BorderRadius.circular(10.r),
                    border: Border.all(color: BookingDetailsDesign.border),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.scale_outlined,
                        size: 16.sp,
                        color: BookingDetailsDesign.brandSoft,
                      ),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: Text(
                          unit.trim().isEmpty ? '—' : unit,
                          style: TextStyle(
                            fontFamily: fontFamily,
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w600,
                            color: BookingDetailsDesign.text,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        if (ProductPriceFormatter.canShowProductPrice(product)) ...[
          SizedBox(width: 10.w),
          Expanded(
            child: BookingDetailsSectionCard(
              title: s.total,
              icon: Icons.payments_outlined,
              fontFamily: fontFamily,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    s.pricePerUnitTimesQuantity,
                    style: TextStyle(
                      color: BookingDetailsDesign.muted,
                      fontFamily: fontFamily,
                      fontSize: 11.sp,
                    ),
                  ),
                  SizedBox(height: 10.h),
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(
                      horizontal: 10.w,
                      vertical: 12.h,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFECFDF3),
                      borderRadius: BorderRadius.circular(10.r),
                      border: Border.all(color: const Color(0xFFBBF7D0)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isAr ? 'المبلغ الإجمالي' : 'Total Amount',
                          style: TextStyle(
                            color: const Color(0xFF166534),
                            fontFamily: fontFamily,
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 4.h),
                        DefaultTextStyle(
                          style: TextStyle(
                            color: BookingDetailsDesign.priceGreen,
                            fontFamily: fontFamily,
                            fontSize: 15.sp,
                            fontWeight: FontWeight.w800,
                          ),
                          child: ProductPriceText.total(product, total),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}

