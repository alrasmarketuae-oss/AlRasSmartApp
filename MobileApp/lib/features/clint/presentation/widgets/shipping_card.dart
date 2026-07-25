import 'package:alrasmarket/core/theme/colors.dart';
import 'package:alrasmarket/core/utils/assets.dart';
import 'package:alrasmarket/core/widgets/cached_app_image.dart';
import 'package:alrasmarket/generated/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Sample / domain model for a shipping price card until API is wired.
class ShippingCardData {
  const ShippingCardData({
    required this.carrierName,
    required this.rating,
    required this.routeCountryFrom,
    required this.routeCountryTo,
    required this.routePortFrom,
    required this.routePortTo,
    required this.daysMin,
    required this.daysMax,
    required this.phoneMasked,
    required this.price40f,
    required this.price20f,
    this.carrierImageUrl,
    this.onShowNumber,
    this.showPrices = true,
  });

  final String carrierName;
  final double rating;
  final String routeCountryFrom;
  final String routeCountryTo;
  final String routePortFrom;
  final String routePortTo;
  final String daysMin;
  final String daysMax;
  final String phoneMasked;
  final String price40f;
  final String price20f;
  final String? carrierImageUrl;
  final VoidCallback? onShowNumber;
  final bool showPrices;
}

/// Figma Frame 424 — shipping carrier offer card.
class ShippingCard extends StatelessWidget {
  const ShippingCard({
    super.key,
    required this.data,
    this.compact = false,
  });

  final ShippingCardData data;
  final bool compact;

  static const Color _titleColor = Color(0xFF333333);
  static Color _muted = LightColor.greyTextColor;
  static const Color _priceBlue = Color(0xFF0066CC);
  static const Color _pillBg = Color(0xFFF2F7FF);

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final isTablet = MediaQuery.sizeOf(context).shortestSide >= 600;

    if (compact) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeaderImage(height: isTablet ? 160.h : 120.h),
            Padding(
              padding: EdgeInsets.fromLTRB(12.w, 16.h, 12.w, 16.h),
              child: _buildCardContent(context, s, isTablet),
            ),
          ],
        ),
      );
    }

    return DecoratedBox(
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(8.r)),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8.r),
        child: Stack(
          children: [
            _buildHeaderImage(height: isTablet ? 220.h : 180.h),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: SizedBox(
                height: isTablet ? 400.h : 340.h,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(8.r),
                      topRight: Radius.circular(8.r),
                    ),
                  ),
                  padding: EdgeInsets.fromLTRB(12.w, 16.h, 12.w, 16.h),
                  child: _buildCardContent(context, s, isTablet),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderImage({required double height}) {
    final imageUrl = data.carrierImageUrl?.trim();
    if (imageUrl != null && imageUrl.isNotEmpty) {
      return CachedAppImage(
        imageUrl: imageUrl,
        width: double.infinity,
        height: height,
        fit: BoxFit.cover,
        errorWidget: _buildFallbackHeaderImage(height),
        placeholder: SizedBox(
          height: height,
          width: double.infinity,
          child: const Center(
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    return _buildFallbackHeaderImage(height);
  }

  Widget _buildFallbackHeaderImage(double height) {
    return SizedBox(
      width: double.infinity,
      height: height,
      child: Image.asset(
        AppAssets.shippingCardImage,
        fit: BoxFit.cover,
      ),
    );
  }

  Widget _buildCardContent(
    BuildContext context,
    S s,
    bool isTablet, {
    bool showHeader = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showHeader) ...[
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  data.carrierName,
                  style: TextStyle(
                    color: _titleColor,
                    fontSize: 16.sp,
                    height: 1.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Icon(
                Icons.star_rounded,
                size: 18.sp,
                color: const Color(0xFFFFB800),
              ),
              SizedBox(width: 4.w),
              Text(
                data.rating.toStringAsFixed(1),
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 14.sp,
                  height: 1.5,
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
        ],
        _RoutePill(
          countryFrom: data.routeCountryFrom,
          portFrom: data.routePortFrom,
          countryTo: data.routeCountryTo,
          portTo: data.routePortTo,
          backgroundColor: _pillBg,
        ),
        if (data.daysMin != '—' || data.daysMax != '—') ...[
          SizedBox(height: 10.h),
          Text(
            s.shippingTimeRange(data.daysMin, data.daysMax),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14.sp,
            ),
          ),
        ],
        SizedBox(height: 10.h),
        SizedBox(
          height: 50.h,
          child: _PhoneRow(
            phoneMasked: data.phoneMasked,
            onShowNumber: data.onShowNumber,
            isTablet: isTablet,
          ),
        ),
        if (data.showPrices) ...[
          SizedBox(height: 20.h),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _PriceBlock(
                  label: s.container20f,
                  price: data.price20f,
                ),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: _PriceBlock(
                  label: s.container40f,
                  price: data.price40f,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _RoutePill extends StatelessWidget {
  const _RoutePill({
    required this.countryFrom,
    required this.portFrom,
    required this.countryTo,
    required this.portTo,
    required this.backgroundColor,
  });

  final String countryFrom;
  final String portFrom;
  final String countryTo;
  final String portTo;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    const dividerColor = LightColor.defaultColor;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  countryFrom,
                  style: TextStyle(
                    color: ShippingCard._titleColor,
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w700,
                    height: 1.35,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  portFrom,
                  style: TextStyle(
                    color: ShippingCard._muted,
                    fontSize: 12.sp,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
            child: SvgPicture.asset(
              AppAssets.servicesIcon5,
              width: 22.w,
              height: 22.h,
              colorFilter: const ColorFilter.mode(
                dividerColor,
                BlendMode.srcIn,
              ),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  countryTo,
                  textAlign: TextAlign.end,
                  style: TextStyle(
                    color: ShippingCard._titleColor,
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w700,
                    height: 1.35,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  portTo,
                  textAlign: TextAlign.end,
                  style: TextStyle(
                    color: ShippingCard._muted,
                    fontSize: 12.sp,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PhoneRow extends StatelessWidget {
  const _PhoneRow({
    required this.phoneMasked,
    this.onShowNumber,
    required this.isTablet,
  });

  final String phoneMasked;
  final VoidCallback? onShowNumber;
  final bool isTablet;
  @override
  Widget build(BuildContext context) {
    final s = S.of(context);

    return Directionality(
      textDirection: TextDirection.ltr,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: 8.w,
          vertical: isTablet ? 3.h : 5.h,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8.r),
          border: Border.all(color: LightColor.defaultColor, width: 1.5),
        ),
        child: Row(
          children: [
            Material(
              color: LightColor.defaultColor,
              borderRadius: BorderRadius.circular(8.r),
              child: InkWell(
                onTap: onShowNumber,
                borderRadius: BorderRadius.circular(8.r),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 12.w,
                    vertical: 8.h,
                  ),
                  child: Text(
                    s.showNumber,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14.sp,
                      height: 1.5,
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(width: 26.w),
            Expanded(
              child: Text(
                phoneMasked,
                textAlign: TextAlign.start,
                style: TextStyle(
                  color: LightColor.defaultColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 16.sp,
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PriceBlock extends StatelessWidget {
  const _PriceBlock({required this.label, required this.price});

  final String label;
  final String price;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: ShippingCard._pillBg,
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.black,
              fontSize: 14.sp,
              fontWeight: FontWeight.bold,
              height: 1.5,
            ),
          ),
          SizedBox(height: 5.h),
          Text(
            price,
            style: TextStyle(
              color: ShippingCard._priceBlue,
              fontFamily: "Inter",
              fontWeight: FontWeight.bold,
              fontSize: 18.sp,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
