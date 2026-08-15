import 'package:alrasmarket/core/theme/colors.dart';
import 'package:alrasmarket/core/utils/product_quantity_formatter.dart';
import 'package:alrasmarket/core/utils/relative_time_formatter.dart';
import 'package:alrasmarket/core/widgets/cached_app_image.dart';
import 'package:alrasmarket/core/widgets/product_price_text.dart';
import 'package:alrasmarket/features/clint/presentation/models/product_media_item.dart';
import 'package:alrasmarket/features/clint/presentation/widgets/product_media/product_media_preview_screen.dart';
import 'package:alrasmarket/features/clint/presentation/widgets/product_media/product_video_thumbnail.dart';
import 'package:alrasmarket/features/clint/presentation/widgets/track_order_widgets/order_status_style.dart';
import 'package:alrasmarket/features/clint/presentation/widgets/track_order_widgets/track_order_status_helper.dart';
import 'package:alrasmarket/features/company/data/models/my_request_offer_model.dart';
import 'package:alrasmarket/features/company/presentation/helpers/create_ad_form_mapper.dart';
import 'package:alrasmarket/features/company/presentation/helpers/create_ad_price_labels.dart';
import 'package:alrasmarket/features/company/presentation/models/create_ad_currency.dart';
import 'package:alrasmarket/generated/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class RequestOfferCard extends StatelessWidget {
  const RequestOfferCard({
    super.key,
    required this.offer,
    required this.fontFamily,
    required this.isUpdating,
    this.onAccept,
    this.onReject,
    this.onTrack,
    this.acceptLabel,
    this.rejectLabel,
  });

  final MyRequestOfferModel offer;
  final String fontFamily;
  final bool isUpdating;
  final VoidCallback? onAccept;
  final VoidCallback? onReject;
  final VoidCallback? onTrack;
  final String? acceptLabel;
  final String? rejectLabel;

  static Color get _textDark => AppColors.titleColor;
  static const _actionBlue = Color(0xFF3A7DC5);
  static const _actionRed = Color(0xFFC83D30);
  static final _amountFormat = NumberFormat('#,##0.##');

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final quantityText = _quantityText(s);
    final deliveryText = _deliveryText();
    final specificationsText = offer.notes.trim();
    final unitPriceAmount = _unitPriceAmount();
    final totalPriceAmount = _totalPriceAmount();
    final hasUnitPrice = unitPriceAmount.isNotEmpty;
    final hasTotalPrice = totalPriceAmount.isNotEmpty;
    final currency = _resolvedCurrency();
    final unitPriceLabel = CreateAdPriceLabels.pricePerUnitLabel(
      s,
      offer.unitName,
    );
    final mediaItems = _mediaItems();
    final statusLabel = _statusLabel(s, isArabic);
    final statusColors = OrderStatusStyle.forStatusId(
      offer.statusId,
      fallbackName: offer.statusName,
    );
    final orderTime = RelativeTimeFormatter.format(s, offer.createdAt);
    final showOrderMeta = offer.orderId > 0 || orderTime.isNotEmpty;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 20.h),
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: AppColors.border(context)),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.15),
            offset: Offset.zero,
            blurRadius: 4,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  offer.productName.trim().isEmpty
                      ? '—'
                      : offer.productName.trim(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: _textDark,
                    fontFamily: fontFamily,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w700,
                    height: 1.5,
                  ),
                ),
              ),
              SizedBox(width: 12.w),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: statusColors.background,
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Text(
                  statusLabel,
                  style: TextStyle(
                    color: statusColors.foreground,
                    fontFamily: fontFamily,
                    fontSize: 12.sp,
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
          if (showOrderMeta) ...[
            SizedBox(height: 8.h),
            Row(
              children: [
                if (offer.orderId > 0)
                  Expanded(
                    child: Text(
                      '${s.orderNumber}: #${offer.orderId}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: _textDark.withValues(alpha: 0.65),
                        fontFamily: fontFamily,
                        fontSize: 12.sp,
                        height: 1.4,
                      ),
                    ),
                  ),
                if (orderTime.isNotEmpty)
                  Text(
                    orderTime,
                    style: TextStyle(
                      color: _textDark.withValues(alpha: 0.55),
                      fontFamily: fontFamily,
                      fontSize: 12.sp,
                      height: 1.4,
                    ),
                  ),
              ],
            ),
          ],
          SizedBox(height: 14.h),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (mediaItems.isNotEmpty) ...[
                GestureDetector(
                  onTap: () => _openMediaPreview(context, mediaItems, 0),
                  child: _OfferMediaThumb(
                    path: offer.imagePaths.first,
                    width: 72.w,
                    height: 72.w,
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                ),
                SizedBox(width: 12.w),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (deliveryText.isNotEmpty || quantityText.isNotEmpty)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (deliveryText.isNotEmpty)
                            Expanded(
                              child: _MetricColumn(
                                label: s.delivery,
                                value: deliveryText,
                                fontFamily: fontFamily,
                              ),
                            ),
                          if (deliveryText.isNotEmpty &&
                              quantityText.isNotEmpty)
                            SizedBox(width: 20.w),
                          if (quantityText.isNotEmpty)
                            Expanded(
                              child: _MetricColumn(
                                label: s.quantity,
                                value: quantityText,
                                fontFamily: fontFamily,
                              ),
                            ),
                        ],
                      ),
                    if ((deliveryText.isNotEmpty || quantityText.isNotEmpty) &&
                        (hasUnitPrice || hasTotalPrice))
                      SizedBox(height: 14.h),
                    if (hasUnitPrice || hasTotalPrice)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (hasUnitPrice)
                            Expanded(
                              child: _MetricColumn(
                                label: unitPriceLabel,
                                fontFamily: fontFamily,
                                valueWidget: ProductPriceText(
                                  amount: unitPriceAmount,
                                  currency: currency,
                                  amountStyle: TextStyle(
                                    color: _textDark,
                                    fontFamily: fontFamily,
                                    fontSize: 14.sp,
                                    fontWeight: FontWeight.w600,
                                    height: 1.5,
                                  ),
                                  iconSize: 16,
                                ),
                              ),
                            ),
                          if (hasUnitPrice && hasTotalPrice)
                            SizedBox(width: 20.w),
                          if (hasTotalPrice)
                            Expanded(
                              child: _MetricColumn(
                                label: s.total,
                                fontFamily: fontFamily,
                                valueWidget: ProductPriceText(
                                  amount: totalPriceAmount,
                                  currency: currency,
                                  amountStyle: TextStyle(
                                    color: _textDark,
                                    fontFamily: fontFamily,
                                    fontSize: 14.sp,
                                    fontWeight: FontWeight.w700,
                                    height: 1.5,
                                  ),
                                  iconSize: 16,
                                ),
                              ),
                            ),
                        ],
                      ),
                  ],
                ),
              ),
            ],
          ),
          if (mediaItems.length > 1) ...[
            SizedBox(height: 12.h),
            SizedBox(
              height: 56.h,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: mediaItems.length,
                separatorBuilder: (_, __) => SizedBox(width: 8.w),
                itemBuilder: (context, index) {
                  return GestureDetector(
                    onTap: () => _openMediaPreview(context, mediaItems, index),
                    child: _OfferMediaThumb(
                      path: offer.imagePaths[index],
                      width: 56.w,
                      height: 56.h,
                      borderRadius: BorderRadius.circular(6.r),
                    ),
                  );
                },
              ),
            ),
          ],
          if (offer.documentPaths.isNotEmpty) ...[
            SizedBox(height: 16.h),
            Text(
              s.productDocuments,
              style: TextStyle(
                color: _textDark.withValues(alpha: 0.8),
                fontFamily: fontFamily,
                fontSize: 14.sp,
                height: 1.5,
              ),
            ),
            SizedBox(height: 8.h),
            Wrap(
              spacing: 8.w,
              runSpacing: 8.h,
              children: [
                for (var i = 0; i < offer.documentPaths.length; i++)
                  _DocumentChip(
                    label: 'Doc ${i + 1}',
                    fontFamily: fontFamily,
                    onTap: () => _openDocument(offer.documentPaths[i]),
                  ),
              ],
            ),
          ],
          if (specificationsText.isNotEmpty) ...[
            SizedBox(height: 16.h),
            _SpecificationsBlock(
              label: s.specifications,
              value: specificationsText,
              fontFamily: fontFamily,
            ),
          ],
          if (onTrack != null) ...[
            SizedBox(height: 16.h),
            _TrackOrderButton(
              label: s.trackOrder,
              fontFamily: fontFamily,
              onPressed: onTrack,
            ),
          ],
          if (onAccept != null || onReject != null) ...[
            SizedBox(height: 12.h),
            Row(
              children: [
                if (onAccept != null)
                  Expanded(
                    child: _ActionChip(
                      label: acceptLabel ?? s.acceptOffer,
                      backgroundColor: _actionBlue,
                      fontFamily: fontFamily,
                      isLoading: isUpdating,
                      onPressed: isUpdating ? null : onAccept,
                    ),
                  ),
                if (onAccept != null && onReject != null) SizedBox(width: 12.w),
                if (onReject != null)
                  Expanded(
                    child: _ActionChip(
                      label: rejectLabel ?? s.rejectOffer,
                      backgroundColor: _actionRed,
                      fontFamily: fontFamily,
                      isLoading: isUpdating,
                      onPressed: isUpdating ? null : onReject,
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _openDocument(String path) async {
    final url = MyRequestOfferModel.resolveAssetUrl(path);
    if (url == null) return;
    final uri = Uri.parse(url);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  List<ProductMediaItem> _mediaItems() {
    final items = <ProductMediaItem>[];
    for (final path in offer.imagePaths) {
      final url = MyRequestOfferModel.resolveAssetUrl(path);
      if (url == null) continue;
      items.add(
        ProductMediaItem(
          url: url,
          kind: CreateAdFormMapper.isVideoPath(path)
              ? ProductMediaKind.video
              : ProductMediaKind.image,
        ),
      );
    }
    return items;
  }

  void _openMediaPreview(
    BuildContext context,
    List<ProductMediaItem> items,
    int index,
  ) {
    ProductMediaPreviewScreen.open(
      context,
      items: items,
      initialIndex: index,
    );
  }

  String _quantityText(S s) {
    if (offer.quantity <= 0) return '';
    final qty = offer.quantity == offer.quantity.roundToDouble()
        ? offer.quantity.toInt().toString()
        : offer.quantity.toString();
    return ProductQuantityFormatter.quantityWithUnit(
      quantityText: qty,
      unitName: offer.unitName,
      s: s,
    );
  }

  String _deliveryText() {
    final country = offer.destinationCountryName.trim();
    if (country.isNotEmpty) return country;
    return offer.portName.trim();
  }

  String _unitPriceAmount() {
    if (offer.unitPrice > 0) {
      return _amountFormat.format(offer.unitPrice);
    }

    return _numericFromFormatted(offer.unitPriceFormatted);
  }

  String _totalPriceAmount() {
    if (offer.totalPrice > 0) {
      return _amountFormat.format(offer.totalPrice);
    }

    // Prefer explicit total; if missing, fall back only when quantity exists.
    if (offer.unitPrice > 0 && offer.quantity > 0) {
      return _amountFormat.format(offer.unitPrice * offer.quantity);
    }

    return _numericFromFormatted(offer.totalPriceFormatted);
  }

  String _numericFromFormatted(String formatted) {
    final trimmed = formatted.trim();
    if (trimmed.isEmpty) return '';
    return trimmed.replaceAll(RegExp(r'[^0-9.,]'), '').trim();
  }

  String _statusLabel(S s, bool isArabic) {
    if (offer.statusId == OrderStatusCodes.awaitingSellerApproval) {
      return s.awaitingYourApproval;
    }
    return offer.statusLabel(isArabic: isArabic);
  }

  String _resolvedCurrency() {
    final code = offer.currency.trim();
    if (code.isNotEmpty) {
      return CreateAdCurrency.normalize(code);
    }

    final formatted = offer.unitPriceFormatted.isNotEmpty
        ? offer.unitPriceFormatted.toUpperCase()
        : offer.totalPriceFormatted.toUpperCase();
    if (formatted.contains('USD') || formatted.startsWith('\$')) {
      return CreateAdCurrency.usd;
    }
    return CreateAdCurrency.aed;
  }
}

class _OfferMediaThumb extends StatelessWidget {
  const _OfferMediaThumb({
    required this.path,
    required this.width,
    required this.height,
    this.borderRadius,
  });

  final String path;
  final double width;
  final double height;
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    final url = MyRequestOfferModel.resolveAssetUrl(path);
    final radius = borderRadius ?? BorderRadius.zero;

    if (url == null) {
      return ClipRRect(
        borderRadius: radius,
        child: SizedBox(
          width: width,
          height: height,
          child: ColoredBox(
            color: const Color(0xFFF3F4F6),
            child: Icon(Icons.image_not_supported_outlined, size: 24.sp),
          ),
        ),
      );
    }

    if (CreateAdFormMapper.isVideoPath(path)) {
      return ProductVideoThumbnail(
        videoUrl: url,
        width: width,
        height: height,
        borderRadius: radius,
      );
    }

    return ClipRRect(
      borderRadius: radius,
      child: CachedAppImage(
        imageUrl: url,
        width: width,
        height: height,
        fit: BoxFit.cover,
        errorWidget: ColoredBox(
          color: const Color(0xFFF3F4F6),
          child: Icon(Icons.image_not_supported_outlined, size: 24.sp),
        ),
      ),
    );
  }
}

class _SpecificationsBlock extends StatelessWidget {
  const _SpecificationsBlock({
    required this.label,
    required this.value,
    required this.fontFamily,
  });

  final String label;
  final String value;
  final String fontFamily;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: const Color(0xFFEAECF0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.description_outlined,
                size: 18.sp,
                color: RequestOfferCard._actionBlue,
              ),
              SizedBox(width: 8.w),
              Text(
                label,
                style: TextStyle(
                  color: RequestOfferCard._textDark,
                  fontFamily: fontFamily,
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  height: 1.4,
                ),
              ),
            ],
          ),
          SizedBox(height: 10.h),
          Text(
            value,
            style: TextStyle(
              color: RequestOfferCard._textDark.withValues(alpha: 0.85),
              fontFamily: fontFamily,
              fontSize: 13.sp,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricColumn extends StatelessWidget {
  const _MetricColumn({
    required this.label,
    required this.fontFamily,
    this.value,
    this.valueWidget,
  });

  final String label;
  final String? value;
  final Widget? valueWidget;
  final String fontFamily;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(
            color: RequestOfferCard._textDark.withValues(alpha: 0.8),
            fontFamily: fontFamily,
            fontSize: 14.sp,
            height: 1.5,
          ),
        ),
        SizedBox(height: 12.h),
        valueWidget ??
            Text(
              value ?? '',
              style: TextStyle(
                color: RequestOfferCard._textDark,
                fontFamily: fontFamily,
                fontSize: 14.sp,
                height: 1.5,
              ),
            ),
      ],
    );
  }
}

class _DocumentChip extends StatelessWidget {
  const _DocumentChip({
    required this.label,
    required this.fontFamily,
    required this.onTap,
  });

  final String label;
  final String fontFamily;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFEFF6FF),
      borderRadius: BorderRadius.circular(8.r),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8.r),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.insert_drive_file_rounded,
                size: 18.sp,
                color: RequestOfferCard._actionBlue,
              ),
              SizedBox(width: 6.w),
              Text(
                label,
                style: TextStyle(
                  color: RequestOfferCard._actionBlue,
                  fontFamily: fontFamily,
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TrackOrderButton extends StatelessWidget {
  const _TrackOrderButton({
    required this.label,
    required this.fontFamily,
    required this.onPressed,
  });

  final String label;
  final String fontFamily;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(8.r),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8.r),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8.r),
            border: Border.all(color: RequestOfferCard._actionBlue),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.local_shipping_outlined,
                size: 18.sp,
                color: RequestOfferCard._actionBlue,
              ),
              SizedBox(width: 8.w),
              Text(
                label,
                style: TextStyle(
                  color: RequestOfferCard._actionBlue,
                  fontFamily: fontFamily,
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w700,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionChip extends StatelessWidget {
  const _ActionChip({
    required this.label,
    required this.backgroundColor,
    required this.fontFamily,
    required this.isLoading,
    this.onPressed,
  });

  final String label;
  final Color backgroundColor;
  final String fontFamily;
  final bool isLoading;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(8.r),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8.r),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
          child: SizedBox(
            width: double.infinity,
            child: isLoading
                ? Center(
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                        backgroundColor: Colors.white.withValues(alpha: 0.24),
                      ),
                    ),
                  )
                : Text(
                    label,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontFamily: fontFamily,
                      fontSize: 14.sp,
                      height: 1.5,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
