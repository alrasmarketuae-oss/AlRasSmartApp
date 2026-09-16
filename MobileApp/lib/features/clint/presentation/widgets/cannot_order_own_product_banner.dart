import 'package:alrasmarket/core/theme/app_fonts.dart';
import 'package:alrasmarket/features/clint/presentation/widgets/booking_widets/booking_details_design.dart';
import 'package:alrasmarket/generated/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Bottom-bar notice when the signed-in user opens their own listing.
class CannotOrderOwnProductBanner extends StatelessWidget {
  const CannotOrderOwnProductBanner({super.key, this.fontFamily});

  final String? fontFamily;

  @override
  Widget build(BuildContext context) {
    final family =
        fontFamily ?? AppFonts.familyFor(Localizations.localeOf(context));
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 12.h),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF7ED),
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: const Color(0xFFFDBA74)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.info_outline_rounded,
                size: 20.sp,
                color: const Color(0xFFC2410C),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Text(
                  S.of(context).cannotOrderOwnProduct,
                  style: TextStyle(
                    fontFamily: family,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    height: 1.35,
                    color: BookingDetailsDesign.text,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
