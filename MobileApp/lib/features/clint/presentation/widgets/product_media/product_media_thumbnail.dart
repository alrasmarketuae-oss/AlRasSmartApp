import 'package:alrasmarket/core/utils/assets.dart';
import 'package:alrasmarket/core/utils/product_stock.dart';
import 'package:alrasmarket/core/widgets/cached_app_image.dart';
import 'package:alrasmarket/features/clint/presentation/widgets/booking_widets/booking_details_mapper.dart';
import 'package:alrasmarket/features/clint/presentation/widgets/product_media/product_media_preview_screen.dart';
import 'package:alrasmarket/features/clint/presentation/widgets/product_media/product_sold_out_stamp_overlay.dart';
import 'package:alrasmarket/features/clint/presentation/widgets/product_media/product_video_play_mark.dart';
import 'package:alrasmarket/features/clint/presentation/widgets/product_media/product_video_thumbnail.dart';
import 'package:alrasmarket/features/company/data/models/my_listing_product_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Card/list thumbnail with optional video play + duration chrome.
class ProductMediaThumbnail extends StatelessWidget {
  const ProductMediaThumbnail({
    super.key,
    required this.product,
    required this.width,
    required this.height,
    this.borderRadius,
    this.initialPreviewIndex = 0,
    this.alignment = Alignment.center,
    this.openPreviewOnTap = true,
    this.showVideoChrome = true,
    this.accentColor,
    this.showDefaultPlaceholderImage = true,
    this.preferRetailChannel = false,
    this.showSoldOutStamp,
  });

  final MyListingProductModel product;
  final double width;
  final double height;
  final BorderRadius? borderRadius;
  final int initialPreviewIndex;
  final Alignment alignment;
  final bool openPreviewOnTap;
  final bool showVideoChrome;
  /// Kept for API compatibility; play mark uses shared styling.
  final Color? accentColor;
  /// When false, empty media shows a neutral blank tile (no bundled image).
  final bool showDefaultPlaceholderImage;
  final bool preferRetailChannel;
  /// When null, derived from [ProductStock.isSoldOut].
  final bool? showSoldOutStamp;

  @override
  Widget build(BuildContext context) {
    final mediaItems = BookingDetailsMapper.mediaItems(product);
    final thumbnailUrl = BookingDetailsMapper.cardThumbnailUrl(product);
    final videoUrl = BookingDetailsMapper.videoUrl(product);
    final hasVideo = videoUrl != null;
    final durationSeconds =
        BookingDetailsMapper.cardVideoDurationSeconds(product);
    final radius = borderRadius ?? BorderRadius.zero;
    final soldOut = showSoldOutStamp ??
        ProductStock.isSoldOut(product, preferRetail: preferRetailChannel);

    Widget child;
    if (thumbnailUrl != null) {
      child = CachedAppImage(
        imageUrl: thumbnailUrl,
        fit: BoxFit.cover,
        alignment: alignment,
        width: width,
        height: height,
        errorWidget: _emptyTile(),
      );
    } else if (videoUrl != null) {
      child = ProductVideoThumbnail(
        videoUrl: videoUrl,
        durationSeconds: durationSeconds,
        width: width,
        height: height,
        showPlayChrome: showVideoChrome,
      );
    } else {
      child = showDefaultPlaceholderImage ? _placeholderImage() : _emptyTile();
    }

    final overlayChrome = showVideoChrome && hasVideo && thumbnailUrl != null;

    final stacked = ProductSoldOutStampOverlay(
      visible: soldOut,
      child: Stack(
        fit: StackFit.expand,
        children: [
          child,
          if (overlayChrome) ...[
            const Center(child: ProductVideoPlayMark()),
            if (_durationLabel(durationSeconds).isNotEmpty)
              Positioned(
                left: 8.w,
                bottom: 8.h,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.72),
                    borderRadius: BorderRadius.circular(4.r),
                  ),
                  child: Text(
                    _durationLabel(durationSeconds),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
          ],
        ],
      ),
    );

    return GestureDetector(
      onTap: !openPreviewOnTap || mediaItems.isEmpty
          ? null
          : () => ProductMediaPreviewScreen.open(
                context,
                items: mediaItems,
                initialIndex: initialPreviewIndex,
              ),
      behavior: HitTestBehavior.opaque,
      child: ClipRRect(
        borderRadius: radius,
        child: SizedBox(
          width: width,
          height: height,
          child: stacked,
        ),
      ),
    );
  }

  String _durationLabel(int? total) {
    if (total == null || total <= 0) return '';
    final minutes = total ~/ 60;
    final seconds = (total % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  Widget _placeholderImage() {
    return Image.asset(
      AppAssets.bannerImage2,
      fit: BoxFit.cover,
      alignment: alignment,
    );
  }

  Widget _emptyTile() {
    return Container(
      width: width,
      height: height,
      color: const Color(0xFFF2F4F7),
    );
  }
}
