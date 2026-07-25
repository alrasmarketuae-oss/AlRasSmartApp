import 'package:alrasmarket/core/utils/product_price_formatter.dart';
import 'package:alrasmarket/core/utils/product_quantity_formatter.dart';
import 'package:alrasmarket/core/utils/product_stock.dart';
import 'package:alrasmarket/core/utils/string_display_format.dart';
import 'package:alrasmarket/core/utils/utc_date_time.dart';
import 'package:alrasmarket/core/widgets/product_price_text.dart';
import 'package:alrasmarket/features/clint/presentation/widgets/booking_widets/booking_bullet_row.dart';
import 'package:alrasmarket/features/clint/presentation/widgets/booking_widets/booking_details_design.dart';
import 'package:alrasmarket/features/clint/presentation/widgets/product_detail/product_detail_copy_code.dart';
import 'package:alrasmarket/features/clint/presentation/widgets/booking_widets/booking_details_mapper.dart';
import 'package:alrasmarket/features/clint/presentation/widgets/booking_widets/booking_details_section_title.dart';
import 'package:alrasmarket/features/clint/presentation/widgets/product_media/product_media_thumbnail.dart';
import 'package:alrasmarket/features/clint/presentation/widgets/requst_widets/request_details_mapper.dart';
import 'package:alrasmarket/features/company/data/models/my_listing_product_model.dart';
import 'package:alrasmarket/features/company/presentation/helpers/create_ad_price_labels.dart';
import 'package:alrasmarket/generated/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class BookingProductSummaryWidget extends StatelessWidget {
  const BookingProductSummaryWidget({
    super.key,
    required this.product,
    required this.fontFamily,
    this.specifications = const [],
  });

  final MyListingProductModel product;
  final String fontFamily;
  final List<String> specifications;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final description = product.description.trim();
    final mediaItems = BookingDetailsMapper.mediaItems(product);
    final mediaCount = mediaItems.length;
    final typeName = product.productTypeName.trim().isEmpty
        ? 'Booking'
        : product.productTypeName.trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(12.w),
          decoration: BoxDecoration(
            color: BookingDetailsDesign.cardBg,
            borderRadius:
                BorderRadius.circular(BookingDetailsDesign.cardRadius),
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
                    width: 108.w,
                    height: 108.w,
                    borderRadius: BorderRadius.circular(12.r),
                    openPreviewOnTap: true,
                  ),
                  if (mediaCount > 0)
                    Positioned(
                      top: 6.h,
                      left: 6.w,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 6.w,
                          vertical: 3.h,
                        ),
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
                              isAr
                                  ? '$mediaCount صور'
                                  : '$mediaCount Photos',
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
                    Align(
                      alignment: AlignmentDirectional.centerEnd,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8.w,
                          vertical: 3.h,
                        ),
                        decoration: BoxDecoration(
                          color: BookingDetailsDesign.brand,
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Text(
                          typeName,
                          style: TextStyle(
                            color: Colors.white,
                            fontFamily: fontFamily,
                            fontSize: 10.sp,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 6.h),
                    Text(
                      product.productName.isEmpty
                          ? s.product
                          : product.productName.capitalizeFirst(),
                      style: TextStyle(
                        color: BookingDetailsDesign.text,
                        fontFamily: fontFamily,
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w800,
                        height: 1.3,
                      ),
                    ),
                    if (description.isNotEmpty) ...[
                      SizedBox(height: 4.h),
                      Text(
                        description,
                        maxLines: 3,
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
        ),
        SizedBox(height: 10.h),
        Row(
          children: [
            Icon(Icons.star_rounded, size: 16.sp, color: const Color(0xFFF5B301)),
            SizedBox(width: 4.w),
            Text(
              isAr ? '0.0 (0 تقييم)' : '0.0 (0 reviews)',
              style: TextStyle(
                color: BookingDetailsDesign.muted,
                fontFamily: fontFamily,
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
          ],
        ),
        SizedBox(height: 14.h),
        _BookingAdDetailsGrid(
          product: product,
          fontFamily: fontFamily,
        ),
        if (specifications.isNotEmpty) ...[
          SizedBox(height: 14.h),
          BookingDetailsSectionTitle(
            title: s.specifications,
            fontFamily: fontFamily,
          ),
          SizedBox(height: 8.h),
          ...specifications.map(
            (item) => BookingBulletRow(
              text: item,
              fontFamily: fontFamily,
            ),
          ),
        ],
      ],
    );
  }
}

/// Same booking facts as [ProductDetailFactsCard] (booking mode), new layout.
class _BookingAdDetailsGrid extends StatelessWidget {
  const _BookingAdDetailsGrid({
    required this.product,
    required this.fontFamily,
  });

  final MyListingProductModel product;
  final String fontFamily;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final unit = product.unitName.trim();

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

    final typeName = product.productTypeName.trim();
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
          value: UtcDateTime.formatDateTimeLocal(postedAt),
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

