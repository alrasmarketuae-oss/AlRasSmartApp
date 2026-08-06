import 'package:alrasmarket/core/utils/product_price_formatter.dart';
import 'package:alrasmarket/core/utils/product_quantity_formatter.dart';
import 'package:alrasmarket/core/utils/product_stock.dart';
import 'package:alrasmarket/core/utils/string_display_format.dart';
import 'package:alrasmarket/core/utils/relative_time_formatter.dart';
import 'package:alrasmarket/core/widgets/product_price_text.dart';
import 'package:alrasmarket/features/clint/presentation/helpers/booking_price_type_label.dart';
import 'package:alrasmarket/features/clint/presentation/widgets/ad_hero_description_text.dart';
import 'package:alrasmarket/features/clint/presentation/widgets/booking_widets/booking_details_design.dart';
import 'package:alrasmarket/features/clint/presentation/widgets/product_detail/product_detail_copy_code.dart';
import 'package:alrasmarket/features/clint/presentation/widgets/booking_widets/booking_details_mapper.dart';
import 'package:alrasmarket/features/clint/presentation/widgets/booking_widets/booking_shipping_details_section.dart';
import 'package:alrasmarket/features/clint/presentation/widgets/product_media/product_media_thumbnail.dart';
import 'package:alrasmarket/features/clint/presentation/widgets/requst_widets/request_details_mapper.dart';
import 'package:alrasmarket/features/company/data/models/my_listing_product_model.dart';
import 'package:alrasmarket/features/company/presentation/helpers/create_ad_price_labels.dart';
import 'package:alrasmarket/generated/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Booking ad details — same visual layout as category/retail ads,
/// with the existing booking data fields only.
class BookingAdDetailsBody extends StatelessWidget {
  const BookingAdDetailsBody({
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
    final description = product.description.trim();
    final mediaItems = BookingDetailsMapper.mediaItems(product);
    final mediaCount = mediaItems.length;
    final unit = product.unitName.trim();
    final supplierNotes = BookingDetailsMapper.supplierNotesText(product);
    final specs = BookingDetailsMapper.specificationItems(product);
    final typeName = product.productTypeName.trim().isEmpty
        ? 'Booking'
        : product.productTypeName.trim();
    final bookingPriceType = BookingPriceTypeLabel.fromProduct(product);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _HeroCard(
          product: product,
          fontFamily: fontFamily,
          mediaCount: mediaCount,
          typeLabel: typeName,
          description: description,
          isAr: isAr,
        ),
        SizedBox(height: 12.h),
        _MetricsRow(
          product: product,
          fontFamily: fontFamily,
          unit: unit,
          bookingPriceType: bookingPriceType,
          isAr: isAr,
        ),
        SizedBox(height: 14.h),
        _AdDetailsCard(
          product: product,
          fontFamily: fontFamily,
          unit: unit,
          typeName: typeName,
          bookingPriceType: bookingPriceType,
          isAr: isAr,
        ),
        if (specs.isNotEmpty) ...[
          SizedBox(height: 14.h),
          BookingDetailsSectionCard(
            title: s.specifications,
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
        SizedBox(height: 14.h),
        BookingShippingDetailsSection(
          product: product,
          fontFamily: fontFamily,
        ),
        if (product.documents.isNotEmpty) ...[
          SizedBox(height: 14.h),
          ProductDocumentsSection(
            documents: product.documents,
            fontFamily: fontFamily,
          ),
        ],
        if (supplierNotes.isNotEmpty) ...[
          SizedBox(height: 14.h),
          BookingDetailsSectionCard(
            title: s.supplierNotes,
            icon: Icons.sticky_note_2_outlined,
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

class _HeroCard extends StatelessWidget {
  const _HeroCard({
    required this.product,
    required this.fontFamily,
    required this.mediaCount,
    required this.typeLabel,
    required this.description,
    required this.isAr,
  });

  final MyListingProductModel product;
  final String fontFamily;
  final int mediaCount;
  final String typeLabel;
  final String description;
  final bool isAr;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final imageHeight = 140.w;

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
                width: 120.w,
                height: imageHeight,
                borderRadius: BorderRadius.circular(14.r),
              ),
              if (mediaCount > 0)
                Positioned(
                  left: 8.w,
                  bottom: 8.h,
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
                  if (typeLabel.isNotEmpty)
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
                        typeLabel,
                        style: TextStyle(
                          color: BookingDetailsDesign.brandSoft,
                          fontFamily: fontFamily,
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  if (typeLabel.isNotEmpty) SizedBox(height: 8.h),
                  Text(
                    product.productName.isEmpty
                        ? s.product
                        : product.productName.capitalizeFirst(),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: BookingDetailsDesign.brand,
                      fontFamily: fontFamily,
                      fontSize: 18.sp,
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

class _MetricsRow extends StatelessWidget {
  const _MetricsRow({
    required this.product,
    required this.fontFamily,
    required this.unit,
    required this.bookingPriceType,
    required this.isAr,
  });

  final MyListingProductModel product;
  final String fontFamily;
  final String unit;
  final String bookingPriceType;
  final bool isAr;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final qty = _quantityValue(s);
    final priceTypeLabel = isAr ? 'نوع سعر البوكينج' : 'Booking Price Type';

    final cards = <Widget>[
      _MetricCard(
        fontFamily: fontFamily,
        label: CreateAdPriceLabels.pricePerUnitLabel(s, unit),
        icon: Icons.sell_outlined,
        iconColor: BookingDetailsDesign.priceGreen,
        valueChild: ProductPriceFormatter.canShowPrices &&
                ProductPriceFormatter.amount(product).isNotEmpty
            ? ProductPriceText.fromProduct(
                product,
                amountStyle: TextStyle(
                  color: BookingDetailsDesign.muted,
                  fontFamily: fontFamily,
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w600,
                ),
                matchCurrencyToAmount: true,
              )
            : null,
        value: ProductPriceFormatter.canShowPrices &&
                ProductPriceFormatter.amount(product).isNotEmpty
            ? null
            : '—',
      ),
      _MetricCard(
        fontFamily: fontFamily,
        label: s.availableQuantity,
        icon: Icons.inventory_2_outlined,
        iconColor: BookingDetailsDesign.brandSoft,
        value: qty.isEmpty ? '—' : qty,
      ),
      _MetricCard(
        fontFamily: fontFamily,
        label: priceTypeLabel,
        icon: Icons.local_shipping_outlined,
        iconColor: const Color(0xFF7C3AED),
        value: bookingPriceType.isNotEmpty ? bookingPriceType : '—',
      ),
      _MetricCard(
        fontFamily: fontFamily,
        label: s.negotiable,
        icon: Icons.handshake_outlined,
        iconColor: const Color(0xFF0D9488),
        value: product.isNegotiable
            ? s.negotiable
            : (isAr ? 'غير قابل للتفاوض' : 'Non-Negotiable'),
      ),
    ];

    return SizedBox(
      height: 86.h,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < cards.length; i++) ...[
            if (i > 0) SizedBox(width: 6.w),
            Expanded(child: cards[i]),
          ],
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

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.fontFamily,
    required this.label,
    required this.icon,
    required this.iconColor,
    this.value,
    this.valueChild,
  });

  final String fontFamily;
  final String label;
  final IconData icon;
  final Color iconColor;
  final String? value;
  final Widget? valueChild;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      padding: EdgeInsets.fromLTRB(7.w, 8.h, 7.w, 8.h),
      decoration: BoxDecoration(
        color: BookingDetailsDesign.cardBg,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: BookingDetailsDesign.border),
        boxShadow: BookingDetailsDesign.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: BookingDetailsDesign.text,
                    fontFamily: fontFamily,
                    fontSize: 9.sp,
                    fontWeight: FontWeight.w700,
                    height: 1.15,
                  ),
                ),
              ),
              Container(
                width: 20.w,
                height: 20.w,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 11.sp, color: iconColor),
              ),
            ],
          ),
          const Spacer(),
          valueChild ??
              Text(
                value ?? '—',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: BookingDetailsDesign.muted,
                  fontFamily: fontFamily,
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w600,
                  height: 1.2,
                ),
              ),
        ],
      ),
    );
  }
}

class _AdDetailsCard extends StatelessWidget {
  const _AdDetailsCard({
    required this.product,
    required this.fontFamily,
    required this.unit,
    required this.typeName,
    required this.bookingPriceType,
    required this.isAr,
  });

  final MyListingProductModel product;
  final String fontFamily;
  final String unit;
  final String typeName;
  final String bookingPriceType;
  final bool isAr;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final main = <Widget>[];
    final meta = <Widget>[];

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
              fontWeight: FontWeight.w800,
              height: 1.2,
            ),
            matchCurrencyToAmount: true,
          ),
        ),
      );
    }

    if (bookingPriceType.isNotEmpty) {
      main.add(
        BookingDetailsFactTile(
          icon: Icons.local_shipping_outlined,
          label: isAr ? 'نوع سعر البوكينج' : 'Booking Price Type',
          fontFamily: fontFamily,
          value: bookingPriceType,
          valueBold: true,
        ),
      );
    }

    main.add(
      BookingDetailsFactTile(
        icon: Icons.groups_outlined,
        label: s.negotiable,
        fontFamily: fontFamily,
        value: product.isNegotiable
            ? s.negotiable
            : (isAr ? 'لا — سعر ثابت' : 'No — fixed price'),
      ),
    );

    final category = product.categoryName.trim();
    main.add(
      BookingDetailsFactTile(
        icon: Icons.grid_view_rounded,
        label: s.category,
        fontFamily: fontFamily,
        value: (category.isNotEmpty && category != '—')
            ? category
            : (isAr ? 'كل التصنيفات' : 'All categories'),
      ),
    );

    if (typeName.isNotEmpty) {
      main.add(
        BookingDetailsFactTile(
          icon: Icons.local_offer_outlined,
          label: isAr ? 'نوع الإعلان' : 'Ad type',
          fontFamily: fontFamily,
          value: typeName,
          valueBold: true,
        ),
      );
    }

    final packaging = RequestDetailsMapper.packagingDisplay(
      product,
      s,
      isAr: isAr,
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

    final productCode = product.productCode.trim();
    if (productCode.isNotEmpty) {
      meta.add(
        BookingDetailsFactTile(
          icon: Icons.qr_code_2_rounded,
          label: s.productCode,
          fontFamily: fontFamily,
          valueWidget: ProductDetailCopyCode(
            code: productCode,
            fontFamily: fontFamily,
            isAr: isAr,
          ),
        ),
      );
    }
    final postedAt = product.createdAt.trim();
    if (postedAt.isNotEmpty) {
      meta.add(
        BookingDetailsFactTile(
          icon: Icons.calendar_today_outlined,
          label: isAr ? 'تاريخ ووقت الإضافة' : 'Posted date & time',
          fontFamily: fontFamily,
          value: RelativeTimeFormatter.format(s, postedAt),
        ),
      );
    }

    if (main.isEmpty && meta.isEmpty) {
      return const SizedBox.shrink();
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

