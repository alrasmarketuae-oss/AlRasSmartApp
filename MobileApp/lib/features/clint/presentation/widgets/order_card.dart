import 'package:alrasmarket/core/utils/order_price_formatter.dart';
import 'package:alrasmarket/core/router/app_router.dart';
import 'package:alrasmarket/core/theme/app_fonts.dart';
import 'package:alrasmarket/core/theme/colors.dart';
import 'package:alrasmarket/core/widgets/primary_button.dart';
import 'package:alrasmarket/core/utils/product_quantity_formatter.dart';
import 'package:alrasmarket/core/utils/relative_time_formatter.dart';
import 'package:alrasmarket/core/widgets/cached_app_image.dart';
import 'package:alrasmarket/core/widgets/product_price_text.dart';
import 'package:alrasmarket/core/utils/string_display_format.dart';
import 'package:alrasmarket/features/clint/data/models/my_order_model.dart';
import 'package:alrasmarket/features/clint/presentation/widgets/product_media/product_video_play_mark.dart';
import 'package:alrasmarket/features/clint/presentation/widgets/product_media/product_video_thumbnail.dart';
import 'package:alrasmarket/features/clint/presentation/widgets/track_order_widgets/order_status_style.dart';
import 'package:alrasmarket/features/clint/presentation/widgets/track_order_widgets/track_order_status_helper.dart';
import 'package:alrasmarket/generated/l10n.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class OrderCard extends StatefulWidget {
  const OrderCard({
    super.key,
    required this.order,
    this.onAdTap,
    this.onTrackTap,
    this.highlighted = false,
  });

  final MyOrderModel order;
  final VoidCallback? onAdTap;
  final VoidCallback? onTrackTap;
  final bool highlighted;

  @override
  State<OrderCard> createState() => _OrderCardState();
}

class _OrderCardState extends State<OrderCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _blink;

  @override
  void initState() {
    super.initState();
    _blink = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
    if (widget.highlighted) {
      _runBlink();
    }
  }

  @override
  void didUpdateWidget(covariant OrderCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.highlighted && !oldWidget.highlighted) {
      _runBlink();
    }
    if (!widget.highlighted && oldWidget.highlighted) {
      _blink.stop();
      _blink.value = 0;
    }
  }

  Future<void> _runBlink() async {
    for (var i = 0; i < 4; i++) {
      if (!mounted || !widget.highlighted) return;
      await _blink.forward();
      if (!mounted || !widget.highlighted) return;
      await _blink.reverse();
    }
  }

  @override
  void dispose() {
    _blink.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    final s = S.of(context);
    final fontFamily = AppFonts.familyFor(Localizations.localeOf(context));
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final statusLabel = TrackOrderStatusHelper.displayStatusLabel(
      order,
      isArabic: isArabic,
    );
    final statusColors = OrderStatusStyle.forOrder(order);
    final imageUrl = order.resolvedPrimaryImageUrl;
    final videoUrl = order.resolvedPrimaryVideoUrl;
    final details = order
        .localizedProductDescription(isArabic: isArabic)
        .trim();

    final qtyText = () {
      final qty = order.quantity;
      final raw =
          qty == qty.roundToDouble() ? qty.toInt().toString() : qty.toString();
      final withUnit = ProductQuantityFormatter.quantityWithUnit(
        quantityText: raw,
        unitName: order.localizedUnitName(isArabic: isArabic),
        s: s,
      );
      return withUnit.isEmpty ? raw : withUnit;
    }();

    return AnimatedBuilder(
      animation: _blink,
      builder: (context, child) {
        final t = widget.highlighted ? _blink.value : 0.0;
        final borderColor = Color.lerp(
          AppColors.border(context),
          LightColor.defaultColor,
          t,
        )!;
        final bgColor = Color.lerp(
          AppColors.card(context),
          AppColors.isDark(context)
              ? const Color(0xFF243044)
              : const Color(0xFFE8F4FD),
          t,
        )!;
        final glow = LightColor.defaultColor.withValues(alpha: 0.08 + 0.22 * t);

        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onAdTap,
            borderRadius: BorderRadius.circular(16.r),
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(
                  color: borderColor,
                  width: widget.highlighted ? 1.5 + t : 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: widget.highlighted
                        ? glow
                        : Colors.black.withValues(alpha: 0.06),
                    blurRadius: widget.highlighted ? 12 + 8 * t : 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: child,
            ),
          ),
        );
      },
      child: Padding(
        padding: EdgeInsets.all(12.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _OrderThumb(
                  imageUrl: imageUrl,
                  videoUrl: videoUrl,
                  size: 88.w,
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Flexible(
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 8.w,
                                vertical: 4.h,
                              ),
                              decoration: BoxDecoration(
                                color: statusColors.background,
                                borderRadius: BorderRadius.circular(8.r),
                              ),
                              child: Text(
                                statusLabel.isEmpty
                                    ? order.statusName
                                    : statusLabel,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: statusColors.foreground,
                                  fontFamily: fontFamily,
                                  fontSize: 11.sp,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 4.w),
                          Icon(
                            Icons.more_vert_rounded,
                            size: 18.sp,
                            color: const Color(0xFF94A3B8),
                          ),
                        ],
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        () {
                          final name = order.localizedProductName(
                            isArabic: isArabic,
                          );
                          return name.isEmpty
                              ? '—'
                              : name.capitalizeFirst();
                        }(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: fontFamily,
                          fontWeight: FontWeight.w700,
                          fontSize: 15.sp,
                          height: 1.3,
                          color: const Color(0xFF1E293B),
                        ),
                      ),
                      if (details.isNotEmpty) ...[
                        SizedBox(height: 4.h),
                        Text(
                          details,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: fontFamily,
                            fontSize: 12.sp,
                            height: 1.35,
                            color: LightColor.greyTextColor,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 12.h),
            Row(
              children: [
                Expanded(
                  child: _StatCell(
                    label: s.requestedQuantity,
                    child: Text(
                      qtyText,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: fontFamily,
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1E293B),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: _StatCell(
                    label: s.total,
                    child: ProductPriceText(
                      amount: OrderPriceFormatter.displayAmount(order),
                      currency: OrderPriceFormatter.resolveCurrency(order),
                      amountStyle: TextStyle(
                        color: LightColor.defaultColor,
                        fontFamily: fontFamily,
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w800,
                      ),
                      iconSize: 14,
                    ),
                  ),
                ),
                Expanded(
                  child: _StatCell(
                    label: s.orderDate,
                    child: Text(
                      RelativeTimeFormatter.format(s, order.createdAt),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: fontFamily,
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1E293B),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 12.h),
            if (order.relatedOrders.isNotEmpty) ...[
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF7ED),
                  borderRadius: BorderRadius.circular(10.r),
                  border: Border.all(color: const Color(0xFFFED7AA)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isArabic
                          ? 'هذا الطلب فيه ${order.relatedOrders.length} منتج ${order.relatedOrders.length == 1 ? 'آخر' : 'أخرى'} في نفس الشراء'
                          : 'This checkout includes ${order.relatedOrders.length} other product(s)',
                      style: TextStyle(
                        fontFamily: fontFamily,
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF9A3412),
                      ),
                    ),
                    ...order.relatedOrders.map(
                      (item) => TextButton(
                        onPressed: () => context.push(
                          AppRoutes.kTrackOrderView,
                          extra: {'orderId': item.id},
                        ),
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          isArabic
                              ? 'عرض المنتج: ${item.productName}'
                              : 'View product: ${item.productName}',
                          style: TextStyle(
                            fontFamily: fontFamily,
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w700,
                            color: LightColor.defaultColor,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 12.h),
            ],
            PrimaryButton(
              text: s.trackOrder,
              onPressed: widget.onTrackTap ??
                  () => context.push(
                        AppRoutes.kTrackOrderView,
                        extra: {'order': order},
                      ),
              height: 42.h,
              borderRadius: 12.r,
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCell extends StatelessWidget {
  const _StatCell({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final fontFamily = AppFonts.familyFor(Localizations.localeOf(context));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontFamily: fontFamily,
            fontSize: 11.sp,
            color: LightColor.greyTextColor,
          ),
        ),
        SizedBox(height: 4.h),
        child,
      ],
    );
  }
}

class _OrderThumb extends StatelessWidget {
  const _OrderThumb({
    required this.imageUrl,
    required this.videoUrl,
    required this.size,
  });

  final String? imageUrl;
  final String? videoUrl;
  final double size;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12.r),
      child: SizedBox(
        width: size,
        height: size,
        child: _buildMedia(),
      ),
    );
  }

  Widget _buildMedia() {
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return Stack(
        fit: StackFit.expand,
        children: [
          CachedAppImage(
            imageUrl: imageUrl!,
            fit: BoxFit.cover,
            errorWidget: _empty(),
          ),
          if (videoUrl != null && videoUrl!.isNotEmpty)
            const Center(child: ProductVideoPlayMark()),
        ],
      );
    }
    if (videoUrl != null && videoUrl!.isNotEmpty) {
      return ProductVideoThumbnail(
        videoUrl: videoUrl!,
        width: size,
        height: size,
        showPlayChrome: true,
      );
    }
    return _empty();
  }

  Widget _empty() {
    return ColoredBox(
      color: const Color(0xFFF1F5F9),
      child: Center(
        child: Icon(
          Icons.image_outlined,
          size: 28.sp,
          color: const Color(0xFF94A3B8),
        ),
      ),
    );
  }
}
