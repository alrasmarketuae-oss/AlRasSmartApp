import 'package:alrasmarket/core/widgets/cached_app_image.dart';
import 'package:alrasmarket/features/clint/data/models/my_order_model.dart';
import 'package:alrasmarket/features/clint/presentation/widgets/product_media/product_video_thumbnail.dart';
import 'package:alrasmarket/features/clint/presentation/widgets/track_order_widgets/track_order_status_helper.dart';
import 'package:alrasmarket/generated/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class TrackOrderSummaryCard extends StatelessWidget {
  const TrackOrderSummaryCard({
    super.key,
    required this.order,
    required this.fontFamily,
  });

  final MyOrderModel order;
  final String fontFamily;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final imageUrl = order.resolvedPrimaryImageUrl;
    final videoUrl = order.resolvedPrimaryVideoUrl;
    final thumbSize = 72.w;
    final productName = order.localizedProductName(isArabic: isArabic);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: const Color(0xFFEAECF0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8.r),
                child: SizedBox(
                  width: thumbSize,
                  height: thumbSize,
                  child: _mediaThumb(
                    imageUrl: imageUrl,
                    videoUrl: videoUrl,
                    size: thumbSize,
                  ),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      productName.isEmpty ? '—' : productName,
                      style: TextStyle(
                        color: const Color(0xFF333333),
                        fontFamily: fontFamily,
                        fontSize: 15.sp,
                        fontWeight: FontWeight.bold,
                        height: 1.4,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      TrackOrderStatusHelper.quantityLabel(
                        order,
                        s,
                        isArabic: isArabic,
                      ),
                      style: _detailStyle(fontFamily),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      '${s.destination}: ${TrackOrderStatusHelper.destinationLabel(order, isArabic: isArabic)}',
                      style: _detailStyle(fontFamily),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Text(
            TrackOrderStatusHelper.orderNumberLabel(order, s),
            style: TextStyle(
              color: const Color(0xFF333333),
              fontFamily: fontFamily,
              fontSize: 14.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _mediaThumb({
    required String? imageUrl,
    required String? videoUrl,
    required double size,
  }) {
    if (imageUrl != null) {
      return CachedAppImage(
        imageUrl: imageUrl,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorWidget: videoUrl != null
            ? ProductVideoThumbnail(
                videoUrl: videoUrl,
                width: size,
                height: size,
                showPlayChrome: true,
              )
            : _emptyTile(size),
      );
    }

    if (videoUrl != null) {
      return ProductVideoThumbnail(
        videoUrl: videoUrl,
        width: size,
        height: size,
        showPlayChrome: true,
      );
    }

    return _emptyTile(size);
  }

  Widget _emptyTile(double size) {
    return Container(
      width: size,
      height: size,
      color: const Color(0xFFF2F4F7),
    );
  }

  TextStyle _detailStyle(String fontFamily) {
    return TextStyle(
      color: const Color(0xFF333333).withValues(alpha: 0.65),
      fontFamily: fontFamily,
      fontSize: 13.sp,
      height: 1.4,
    );
  }
}
