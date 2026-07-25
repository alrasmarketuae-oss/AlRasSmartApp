import 'package:alrasmarket/core/router/app_router.dart';
import 'package:alrasmarket/core/router/where_to_go.dart';
import 'package:alrasmarket/core/theme/app_fonts.dart';
import 'package:alrasmarket/core/utils/assets.dart';
import 'package:alrasmarket/core/widgets/primary_button.dart';
import 'package:alrasmarket/generated/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';

class BookingSuccessView extends StatelessWidget {
  const BookingSuccessView({
    super.key,
    this.orderNumber = '12345',
  });

  final String orderNumber;

  @override
  Widget build(BuildContext context) {
    final fontFamily = AppFonts.familyFor(Localizations.localeOf(context));
    final l10n = S.of(context);
    final displayOrderNumber = orderNumber.startsWith('#')
        ? orderNumber
        : '#$orderNumber';

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FA),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      SizedBox(height: 48.h),
                      SvgPicture.asset(
                        AppAssets.checkCircleIcon,
                        width: 88.r,
                        height: 88.r,
                      ),
                      SizedBox(height: 28.h),
                      Text(
                        l10n.orderSentSuccessfullyTitle,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: const Color(0xFF333333),
                          fontFamily: fontFamily,
                          fontSize: 22.sp,
                          fontWeight: FontWeight.bold,
                          height: 1.35,
                        ),
                      ),
                      SizedBox(height: 12.h),
                      Text(
                        l10n.orderSentSuccessfullySubtitle,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: const Color(0xFF333333).withValues(alpha: 0.65),
                          fontFamily: fontFamily,
                          fontSize: 14.sp,
                          height: 1.5,
                        ),
                      ),
                      SizedBox(height: 28.h),
                      _OrderNumberCard(
                        label: l10n.orderNumber,
                        orderNumber: displayOrderNumber,
                        fontFamily: fontFamily,
                      ),
                      SizedBox(height: 12.h),
                      _NotificationBanner(
                        message: l10n.orderSentNotifyWhenRespond,
                        fontFamily: fontFamily,
                      ),
                    ],
                  ),
                ),
              ),
              PrimaryButton(
                text: l10n.trackOrder,
                backgroundColor: const Color(0xFF3A7DC5),
                onPressed: () => context.push(AppRoutes.kTrackOrderView),
                height: 48.h,
                borderRadius: 8.r,
              ),
              SizedBox(height: 12.h),
              OutlinedButton(
                onPressed: () => context.go(whereToGo()),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(
                    color: Color(0xFF3A7DC5),
                    width: 1.5,
                  ),
                  minimumSize: Size(double.infinity, 48.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                ),
                child: Text(
                  l10n.backToHome,
                  style: TextStyle(
                    color: const Color(0xFF3A7DC5),
                    fontFamily: fontFamily,
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              SizedBox(height: 24.h),
            ],
          ),
        ),
      ),
    );
  }
}

class _OrderNumberCard extends StatelessWidget {
  const _OrderNumberCard({
    required this.label,
    required this.orderNumber,
    required this.fontFamily,
  });

  final String label;
  final String orderNumber;
  final String fontFamily;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 18.h),
      decoration: BoxDecoration(
        color: const Color(0xFFE9F5EA),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              color: const Color(0xFF333333).withValues(alpha: 0.55),
              fontFamily: fontFamily,
              fontSize: 13.sp,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 6.h),
          Text(
            orderNumber,
            style: TextStyle(
              color: const Color(0xFF333333),
              fontFamily: fontFamily,
              fontSize: 20.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _NotificationBanner extends StatelessWidget {
  const _NotificationBanner({
    required this.message,
    required this.fontFamily,
  });

  final String message;
  final String fontFamily;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: const Color(0xFFE1F0FF),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: const Color(0xFF333333).withValues(alpha: 0.75),
                fontFamily: fontFamily,
                fontSize: 13.sp,
                height: 1.4,
              ),
            ),
          ),
          SizedBox(width: 8.w),
          Icon(
            Icons.info_outline_rounded,
            size: 20.sp,
            color: const Color(0xFF3A7DC5),
          ),
        ],
      ),
    );
  }
}
