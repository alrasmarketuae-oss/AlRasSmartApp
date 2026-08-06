import 'package:alrasmarket/core/utils/product_price_formatter.dart';
import 'package:alrasmarket/core/utils/product_quantity_formatter.dart';
import 'package:alrasmarket/core/utils/product_stock.dart';
import 'package:alrasmarket/core/utils/relative_time_formatter.dart';
import 'package:alrasmarket/core/widgets/product_price_text.dart';
import 'package:alrasmarket/features/clint/presentation/helpers/product_price_type_label.dart';
import 'package:alrasmarket/features/clint/presentation/widgets/booking_widets/booking_details_design.dart';
import 'package:alrasmarket/features/clint/presentation/widgets/product_detail/product_detail_copy_code.dart';
import 'package:alrasmarket/features/clint/presentation/widgets/booking_widets/booking_details_mapper.dart';
import 'package:alrasmarket/features/clint/presentation/widgets/product_media/product_media_thumbnail.dart';
import 'package:alrasmarket/features/clint/presentation/widgets/requst_widets/request_details_mapper.dart';
import 'package:alrasmarket/features/company/data/models/my_listing_product_model.dart';
import 'package:alrasmarket/features/company/presentation/helpers/create_ad_price_labels.dart';
import 'package:alrasmarket/generated/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Request ad details layout — style matches booking/category/offer, backend data only.
class RequestAdDetailsBody extends StatelessWidget {
  const RequestAdDetailsBody({
    super.key,
    required this.product,
    required this.fontFamily,
  });

  final MyListingProductModel product;
  final String fontFamily;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final description = RequestDetailsMapper.descriptionText(product);
    final specs = RequestDetailsMapper.specificationItems(product);
    final additionalNotes = RequestDetailsMapper.additionalNotesText(product);
    final mediaItems = BookingDetailsMapper.mediaItems(product);
    final category = product.categoryName.trim();
    final unit = product.unitName.trim();
    final supplierNotes = BookingDetailsMapper.supplierNotesText(product);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _RequestHero(
          product: product,
          fontFamily: fontFamily,
          mediaCount: mediaItems.length,
          categoryLabel: category,
          description: description,
          isAr: isAr,
        ),
        SizedBox(height: 14.h),
        _RequestFactsCard(
          product: product,
          fontFamily: fontFamily,
          unit: unit,
          isAr: isAr,
        ),
        SizedBox(height: 14.h),
        _RequestLogisticsCard(
          product: product,
          fontFamily: fontFamily,
        ),
        if (specs.isNotEmpty) ...[
          SizedBox(height: 14.h),
          BookingDetailsSectionCard(
            title: s.requiredSpecifications,
            icon: Icons.checklist_outlined,
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
        if (additionalNotes.isNotEmpty) ...[
          SizedBox(height: 14.h),
          BookingDetailsSectionCard(
            title: s.additionalNotes,
            icon: Icons.sticky_note_2_outlined,
            fontFamily: fontFamily,
            child: Text(
              additionalNotes,
              style: TextStyle(
                color: BookingDetailsDesign.muted,
                fontFamily: fontFamily,
                fontSize: 13.sp,
                height: 1.5,
              ),
            ),
          ),
        ],
        if (supplierNotes.isNotEmpty) ...[
          SizedBox(height: 14.h),
          BookingDetailsSectionCard(
            title: s.supplierNotes,
            icon: Icons.notes_outlined,
            fontFamily: fontFamily,
            child: Text(
              supplierNotes,
              style: TextStyle(
                color: BookingDetailsDesign.muted,
                fontFamily: fontFamily,
                fontSize: 13.sp,
                height: 1.5,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _RequestHero extends StatelessWidget {
  const _RequestHero({
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
    final title = RequestDetailsMapper.title(product, s);

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
                height: 132.w,
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (categoryLabel.isNotEmpty && categoryLabel != '—')
                  Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
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
                SizedBox(height: 8.h),
                Text(
                  title,
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
                  Text(
                    description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: BookingDetailsDesign.muted,
                      fontFamily: fontFamily,
                      fontSize: 12.sp,
                      height: 1.4,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RequestFactsCard extends StatelessWidget {
  const _RequestFactsCard({
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
    final rows = <Widget>[];

    void addRow({
      required IconData icon,
      required Color iconColor,
      required String label,
      String? value,
      Widget? valueWidget,
      Color? valueColor,
    }) {
      if (valueWidget == null && (value == null || value.trim().isEmpty)) {
        return;
      }
      rows.add(
        _DetailRow(
          icon: icon,
          iconColor: iconColor,
          label: label,
          value: value,
          valueWidget: valueWidget,
          valueColor: valueColor,
          fontFamily: fontFamily,
          showDivider: rows.isNotEmpty,
        ),
      );
    }

    final qty = _quantityValue(s);
    if (qty.isNotEmpty) {
      addRow(
        icon: Icons.inventory_2_outlined,
        iconColor: BookingDetailsDesign.brandSoft,
        label: s.requiredQuantity,
        value: qty,
        valueColor: BookingDetailsDesign.brandSoft,
      );
    }

    if (ProductPriceFormatter.canShowPrices &&
        ProductPriceFormatter.amount(product).isNotEmpty) {
      addRow(
        icon: Icons.sell_outlined,
        iconColor: BookingDetailsDesign.priceGreen,
        label: CreateAdPriceLabels.targetPricePerUnitLabel(s, unit),
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
      );
    }

    final priceType = ProductPriceTypeLabel.fromProduct(product, isAr: isAr);
    addRow(
      icon: Icons.description_outlined,
      iconColor: const Color(0xFF7C3AED),
      label: s.requestFulfillment,
      value: priceType.isNotEmpty ? priceType : '—',
      valueColor: const Color(0xFF7C3AED),
    );

    addRow(
      icon: Icons.handshake_outlined,
      iconColor: const Color(0xFFEA580C),
      label: s.negotiable,
      value: product.isNegotiable
          ? s.negotiable
          : (isAr ? 'لا — سعر ثابت' : 'No — fixed price'),
      valueColor: const Color(0xFFEA580C),
    );

    final packaging = RequestDetailsMapper.packagingDisplay(
      product,
      s,
      isAr: isAr,
    );
    if (packaging.isNotEmpty) {
      addRow(
        icon: Icons.inventory_outlined,
        iconColor: BookingDetailsDesign.brandSoft,
        label: isAr ? 'التعبئة' : 'Packing',
        value: packaging,
      );
    }

    final code = product.productCode.trim();
    if (code.isNotEmpty) {
      addRow(
        icon: Icons.qr_code_2_rounded,
        iconColor: BookingDetailsDesign.brandSoft,
        label: s.productCode,
        valueWidget: ProductDetailCopyCode(code: code, fontFamily: fontFamily, isAr: isAr),
      );
    }

    final postedAt = product.createdAt.trim();
    if (postedAt.isNotEmpty) {
      addRow(
        icon: Icons.calendar_today_outlined,
        iconColor: BookingDetailsDesign.brandSoft,
        label: isAr ? 'تاريخ ووقت الإضافة' : 'Posted Date & Time',
        value: RelativeTimeFormatter.format(s, postedAt),
      );
    }

    if (rows.isEmpty) return const SizedBox.shrink();

    return BookingDetailsSectionCard(
      title: s.orderDetails,
      icon: Icons.receipt_long_outlined,
      fontFamily: fontFamily,
      child: Column(children: rows),
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

class _RequestLogisticsCard extends StatelessWidget {
  const _RequestLogisticsCard({
    required this.product,
    required this.fontFamily,
  });

  final MyListingProductModel product;
  final String fontFamily;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final rows = <Widget>[];
    final isBookingRequest = RequestDetailsMapper.isBookingFulfillment(product);

    void addRow({
      required IconData icon,
      required Color iconColor,
      required String label,
      required String value,
    }) {
      final trimmed = value.trim();
      if (trimmed.isEmpty) return;
      rows.add(
        _DetailRow(
          icon: icon,
          iconColor: iconColor,
          label: label,
          value: trimmed,
          fontFamily: fontFamily,
          showDivider: rows.isNotEmpty,
        ),
      );
    }

    if (isBookingRequest) {
      addRow(
        icon: Icons.public_outlined,
        iconColor: BookingDetailsDesign.brandSoft,
        label: s.countryOfOrigin,
        value: RequestDetailsMapper.originCountryName(product),
      );
      addRow(
        icon: Icons.anchor_outlined,
        iconColor: BookingDetailsDesign.brandSoft,
        label: s.loadingPort,
        value: RequestDetailsMapper.loadingPortName(product),
      );
      addRow(
        icon: Icons.flag_outlined,
        iconColor: BookingDetailsDesign.brandSoft,
        label: s.destinationCountry,
        value: RequestDetailsMapper.destinationCountryName(product),
      );
      addRow(
        icon: Icons.location_on_outlined,
        iconColor: BookingDetailsDesign.brandSoft,
        label: s.destinationPort,
        value: RequestDetailsMapper.destinationPortName(product),
      );
    } else {
      addRow(
        icon: Icons.place_outlined,
        iconColor: BookingDetailsDesign.brandSoft,
        label: s.deliveryAddress,
        value: RequestDetailsMapper.deliveryAddress(product),
      );
    }

    final postingDate = RequestDetailsMapper.formattedPostingDate(product, s);
    addRow(
      icon: Icons.calendar_month_outlined,
      iconColor: BookingDetailsDesign.brandSoft,
      label: s.postingDate,
      value: postingDate,
    );

    if (rows.isEmpty) return const SizedBox.shrink();

    return BookingDetailsSectionCard(
      title: s.orderDetails,
      icon: Icons.location_on_outlined,
      fontFamily: fontFamily,
      child: Column(children: rows),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.fontFamily,
    this.value,
    this.valueWidget,
    this.valueColor,
    this.showDivider = false,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final String fontFamily;
  final String? value;
  final Widget? valueWidget;
  final Color? valueColor;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (showDivider)
          Divider(
            height: 1,
            color: BookingDetailsDesign.border.withValues(alpha: 0.9),
          ),
        Padding(
          padding: EdgeInsets.symmetric(vertical: 10.h),
          child: Row(
            children: [
              Container(
                width: 32.w,
                height: 32.w,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 16.sp, color: iconColor),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: BookingDetailsDesign.text,
                    fontFamily: fontFamily,
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              SizedBox(width: 8.w),
              Flexible(
                child: Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: valueWidget ??
                      Text(
                        value ?? '',
                        textAlign: TextAlign.end,
                        style: TextStyle(
                          color: valueColor ?? BookingDetailsDesign.text,
                          fontFamily: fontFamily,
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w700,
                          height: 1.3,
                        ),
                      ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

