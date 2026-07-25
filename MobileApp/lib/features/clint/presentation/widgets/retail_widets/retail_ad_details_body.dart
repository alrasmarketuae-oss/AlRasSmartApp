import 'package:alrasmarket/core/utils/product_price_formatter.dart';
import 'package:alrasmarket/core/utils/product_quantity_formatter.dart';
import 'package:alrasmarket/core/utils/product_stock.dart';
import 'package:alrasmarket/core/utils/string_display_format.dart';
import 'package:alrasmarket/core/utils/utc_date_time.dart';
import 'package:alrasmarket/core/widgets/product_price_text.dart';
import 'package:alrasmarket/features/clint/presentation/widgets/ad_hero_description_text.dart';
import 'package:alrasmarket/features/clint/presentation/widgets/booking_widets/booking_details_design.dart';
import 'package:alrasmarket/features/clint/presentation/widgets/product_detail/product_detail_copy_code.dart';
import 'package:alrasmarket/features/clint/presentation/widgets/booking_widets/booking_details_mapper.dart';
import 'package:alrasmarket/features/clint/presentation/widgets/product_media/product_media_thumbnail.dart';
import 'package:alrasmarket/features/clint/presentation/widgets/requst_widets/request_details_mapper.dart';
import 'package:alrasmarket/features/company/data/models/my_listing_product_model.dart';
import 'package:alrasmarket/features/company/presentation/helpers/create_ad_price_labels.dart';
import 'package:alrasmarket/generated/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Retail product details layout (no supplier header).
class RetailAdDetailsBody extends StatelessWidget {
  const RetailAdDetailsBody({
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
    final s = S.of(context);
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final description = BookingDetailsMapper.retailDescriptionText(product);
    final mediaItems = BookingDetailsMapper.mediaItems(product);
    final unit = product.unitNameForChannel(preferRetail: true).trim();
    final category = product.categoryName.trim();
    final specs = BookingDetailsMapper.retailSpecificationItems(product);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _RetailHero(
          product: product,
          fontFamily: fontFamily,
          mediaCount: mediaItems.length,
          categoryLabel: category,
          description: description,
          isAr: isAr,
        ),
        SizedBox(height: 14.h),
        _RetailAdDetailsCard(
          product: product,
          fontFamily: fontFamily,
          unit: unit,
          isAr: isAr,
        ),
        if (specs.isNotEmpty) ...[
          SizedBox(height: 14.h),
          BookingDetailsSectionCard(
            title: s.specifications,
            icon: Icons.list_alt_rounded,
            fontFamily: fontFamily,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final item in specs)
                  Padding(
                    padding: EdgeInsets.only(bottom: 6.h),
                    child: Text(
                      '• $item',
                      style: TextStyle(
                        color: BookingDetailsDesign.text,
                        fontFamily: fontFamily,
                        fontSize: 13.sp,
                        height: 1.4,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
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

class _RetailHero extends StatelessWidget {
  const _RetailHero({
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

class _RetailAdDetailsCard extends StatelessWidget {
  const _RetailAdDetailsCard({
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

    if (ProductPriceFormatter.canShowPrices &&
        ProductPriceFormatter.amount(product).isNotEmpty) {
      main.add(
        BookingDetailsFactTile(
          icon: Icons.sell_outlined,
          label: CreateAdPriceLabels.pricePerUnitLabel(s, unit),
          fontFamily: fontFamily,
          valueWidget: ProductPriceText.fromProduct(
            product,
            amountStyle: TextStyle(
              color: BookingDetailsDesign.priceGreen,
              fontFamily: fontFamily,
              fontSize: 13.sp,
              fontWeight: FontWeight.w700,
            ),
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

    final packaging = RequestDetailsMapper.packagingDisplay(
      product,
      s,
      isAr: isAr,
      packagingOverride: product.retailPackaging ?? product.packaging,
    );
    if (packaging.isNotEmpty) {
      main.add(
        BookingDetailsFactTile(
          icon: Icons.inventory_outlined,
          label: isAr ? 'التعبئة' : 'Packing',
          fontFamily: fontFamily,
          value: packaging,
        ),
      );
    }

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
          value: UtcDateTime.formatDateTimeLocal(postedAt),
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
    final qty = product.quantityForChannel(preferRetail: true).trim();
    if (qty.isEmpty) return '';
    return ProductQuantityFormatter.quantityWithUnit(
      quantityText: qty,
      unitName: product.unitNameForChannel(preferRetail: true),
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

  void _step(int delta) {
    final current = double.tryParse(quantityController.text.trim()) ?? 0;
    final next = (current + delta).clamp(1, 999999);
    final text = next == next.roundToDouble()
        ? next.toInt().toString()
        : next.toString();
    quantityController.text = text;
    onQuantityChanged();
  }

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
              children: [
                Row(
                  children: [
                    _StepButton(
                      icon: Icons.remove,
                      onTap: () => _step(-1),
                    ),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 8.w),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10.r),
                          border: Border.all(
                            color: BookingDetailsDesign.brandSoft
                                .withValues(alpha: 0.45),
                          ),
                        ),
                        child: TextFormField(
                          controller: quantityController,
                          textAlign: TextAlign.center,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                              RegExp(r'[0-9.]'),
                            ),
                          ],
                          onChanged: (_) => onQuantityChanged(),
                          validator: quantityValidator,
                          style: TextStyle(
                            fontFamily: fontFamily,
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w700,
                            color: BookingDetailsDesign.text,
                          ),
                          decoration: InputDecoration(
                            isDense: true,
                            border: InputBorder.none,
                            hintText: s.enterQuantity,
                            hintStyle: TextStyle(
                              fontFamily: fontFamily,
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w500,
                              color: BookingDetailsDesign.muted,
                            ),
                            contentPadding:
                                EdgeInsets.symmetric(vertical: 10.h),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 8.w),
                    _StepButton(
                      icon: Icons.add,
                      onTap: () => _step(1),
                    ),
                  ],
                ),
                SizedBox(height: 8.h),
                Text(
                  s.quantityTypeManuallyHint,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: BookingDetailsDesign.muted,
                    fontFamily: fontFamily,
                    fontSize: 11.sp,
                    height: 1.35,
                  ),
                ),
                SizedBox(height: 10.h),
                Container(
                  width: double.infinity,
                  padding:
                      EdgeInsets.symmetric(horizontal: 10.w, vertical: 10.h),
                  decoration: BoxDecoration(
                    color: Colors.white,
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
                if (ProductPriceFormatter.canShowPrices)
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
                  )
                else
                  Text(
                    '—',
                    style: TextStyle(
                      fontFamily: fontFamily,
                      color: BookingDetailsDesign.muted,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _StepButton extends StatelessWidget {
  const _StepButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFF3F6FA),
      borderRadius: BorderRadius.circular(10.r),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10.r),
        child: SizedBox(
          width: 36.w,
          height: 36.w,
          child: Icon(icon, size: 18.sp, color: BookingDetailsDesign.brand),
        ),
      ),
    );
  }
}

