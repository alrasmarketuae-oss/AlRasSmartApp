import 'package:alrasmarket/core/theme/app_fonts.dart';
import 'package:alrasmarket/core/theme/colors.dart';
import 'package:alrasmarket/core/utils/product_price_formatter.dart';
import 'package:alrasmarket/core/utils/product_stock.dart';
import 'package:alrasmarket/core/utils/relative_time_formatter.dart';
import 'package:alrasmarket/core/widgets/product_price_text.dart';
import 'package:alrasmarket/features/clint/presentation/helpers/product_price_type_label.dart';
import 'package:alrasmarket/features/clint/presentation/widgets/booking_widets/booking_details_mapper.dart';
import 'package:alrasmarket/features/clint/presentation/widgets/booking_widets/booking_product_image_carousel.dart';
import 'package:alrasmarket/features/clint/presentation/widgets/product_views_badge.dart';
import 'package:alrasmarket/features/clint/presentation/widgets/requst_widets/request_details_mapper.dart';
import 'package:alrasmarket/features/company/data/models/my_listing_product_model.dart';
import 'package:alrasmarket/features/company/presentation/models/create_ad_type.dart';
import 'package:alrasmarket/generated/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class AdRequestOrderInfoCard extends StatefulWidget {
  const AdRequestOrderInfoCard({
    super.key,
    required this.product,
    required this.fontFamily,
    this.preferRetailPricing = false,
    this.preferCategoryLabel = false,
    this.showBothPricingChannels = false,
  });

  final MyListingProductModel product;
  final String fontFamily;
  final bool preferRetailPricing;
  final bool preferCategoryLabel;
  final bool showBothPricingChannels;

  static const _textDark = Color(0xFF333333);

  @override
  State<AdRequestOrderInfoCard> createState() => _AdRequestOrderInfoCardState();
}

class _AdRequestOrderInfoCardState extends State<AdRequestOrderInfoCard> {
  // Ad details start collapsed so incoming orders are visible without scrolling.
  bool _expanded = false;

  MyListingProductModel get product => widget.product;
  String get fontFamily => widget.fontFamily;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final isAr =
        Localizations.localeOf(context).languageCode.toLowerCase() == 'ar';
    final productName = RequestDetailsMapper.title(product, s);
    final adDetailsLabel = isAr ? 'تفاصيل الإعلان' : 'Ad details';

    return Padding(
      padding: EdgeInsets.fromLTRB(24.w, 12.h, 24.w, 0),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8.r),
          border: Border.all(color: const Color(0xFFD0D5DD)),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              onTap: () => setState(() => _expanded = !_expanded),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(8.r),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F4FD),
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Icon(
                        Icons.receipt_long_outlined,
                        size: 18.sp,
                        color: const Color(0xFF1E6BB8),
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            adDetailsLabel,
                            style: TextStyle(
                              color: AdRequestOrderInfoCard._textDark,
                              fontFamily: fontFamily,
                              fontSize: 15.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (productName.trim().isNotEmpty) ...[
                            SizedBox(height: 2.h),
                            Text(
                              productName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: const Color(0xFF667085),
                                fontFamily: fontFamily,
                                fontSize: 12.sp,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    SizedBox(width: 8.w),
                    AnimatedRotation(
                      turns: _expanded ? 0.5 : 0.0,
                      duration: const Duration(milliseconds: 200),
                      child: Icon(
                        Icons.keyboard_arrow_down_rounded,
                        size: 24.sp,
                        color: const Color(0xFF667085),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            AnimatedCrossFade(
              firstChild: const SizedBox(width: double.infinity),
              secondChild: _buildDetails(context, s, isAr),
              crossFadeState: _expanded
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 220),
              sizeCurve: Curves.easeInOut,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetails(BuildContext context, S s, bool isAr) {
    final specifications = RequestDetailsMapper.specificationsText(product);
    final showBoth =
        product.isHybridCategoryRetail && widget.showBothPricingChannels;
    final preferRetail = widget.preferRetailPricing;
    final wholesaleQuantity =
        RequestDetailsMapper.quantityText(product, preferRetail: false);
    final retailQuantity =
        RequestDetailsMapper.quantityText(product, preferRetail: true);
    final quantity = showBoth
        ? ''
        : RequestDetailsMapper.quantityText(
            product,
            preferRetail: preferRetail,
          );
    final packaging = RequestDetailsMapper.packagingDisplay(
      product,
      s,
      isAr: isAr,
    );
    final deliveryAddress = RequestDetailsMapper.deliveryAddress(product);
    final receiptDate = RequestDetailsMapper.requestedReceiptDateText(product);
    final notes = RequestDetailsMapper.notesText(product);
    final mediaItems = BookingDetailsMapper.mediaItems(product);
    final displayTypeName = widget.preferRetailPricing
        ? CreateAdType.retail.label
        : (widget.preferCategoryLabel && product.categoryId != null)
            ? CreateAdType.categories.label
            : product.productTypeName;
    final typeLabel = CreateAdType.displayLabel(displayTypeName);
    final statusLabel =
        product.status.trim().isEmpty ? '—' : product.status.trim();
    final hasWholesalePrice =
        ProductPriceFormatter.amount(product, preferRetail: false).isNotEmpty;
    final hasRetailPrice = product.hasRetailPricing &&
        ProductPriceFormatter.amount(product, preferRetail: true).isNotEmpty;
    final hasPrice = showBoth
        ? (hasWholesalePrice || hasRetailPrice)
        : ProductPriceFormatter.amount(
            product,
            preferRetail: preferRetail,
          ).isNotEmpty;
    final showDiscount = CreateAdType.fromLabel(product.productTypeName) ==
            CreateAdType.offers &&
        product.isDiscountActive;
    final fromCountry = product.shipping.routeFromCountry.trim();
    final toCountry = product.shipping.routeToCountry.trim();
    // Treat FOB/booking ads (which may have no ports) as booking so the origin
    // country still shows once the ad is approved.
    final isBooking = product.productTypeId == 2 ||
        RequestDetailsMapper.isBookingFulfillment(product);
    final originCountry = RequestDetailsMapper.originCountryName(product);
    final loadingPort = RequestDetailsMapper.loadingPortName(product);
    final destinationCountry =
        RequestDetailsMapper.destinationCountryName(product);
    final destinationPort = RequestDetailsMapper.destinationPortName(product);
    final statusFieldLabel = isAr ? 'الحالة' : 'Status';
    final adTypeFieldLabel = isAr ? 'نوع الإعلان' : 'Ad type';
    final discountFieldLabel = isAr ? 'الخصم' : 'Discount';
    final routeFieldLabel = isAr ? 'مسار الشحن' : 'Shipping route';
    final wholesalePriceLabel = isAr ? 'سعر الجملة' : 'Wholesale price';
    final retailPriceLabel = isAr ? 'سعر التجزئة' : 'Retail price';
    final wholesaleQtyLabel = isAr ? 'كمية الجملة' : 'Wholesale quantity';
    final retailQtyLabel = isAr ? 'كمية التجزئة' : 'Retail quantity';
    final wholesaleUnitLabel = isAr ? 'وحدة الجملة' : 'Wholesale unit';
    final retailUnitLabel = isAr ? 'وحدة التجزئة' : 'Retail unit';
    final wholesaleUnit = product.unitNameForChannel(preferRetail: false).trim();
    final retailUnit = product.unitNameForChannel(preferRetail: true).trim();
    final priceTypeLabel =
        ProductPriceTypeLabel.fromProduct(product, isAr: isAr);
    final soldOut = ProductStock.isSoldOut(
      product,
      preferRetail: preferRetail,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Divider(height: 1, color: const Color(0xFFEAECF0)),
        Padding(
          padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 16.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (mediaItems.isNotEmpty) ...[
                Builder(
                  builder: (context) {
                    final images =
                        mediaItems.where((m) => !m.isVideo).toList();
                    final videos = mediaItems.where((m) => m.isVideo).toList();
                    return Column(
                      children: [
                        if (images.isNotEmpty)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8.r),
                            child: BookingProductImageCarousel(
                              mediaItems: images,
                              showSoldOutStamp: soldOut,
                            ),
                          ),
                        if (images.isNotEmpty && videos.isNotEmpty)
                          SizedBox(height: 10.h),
                        if (videos.isNotEmpty)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8.r),
                            child: BookingProductImageCarousel(
                              mediaItems: videos,
                              showSoldOutStamp: soldOut,
                            ),
                          ),
                        SizedBox(height: 16.h),
                      ],
                    );
                  },
                ),
              ],
              _InfoRow(
                label: statusFieldLabel,
                value: statusLabel,
                fontFamily: fontFamily,
              ),
              SizedBox(height: 12.h),
              _InfoRow(
                label: adTypeFieldLabel,
                value: typeLabel,
                fontFamily: fontFamily,
              ),
              if ((product.categoryId != null && product.categoryId! > 0) ||
                  product.isRequestProduct ||
                  product.isOfferProduct ||
                  priceTypeLabel.isNotEmpty) ...[
                SizedBox(height: 12.h),
                _InfoRow(
                  label: s.requestFulfillment,
                  value: priceTypeLabel.isNotEmpty ? priceTypeLabel : '—',
                  fontFamily: fontFamily,
                ),
              ],
              if (product.categoryName.trim().isNotEmpty) ...[
                SizedBox(height: 12.h),
                _InfoRow(
                  label: s.category,
                  value: product.categoryName.trim(),
                  fontFamily: fontFamily,
                ),
              ],
              if (product.productId.isNotEmpty) ...[
                SizedBox(height: 12.h),
                ProductViewsBadge(
                  productId: product.productId,
                  initialViewsCount: product.viewsCountValue,
                  fontFamily: fontFamily,
                  trackOnOpen: false,
                ),
              ],
              if (product.createdAt.trim().isNotEmpty) ...[
                SizedBox(height: 12.h),
                _InfoRow(
                  label: isAr ? 'تاريخ ووقت الإضافة' : 'Posted date & time',
                  value: RelativeTimeFormatter.format(s, product.createdAt),
                  fontFamily: fontFamily,
                ),
              ],
              if (hasPrice) ...[
                SizedBox(height: 16.h),
                if (showBoth) ...[
                  if (hasWholesalePrice) ...[
                    Text(
                      wholesalePriceLabel,
                      style: TextStyle(
                        color: Colors.black.withValues(alpha: 0.8),
                        fontFamily: fontFamily,
                        fontSize: 14.sp,
                        height: 1.5,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    ProductPriceText.unitPrice(
                      product,
                      preferRetail: false,
                      amountStyle: TextStyle(
                        color: LightColor.defaultColor,
                        fontFamily: AppFonts.cairo,
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w700,
                      ),
                      matchCurrencyToAmount: true,
                    ),
                  ],
                  if (hasRetailPrice) ...[
                    if (hasWholesalePrice) SizedBox(height: 12.h),
                    Text(
                      retailPriceLabel,
                      style: TextStyle(
                        color: Colors.black.withValues(alpha: 0.8),
                        fontFamily: fontFamily,
                        fontSize: 14.sp,
                        height: 1.5,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    ProductPriceText.unitPrice(
                      product,
                      preferRetail: true,
                      amountStyle: TextStyle(
                        color: LightColor.defaultColor,
                        fontFamily: AppFonts.cairo,
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w700,
                      ),
                      matchCurrencyToAmount: true,
                    ),
                  ],
                ] else ...[
                  Text(
                    s.price,
                    style: TextStyle(
                      color: Colors.black.withValues(alpha: 0.8),
                      fontFamily: fontFamily,
                      fontSize: 14.sp,
                      height: 1.5,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  ProductPriceText.unitPrice(
                    product,
                    preferRetail: preferRetail,
                    amountStyle: TextStyle(
                      color: LightColor.defaultColor,
                      fontFamily: AppFonts.cairo,
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w700,
                    ),
                    matchCurrencyToAmount: true,
                  ),
                ],
              ],
              if (showDiscount) ...[
                SizedBox(height: 12.h),
                _InfoRow(
                  label: discountFieldLabel,
                  value:
                      '${product.discountPercentage.trim().isNotEmpty ? product.discountPercentage.trim() : product.discountPercentValue}%',
                  fontFamily: fontFamily,
                ),
              ],
              if (specifications.isNotEmpty) ...[
                SizedBox(height: 24.h),
                _FieldBlock(
                  label: product.isRequestProduct
                      ? s.requiredSpecifications
                      : s.specifications,
                  value: specifications,
                  fontFamily: fontFamily,
                  valueSize: 13.sp,
                ),
              ],
              if (showBoth &&
                  (wholesaleQuantity.isNotEmpty ||
                      (product.hasRetailPricing &&
                          retailQuantity.isNotEmpty))) ...[
                SizedBox(height: 24.h),
                if (wholesaleQuantity.isNotEmpty)
                  _FieldBlock(
                    label: wholesaleQtyLabel,
                    value: wholesaleQuantity,
                    fontFamily: fontFamily,
                  ),
                if (wholesaleUnit.isNotEmpty) ...[
                  if (wholesaleQuantity.isNotEmpty) SizedBox(height: 12.h),
                  _FieldBlock(
                    label: wholesaleUnitLabel,
                    value: wholesaleUnit,
                    fontFamily: fontFamily,
                  ),
                ],
                if (product.hasRetailPricing &&
                    retailQuantity.isNotEmpty) ...[
                  SizedBox(height: 12.h),
                  _FieldBlock(
                    label: retailQtyLabel,
                    value: retailQuantity,
                    fontFamily: fontFamily,
                  ),
                ],
                if (product.hasRetailPricing && retailUnit.isNotEmpty) ...[
                  SizedBox(height: 12.h),
                  _FieldBlock(
                    label: retailUnitLabel,
                    value: retailUnit,
                    fontFamily: fontFamily,
                  ),
                ],
                if (packaging.isNotEmpty) ...[
                  SizedBox(height: 12.h),
                  _FieldBlock(
                    label: isAr ? 'التعبئة' : 'Packing',
                    value: packaging,
                    fontFamily: fontFamily,
                  ),
                ],
              ] else if (quantity.isNotEmpty || packaging.isNotEmpty) ...[
                SizedBox(height: 24.h),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (quantity.isNotEmpty)
                      Expanded(
                        child: _FieldBlock(
                          label: s.quantity,
                          value: quantity,
                          fontFamily: fontFamily,
                        ),
                      ),
                    if (quantity.isNotEmpty && packaging.isNotEmpty)
                      SizedBox(width: 15.w),
                    if (packaging.isNotEmpty)
                      Expanded(
                        child: _FieldBlock(
                          label: isAr ? 'التعبئة' : 'Packing',
                          value: packaging,
                          fontFamily: fontFamily,
                        ),
                      ),
                  ],
                ),
              ],
              if (isBooking) ...[
                if (originCountry.isNotEmpty) ...[
                  SizedBox(height: 18.h),
                  _InfoRow(
                    label: s.countryOfOrigin,
                    value: originCountry,
                    fontFamily: fontFamily,
                  ),
                ],
                if (loadingPort.isNotEmpty) ...[
                  SizedBox(height: 12.h),
                  _InfoRow(
                    label: s.loadingPort,
                    value: loadingPort,
                    fontFamily: fontFamily,
                  ),
                ],
                if (destinationCountry.isNotEmpty) ...[
                  SizedBox(height: 12.h),
                  _InfoRow(
                    label: s.destinationCountry,
                    value: destinationCountry,
                    fontFamily: fontFamily,
                  ),
                ],
                if (destinationPort.isNotEmpty) ...[
                  SizedBox(height: 12.h),
                  _InfoRow(
                    label: s.destinationPort,
                    value: destinationPort,
                    fontFamily: fontFamily,
                  ),
                ],
              ] else ...[
                if (fromCountry.isNotEmpty || toCountry.isNotEmpty) ...[
                  SizedBox(height: 18.h),
                  _InfoRow(
                    label: routeFieldLabel,
                    value: [
                      if (fromCountry.isNotEmpty) fromCountry,
                      if (toCountry.isNotEmpty) toCountry,
                    ].join(' → '),
                    fontFamily: fontFamily,
                  ),
                ],
                if (deliveryAddress.isNotEmpty) ...[
                  SizedBox(height: 18.h),
                  _InfoRow(
                    label: s.deliveryAddress,
                    value: deliveryAddress,
                    fontFamily: fontFamily,
                  ),
                ],
              ],
              if (receiptDate.isNotEmpty) ...[
                SizedBox(height: 12.h),
                _InfoRow(
                  label: s.requestedReceiptDate,
                  value: receiptDate,
                  fontFamily: fontFamily,
                ),
              ],
              if (notes.isNotEmpty) ...[
                SizedBox(height: 12.h),
                _InfoRow(
                  label: s.additionalNotes,
                  value: notes,
                  fontFamily: fontFamily,
                ),
              ],
              if (_isRejectedWithReason(product)) ...[
                SizedBox(height: 12.h),
                _InfoRow(
                  label: s.rejectionReason,
                  value: product.supplierNotes.trim(),
                  fontFamily: fontFamily,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  bool _isRejectedWithReason(MyListingProductModel item) {
    final status = item.status.toLowerCase();
    final approval = item.approvalStatus.toLowerCase();
    return (status.contains('reject') || approval.contains('reject')) &&
        item.supplierNotes.trim().isNotEmpty;
  }
}

class _FieldBlock extends StatelessWidget {
  const _FieldBlock({
    required this.label,
    required this.value,
    required this.fontFamily,
    this.valueSize,
  });

  final String label;
  final String value;
  final String fontFamily;
  final double? valueSize;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.black.withValues(alpha: 0.8),
            fontFamily: fontFamily,
            fontSize: 14.sp,
            height: 1.5,
          ),
        ),
        SizedBox(height: 12.h),
        Text(
          value,
          style: TextStyle(
            color: Colors.black,
            fontFamily: fontFamily,
            fontSize: valueSize ?? 14.sp,
            fontWeight: FontWeight.w800,
            height: 1.5,
          ),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
    required this.fontFamily,
  });

  final String label;
  final String value;
  final String fontFamily;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: AdRequestOrderInfoCard._textDark.withValues(alpha: 0.8),
            fontFamily: fontFamily,
            fontSize: 14.sp,
            height: 1.5,
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: TextStyle(
              color: AdRequestOrderInfoCard._textDark.withValues(alpha: 0.8),
              fontFamily: fontFamily,
              fontSize: 14.sp,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }
}
