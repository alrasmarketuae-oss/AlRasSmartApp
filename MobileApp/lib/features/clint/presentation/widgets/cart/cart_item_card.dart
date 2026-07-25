import 'package:alrasmarket/core/utils/product_price_formatter.dart';
import 'package:alrasmarket/core/utils/string_display_format.dart';
import 'package:alrasmarket/core/widgets/cached_app_image.dart';
import 'package:alrasmarket/core/widgets/product_price_text.dart';
import 'package:alrasmarket/core/utils/assets.dart';
import 'package:alrasmarket/features/clint/domain/entities/cart_item_entity.dart';
import 'package:alrasmarket/features/clint/presentation/widgets/cart/cart_design.dart';
import 'package:alrasmarket/features/clint/presentation/widgets/cart/cart_quantity_selector.dart';
import 'package:alrasmarket/features/clint/presentation/widgets/product_media/product_video_play_mark.dart';
import 'package:alrasmarket/features/clint/presentation/widgets/product_media/product_video_thumbnail.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class CartItemCard extends StatelessWidget {
  const CartItemCard({
    super.key,
    required this.item,
    required this.onIncrement,
    required this.onDecrement,
    required this.onDelete,
    this.isUpdating = false,
    this.showDelete = true,
  });

  final CartItemEntity item;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final VoidCallback onDelete;
  final bool isUpdating;
  final bool showDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: CartDesign.cardBg,
        borderRadius: CartDesign.cardRadius,
        boxShadow: CartDesign.cardShadow,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10.r),
            child: _buildThumbnail(),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        item.productName.capitalizeFirst(),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w800,
                          color: CartDesign.text,
                          height: 1.35,
                        ),
                      ),
                    ),
                    if (showDelete) ...[
                      SizedBox(width: 8.w),
                      InkWell(
                        onTap: isUpdating ? null : onDelete,
                        borderRadius: BorderRadius.circular(20.r),
                        child: Icon(
                          Icons.delete_outline_rounded,
                          size: 20.sp,
                          color: isUpdating
                              ? CartDesign.muted.withValues(alpha: 0.45)
                              : CartDesign.danger,
                        ),
                      ),
                    ],
                  ],
                ),
                SizedBox(height: 4.h),
                Text(
                  item.quantityLabel,
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: CartDesign.muted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 12.h),
                Row(
                  children: [
                    CartQuantitySelector(
                      quantity: item.quantity.round(),
                      onIncrement: onIncrement,
                      onDecrement: onDecrement,
                      isEnabled: !isUpdating,
                      canIncrement: item.canIncrement,
                    ),
                    const Spacer(),
                    if (ProductPriceFormatter.canShowPrices)
                      ProductPriceText(
                        amount: item.unitPriceAmount,
                        currency: 'AED',
                        amountStyle: TextStyle(
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w800,
                          color: CartDesign.priceGreen,
                        ),
                        matchCurrencyToAmount: true,
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThumbnail() {
    final imageUrl = item.imageUrl?.trim();
    if (imageUrl != null && imageUrl.isNotEmpty) {
      final videoUrl = item.videoUrl?.trim();
      final hasVideo = videoUrl != null && videoUrl.isNotEmpty;
      return SizedBox(
        width: 76.w,
        height: 76.w,
        child: Stack(
          fit: StackFit.expand,
          children: [
            CachedAppImage(
              imageUrl: imageUrl,
              fit: BoxFit.cover,
              errorWidget: _fallbackMedia(),
            ),
            if (hasVideo) const Center(child: ProductVideoPlayMark()),
          ],
        ),
      );
    }

    return _fallbackMedia();
  }

  Widget _fallbackMedia() {
    final videoUrl = item.videoUrl?.trim();
    if (videoUrl != null && videoUrl.isNotEmpty) {
      return ProductVideoThumbnail(
        videoUrl: videoUrl,
        durationSeconds: item.videoDurationSeconds,
        width: 76.w,
        height: 76.w,
        showPlayChrome: true,
      );
    }
    return _placeholderImage();
  }

  Widget _placeholderImage() {
    return Image.asset(
      AppAssets.bannerImage2,
      width: 76.w,
      height: 76.w,
      fit: BoxFit.cover,
    );
  }
}
