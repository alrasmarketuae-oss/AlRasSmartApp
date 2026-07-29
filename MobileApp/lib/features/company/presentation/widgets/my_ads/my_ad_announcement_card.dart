import 'package:alrasmarket/core/router/app_router.dart';
import 'package:alrasmarket/core/services_locator/services_locator.dart';
import 'package:alrasmarket/core/theme/app_fonts.dart';
import 'package:alrasmarket/core/theme/colors.dart';
import 'package:alrasmarket/core/ui/widgets/feedback/app_toast.dart';
import 'package:alrasmarket/core/utils/assets.dart';
import 'package:alrasmarket/core/utils/product_price_formatter.dart';
import 'package:alrasmarket/core/utils/product_quantity_formatter.dart';
import 'package:alrasmarket/core/utils/product_stock.dart';
import 'package:alrasmarket/core/widgets/product_price_text.dart';
import 'package:alrasmarket/features/clint/presentation/helpers/booking_price_type_label.dart';
import 'package:alrasmarket/features/clint/presentation/helpers/product_price_type_label.dart';
import 'package:alrasmarket/features/clint/presentation/widgets/product_media/product_media_thumbnail.dart';
import 'package:alrasmarket/features/clint/presentation/widgets/product_views_badge.dart';
import 'package:alrasmarket/features/company/data/models/my_listing_product_model.dart';
import 'package:alrasmarket/features/company/presentation/controller/cubit/company_cubit.dart';
import 'package:alrasmarket/features/company/presentation/controller/cubit/create_ad_cubit.dart';
import 'package:alrasmarket/features/company/presentation/models/create_ad_type.dart';
import 'package:alrasmarket/features/company/presentation/views/create_ad.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:alrasmarket/generated/l10n.dart';
class MyAdAnnouncementCard extends StatefulWidget {
  const MyAdAnnouncementCard({
    super.key,
    required this.product,
    this.compact = false,
    this.highlighted = false,
    this.preferRetailPricing = false,
    this.preferCategoryLabel = false,
    this.showBothPricingChannels = false,
  });

  final MyListingProductModel product;

  /// Narrow Account grid cells (2 phone / 3 tablet).
  final bool compact;

  /// Soft emphasis when opened from a new-order notification.
  final bool highlighted;

  /// When true (My Ads → Retail filter), show retail price / unit / qty.
  final bool preferRetailPricing;

  /// When true (My Ads → Categories filter), badge says Categories for hybrids.
  final bool preferCategoryLabel;

  /// When true (My Ads → All), hybrids show wholesale + retail rows.
  final bool showBothPricingChannels;

  @override
  State<MyAdAnnouncementCard> createState() => _MyAdAnnouncementCardState();
}

class _MyAdAnnouncementCardState extends State<MyAdAnnouncementCard>
    with SingleTickerProviderStateMixin {
  static const _borderGray = Color(0xFFD0D5DD);
  static const _textDark = Color(0xFF333333);

  late bool _isListingActive;
  bool _isTogglingStatus = false;
  bool _isDeleting = false;
  bool _isMarkingSoldOut = false;
  late final AnimationController _blink;

  MyListingProductModel get product => widget.product;

  @override
  void initState() {
    super.initState();
    _isListingActive = product.isListingActive;
    _blink = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
    if (widget.highlighted) {
      _runBlink();
    }
  }

  @override
  void didUpdateWidget(covariant MyAdAnnouncementCard oldWidget) {
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
    final s = S.of(context);
    final fontFamily = AppFonts.familyFor(Localizations.localeOf(context));
    final compact = widget.compact;
    final displayTypeName = widget.preferRetailPricing
        ? CreateAdType.retail.label
        : (widget.preferCategoryLabel && product.categoryId != null)
            ? CreateAdType.categories.label
            : product.productTypeName;
    final typeStyle = _typeBadgeStyle(displayTypeName);
    final listingBadge = _listingStatusBadge(product.statusCanonical, s);
    final listingIcon = _listingIconBadge(product.statusCanonical);
    final adType = CreateAdType.fromLabel(
          product.productTypeNameEn.trim().isNotEmpty
              ? product.productTypeNameEn
              : product.productTypeName,
        ) ??
        (product.productTypeId == 3
            ? CreateAdType.offers
            : product.productTypeId == 4
                ? CreateAdType.requests
                : product.productTypeId == 2
                    ? CreateAdType.booking
                    : product.productTypeId == 1
                        ? CreateAdType.retail
                        : null);
    final typeLabel = CreateAdType.localizedDisplayLabel(
      displayTypeName,
      S.of(context),
    );
    final preferRetail = widget.preferRetailPricing;
    final showDiscount =
        adType == CreateAdType.offers && product.isDiscountActive;
    final padH = compact ? 8.w : 12.w;
    final padV = compact ? 8.h : 12.h;
    final titleSize = compact ? 13.sp : 16.sp;
    final bodySize = compact ? 11.sp : 14.sp;
    final imageHeight = compact ? 110.h : 140.h;
    final isAr =
        Localizations.localeOf(context).languageCode.toLowerCase() == 'ar';
    final viewOrdersLabel = isAr ? 'عرض الطلبات' : 'View orders';
    final pauseLabel = isAr ? 'إيقاف' : 'Pause';
    final publishLabel = S.of(context).publish;
    final canToggleStatus =
        !product.statusCanonical.toLowerCase().contains('review');

    final content = Padding(
      padding: EdgeInsets.fromLTRB(padH, padV, padH, padV),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: compact ? MainAxisSize.max : MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  product.productName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: _textDark,
                    fontFamily: fontFamily,
                    fontSize: titleSize,
                    fontWeight: FontWeight.w700,
                    height: 1.35,
                  ),
                ),
              ),
              Transform.translate(
                offset: Offset(4.w, -4.h),
                child: _AdActionsMenu(
                  fontFamily: fontFamily,
                  editLabel: S.of(context).edit,
                  deleteLabel: S.of(context).delete,
                  viewOrdersLabel: viewOrdersLabel,
                  pauseOrPublishLabel:
                      _isListingActive ? pauseLabel : publishLabel,
                  soldOutLabel: S.of(context).soldOut,
                  showPauseOrPublish: canToggleStatus,
                  showSoldOut: !product.isRequestProduct &&
                      !ProductStock.isSoldOut(
                        product,
                        preferRetail: preferRetail,
                      ),
                  isTogglingStatus: _isTogglingStatus,
                  isDeleting: _isDeleting,
                  isMarkingSoldOut: _isMarkingSoldOut,
                  onEdit: _onEdit,
                  onDelete: _onDelete,
                  onViewOrders: _onOpenAdDetails,
                  onToggleStatus: _onToggleListingStatus,
                  onSoldOut: _onMarkSoldOut,
                ),
              ),
            ],
          ),
          SizedBox(height: 6.h),
          Row(
            children: [
              Flexible(
                child: _Badge(
                  label: listingBadge.label,
                  background: listingBadge.background,
                  foreground: listingBadge.foreground,
                  icon: listingIcon,
                  compact: compact,
                ),
              ),
              SizedBox(width: 6.w),
              Flexible(
                child: _Badge(
                  label: typeLabel,
                  background: typeStyle.background,
                  foreground: typeStyle.foreground,
                  icon: typeStyle.icon ?? AppAssets.categoriesImage1,
                  compact: compact,
                ),
              ),
            ],
          ),
          if (product.categoryName.trim().isNotEmpty) ...[
            SizedBox(height: 6.h),
            Text(
              product.categoryName.trim(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: fontFamily,
                fontSize: bodySize,
                color: LightColor.greyTextColor,
              ),
            ),
          ],
          if (product.pendingOffersCount > 0) ...[
            SizedBox(height: 6.h),
            _Badge(
              label: (product.isRequestProduct ||
                      adType == CreateAdType.requests)
                  ? S.of(context).offersAvailable(product.pendingOffersCount)
                  : S.of(context).ordersAvailable(product.pendingOffersCount),
              background: const Color(0xFFE8F4FD),
              foreground: const Color(0xFF3A7DC5),
              compact: compact,
            ),
          ],
          SizedBox(height: 6.h),
          if (product.productId.isNotEmpty)
            ProductViewsBadge(
              productId: product.productId,
              initialViewsCount: product.viewsCountValue,
              fontFamily: fontFamily,
              trackOnOpen: false,
            ),
          if (_isRejectedWithReason(product)) ...[
            SizedBox(height: 6.h),
            Text(
              '${S.of(context).rejectionReason}: ${product.supplierNotes.trim()}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: fontFamily,
                fontSize: compact ? 11.sp : 13.sp,
                color: const Color(0xFFD92D20),
                height: 1.35,
              ),
            ),
          ],
          if (compact) const Spacer(),
          if (adType == CreateAdType.requests) ...[
            Text(
              () {
                final qty = ProductQuantityFormatter.quantityWithUnit(
                  quantityText: product.quantity,
                  unitName: product.unitName,
                  s: S.of(context),
                );
                return qty.isEmpty
                    ? S.of(context).requestedQuantity
                    : '${S.of(context).requestedQuantity} $qty';
              }(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: fontFamily,
                fontSize: bodySize,
                color: const Color.fromRGBO(107, 114, 128, 1),
              ),
            ),
            if (ProductPriceFormatter.amount(product).isNotEmpty) ...[
              SizedBox(height: 4.h),
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: ProductPriceText.unitPrice(
                  product,
                  amountStyle: TextStyle(
                    color: LightColor.defaultColor,
                    fontFamily: AppFonts.cairo,
                    fontSize: compact ? 14.sp : 16.sp,
                    fontWeight: FontWeight.w700,
                  ),
                  matchCurrencyToAmount: true,
                ),
              ),
            ],
          ],
          if (adType != CreateAdType.requests) ...[
            Row(
              children: [
                Flexible(
                  child: ProductPriceText.unitPrice(
                    product,
                    preferRetail: preferRetail,
                    amountStyle: TextStyle(
                      color: LightColor.defaultColor,
                      fontFamily: AppFonts.cairo,
                      fontSize: compact ? 14.sp : 16.sp,
                      fontWeight: FontWeight.w700,
                    ),
                    matchCurrencyToAmount: true,
                  ),
                ),
                if (adType == CreateAdType.booking) ...[
                  SizedBox(width: 4.w),
                  Flexible(
                    child: Text(
                      '${product.shipping.routeFromCountry} → ${product.shipping.routeToCountry}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: fontFamily,
                        fontSize: bodySize,
                        color: _textDark,
                      ),
                    ),
                  ),
                ],
                if (showDiscount) ...[
                  SizedBox(width: 4.w),
                  DiscountBadge(
                    discountPercentage:
                        product.discountPercentage.trim().isNotEmpty
                            ? product.discountPercentage.trim()
                            : product.discountPercentValue.toString(),
                    compact: compact,
                  ),
                ],
              ],
            ),
            if (product
                .quantityForChannel(preferRetail: preferRetail)
                .trim()
                .isNotEmpty) ...[
              SizedBox(height: 2.h),
              Text(
                ProductQuantityFormatter.quantityWithUnit(
                  quantityText: product.quantityForChannel(
                    preferRetail: preferRetail,
                  ),
                  unitName: product.unitNameForChannel(
                    preferRetail: preferRetail,
                  ),
                  s: S.of(context),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: fontFamily,
                  fontSize: compact ? 10.sp : 12.sp,
                  color: const Color.fromRGBO(107, 114, 128, 1),
                ),
              ),
            ],
          ],
          if (() {
            final type = adType;
            return type == CreateAdType.booking ||
                type == CreateAdType.categories ||
                type == CreateAdType.offers ||
                type == CreateAdType.requests ||
                (product.categoryId != null && product.categoryId! > 0);
          }()) ...[
            Builder(
              builder: (context) {
                final priceType = adType == CreateAdType.booking
                    ? BookingPriceTypeLabel.fromProduct(product)
                    : ProductPriceTypeLabel.fromProduct(
                        product,
                        isAr: isAr,
                      );
                if (priceType.isEmpty) return const SizedBox.shrink();
                return Padding(
                  padding: EdgeInsets.only(top: 4.h),
                  child: Text(
                    priceType,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: fontFamily,
                      fontSize: compact ? 10.sp : 12.sp,
                      fontWeight: FontWeight.w600,
                      color: LightColor.defaultColor,
                    ),
                  ),
                );
              },
            ),
          ],
        ],
      ),
    );

    return AnimatedBuilder(
      animation: _blink,
      builder: (context, child) {
        final t = widget.highlighted ? _blink.value : 0.0;
        final borderColor = Color.lerp(
          _borderGray,
          const Color(0xFF3A7DC5),
          t,
        )!;
        final bgColor = Color.lerp(
          Colors.white,
          const Color(0xFFE8F4FD),
          t,
        )!;
        final glow = const Color(0xFF3A7DC5).withValues(alpha: 0.1 + 0.22 * t);

        return Container(
          width: double.infinity,
          height: compact ? double.infinity : null,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(9.r),
            border: Border.all(
              color: borderColor,
              width: widget.highlighted ? 1.5 + t * 0.5 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: widget.highlighted
                    ? glow
                    : Colors.black.withValues(alpha: 0.15),
                blurRadius: widget.highlighted ? 4.r + 6.r * t : 4.r,
                offset: Offset.zero,
              ),
            ],
          ),
          child: child,
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: compact ? MainAxisSize.max : MainAxisSize.min,
        children: [
          InkWell(
            onTap: product.productId.isNotEmpty ? _onOpenAdDetails : null,
            child: ProductMediaThumbnail(
              product: product,
              width: double.infinity,
              height: imageHeight,
              openPreviewOnTap: false,
              showDefaultPlaceholderImage: false,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(8.r),
                bottomRight: Radius.circular(8.r),
              ),
            ),
          ),
          if (compact)
            Expanded(
              child: InkWell(
                onTap: product.productId.isNotEmpty ? _onOpenAdDetails : null,
                child: content,
              ),
            )
          else
            InkWell(
              onTap: product.productId.isNotEmpty ? _onOpenAdDetails : null,
              child: content,
            ),
        ],
      ),
    );
  }

  void _onOpenAdDetails() {
    if (product.productId.isEmpty) return;

    context.push(
      AppRoutes.kAdRequestOffersView,
      extra: {
        'product': product,
        'preferRetailPricing': widget.preferRetailPricing,
        'preferCategoryLabel': widget.preferCategoryLabel,
        'showBothPricingChannels': widget.showBothPricingChannels,
      },
    );
  }

  Future<void> _onEdit() async {
    if (product.productId.isEmpty) {
      AppToast.showError(context, 'Product id is missing.');
      return;
    }

    final cubit = sl<CreateAdCubit>()..loadProductForEdit(product);
    if (!mounted) return;

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => CreateAdView(cubit: cubit),
      ),
    );

    if (!mounted) return;
    await context.read<CompanyCubit>().reloadMyListings();
  }

  Future<void> _onDelete() async {
    final s = S.of(context);
    if (product.productId.isEmpty) {
      AppToast.showError(context, s.productIdMissing);
      return;
    }

    final fontFamily = AppFonts.familyFor(Localizations.localeOf(context));
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        final ds = S.of(dialogContext);
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
          ),
          title: Text(
            ds.deleteAdConfirmTitle,
            style: TextStyle(
              fontFamily: fontFamily,
              fontSize: 18.sp,
              fontWeight: FontWeight.w700,
              color: _textDark,
            ),
          ),
          content: Text(
            ds.deleteAdConfirmMessage(product.productName),
            style: TextStyle(
              fontFamily: fontFamily,
              fontSize: 14.sp,
              color: LightColor.greyTextColor,
              height: 1.4,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(
                ds.cancel,
                style: TextStyle(
                  fontFamily: fontFamily,
                  fontSize: 14.sp,
                  color: LightColor.greyTextColor,
                ),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(
                ds.delete,
                style: TextStyle(
                  fontFamily: fontFamily,
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w700,
                  color: LightColor.defultRed,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isDeleting = true);
    final error = await context.read<CompanyCubit>().deleteProduct(
      product.productId,
      context,
    );

    if (!mounted) return;
    setState(() => _isDeleting = false);

    if (error != null) {
      AppToast.showError(context, error);
      return;
    }

    AppToast.showSuccess(context, S.of(context).adDeletedSuccessfully);
  }

  Future<void> _onToggleListingStatus() async {
    if (product.productId.isEmpty) return;

    setState(() => _isTogglingStatus = true);
    final nextActive = !_isListingActive;
    final error = await context.read<CompanyCubit>().updateListingStatus(
      productId: product.productId,
      isActive: nextActive,
      context: context,
    );

    if (!mounted) return;
    setState(() => _isTogglingStatus = false);

    if (error != null) {
      AppToast.showError(context, error);
      return;
    }

    setState(() => _isListingActive = nextActive);
    AppToast.showSuccess(
      context,
      nextActive ? 'Listing activated.' : 'Listing paused.',
    );
  }

  Future<void> _onMarkSoldOut() async {
    if (product.productId.isEmpty || _isMarkingSoldOut) return;

    final isAr =
        Localizations.localeOf(context).languageCode.toLowerCase() == 'ar';
    final soldOutLabel = S.of(context).soldOut;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(isAr ? 'تأكيد' : 'Confirm'),
          content: Text(
            isAr
                ? 'هل تريد تعليم هذا الإعلان كـ$soldOutLabel؟'
                : 'Mark this ad as $soldOutLabel?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(S.of(context).cancel),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(soldOutLabel),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isMarkingSoldOut = true);
    final error = await context.read<CompanyCubit>().markSoldOut(
      productId: product.productId,
      context: context,
    );

    if (!mounted) return;
    setState(() => _isMarkingSoldOut = false);

    if (error != null) {
      AppToast.showError(context, error);
      return;
    }

    AppToast.showSuccess(context, S.of(context).soldOut);
  }

  bool _isRejectedWithReason(MyListingProductModel item) {
    final status = item.status.toLowerCase();
    final approval = item.approvalStatus.toLowerCase();
    return (status.contains('reject') || approval.contains('reject'))
        && item.supplierNotes.trim().isNotEmpty;
  }

  _BadgeStyle _listingStatusBadge(String statusCanonical, S s) {
    final value = statusCanonical.trim();
    final lower = value.toLowerCase();

    if (lower == 'active') {
      return _BadgeStyle(
        label: s.listingActive,
        background: const Color(0xFFDCFAE6),
        foreground: const Color(0xFF17B26A),
      );
    }
    if (lower.contains('paused') || lower.contains('inactive')) {
      return _BadgeStyle(
        label: s.listingPaused,
        background: const Color(0xFFF2F2F2),
        foreground: LightColor.greyTextColor,
      );
    }
    if (lower.contains('review')) {
      return _BadgeStyle(
        label: s.underReviewAds,
        background: const Color(0xFFFFFAEB),
        foreground: const Color(0xFFFDB022),
      );
    }
    if (lower.contains('sold') ||
        lower.contains('out') ||
        lower.contains('stock')) {
      return _BadgeStyle(
        label: s.soldOut,
        background: const Color(0xFFFFEBEE),
        foreground: const Color(0xFFE53935),
      );
    }
    return _BadgeStyle(
      label: value.isEmpty ? '—' : value,
      background: const Color(0xFFF2F4F7),
      foreground: const Color(0xFF475467),
    );
  }

  String _listingIconBadge(String statusCanonical) {
    final value = statusCanonical.trim();
    final lower = value.toLowerCase();

    if (lower == 'active') {
      return AppAssets.checkCircleIcon;
    }
    if (lower.contains('paused') || lower.contains('inactive')) {
      return AppAssets.profileStopIcon;
    }
    if (lower.contains('review')) {
      return AppAssets.clockIcon;
    }
    return AppAssets.checkCircleIcon;
  }

  _BadgeStyle _typeBadgeStyle(String typeName) {
    switch (CreateAdType.fromLabel(typeName)) {
      case CreateAdType.offers:
        return const _BadgeStyle(
          background: Color(0xFFFECDC9),
          foreground: Color(0xFFC83D30),
          icon: AppAssets.offerRed,
        );
      case CreateAdType.requests:
        return const _BadgeStyle(
          background: Color(0xFFE0EAFF),
          foreground: Color(0xFF3A7DC5),
          icon: AppAssets.servicesIcon,
        );
      case CreateAdType.booking:
        return const _BadgeStyle(
          background: Color(0xFFDCFAE6),
          foreground: Color(0xFF17B26A),
          icon: AppAssets.bookingGreen,
        );
      case CreateAdType.retail:
        return const _BadgeStyle(
          background: Color(0xFFE0F1FF),
          foreground: Color(0xFF3A7DC5),
          icon: AppAssets.servicesIcon4,
        );
      case CreateAdType.categories:
        return const _BadgeStyle(
          background: Color(0xFFE0F1FF),
          foreground: Color(0xFF3A7DC5),
          icon: AppAssets.servicesIcon4,
        );
      case null:
        return const _BadgeStyle(
          background: Color(0xFFE0F1FF),
          foreground: Color(0xFF3A7DC5),
        );
    }
  }
}

class _Badge extends StatelessWidget {
  const _Badge({
    required this.label,
    required this.background,
    required this.foreground,
    this.icon,
    this.compact = false,
  });

  final String label;
  final Color background;
  final Color foreground;
  final String? icon;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final fontFamily = AppFonts.familyFor(Localizations.localeOf(context));

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 12,
        vertical: compact ? 4 : 8,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(10.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: foreground,
                fontFamily: fontFamily,
                fontSize: compact ? 11.sp : 14.sp,
                fontWeight: FontWeight.w600,
                height: 1.2,
              ),
            ),
          ),
          SizedBox(width: 4.w),
          SvgPicture.asset(
            icon ?? AppAssets.profileEditIcon,
            color: icon != AppAssets.offerRed ? foreground : null,
            width: compact ? 14.w : 20.w,
            height: compact ? 14.h : 20.h,
          ),
        ],
      ),
    );
  }
}

class _AdActionsMenu extends StatelessWidget {
  const _AdActionsMenu({
    required this.fontFamily,
    required this.editLabel,
    required this.deleteLabel,
    required this.viewOrdersLabel,
    required this.pauseOrPublishLabel,
    required this.soldOutLabel,
    required this.showPauseOrPublish,
    required this.showSoldOut,
    required this.isTogglingStatus,
    required this.isDeleting,
    required this.isMarkingSoldOut,
    required this.onEdit,
    required this.onDelete,
    required this.onViewOrders,
    required this.onToggleStatus,
    required this.onSoldOut,
  });

  final String fontFamily;
  final String editLabel;
  final String deleteLabel;
  final String viewOrdersLabel;
  final String pauseOrPublishLabel;
  final String soldOutLabel;
  final bool showPauseOrPublish;
  final bool showSoldOut;
  final bool isTogglingStatus;
  final bool isDeleting;
  final bool isMarkingSoldOut;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onViewOrders;
  final VoidCallback onToggleStatus;
  final VoidCallback onSoldOut;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<_AdMenuAction>(
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
      icon: Icon(
        Icons.more_vert,
        color: const Color(0xFF475467),
        size: 22.sp,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
      onSelected: (action) {
        switch (action) {
          case _AdMenuAction.viewOrders:
            onViewOrders();
            break;
          case _AdMenuAction.edit:
            onEdit();
            break;
          case _AdMenuAction.toggleStatus:
            onToggleStatus();
            break;
          case _AdMenuAction.soldOut:
            onSoldOut();
            break;
          case _AdMenuAction.delete:
            onDelete();
            break;
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: _AdMenuAction.viewOrders,
          child: Text(
            viewOrdersLabel,
            style: TextStyle(fontFamily: fontFamily, fontSize: 14.sp),
          ),
        ),
        PopupMenuItem(
          value: _AdMenuAction.edit,
          child: Text(
            editLabel,
            style: TextStyle(fontFamily: fontFamily, fontSize: 14.sp),
          ),
        ),
        if (showPauseOrPublish)
          PopupMenuItem(
            value: _AdMenuAction.toggleStatus,
            enabled: !isTogglingStatus,
            child: Text(
              pauseOrPublishLabel,
              style: TextStyle(fontFamily: fontFamily, fontSize: 14.sp),
            ),
          ),
        if (showSoldOut)
          PopupMenuItem(
            value: _AdMenuAction.soldOut,
            enabled: !isMarkingSoldOut,
            child: Text(
              soldOutLabel,
              style: TextStyle(fontFamily: fontFamily, fontSize: 14.sp),
            ),
          ),
        PopupMenuItem(
          value: _AdMenuAction.delete,
          enabled: !isDeleting,
          child: Text(
            deleteLabel,
            style: TextStyle(
              fontFamily: fontFamily,
              fontSize: 14.sp,
              color: LightColor.defultRed,
            ),
          ),
        ),
      ],
    );
  }
}

enum _AdMenuAction { viewOrders, edit, toggleStatus, soldOut, delete }

class _BadgeStyle {
  const _BadgeStyle({
    this.label = '',
    required this.background,
    required this.foreground,
    this.icon,
  });

  final String label;
  final Color background;
  final Color foreground;
  final String? icon;
}

class DiscountBadge extends StatelessWidget {
  final String discountPercentage;
  final bool compact;
  const DiscountBadge({
    Key? key,
    required this.discountPercentage,
    this.compact = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 6 : 8,
        vertical: compact ? 2 : 4,
      ),
      decoration: BoxDecoration(
        color: const Color.fromRGBO(249, 112, 102, 1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            discountPercentage,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontFamily: 'Inter',
              fontSize: compact ? 12.sp : 16.sp,
              fontWeight: FontWeight.w600,
              height: 1.2,
            ),
          ),
          SizedBox(width: compact ? 2 : 5),
          Icon(
            Icons.percent,
            color: Colors.white,
            size: compact ? 12 : 15,
          ),
        ],
      ),
    );
  }
}
