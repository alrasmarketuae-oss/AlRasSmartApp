import 'package:alrasmarket/core/router/app_router.dart';
import 'package:alrasmarket/core/theme/app_fonts.dart';
import 'package:alrasmarket/core/theme/colors.dart';
import 'package:alrasmarket/generated/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

class ChangePricesBanner extends StatelessWidget {
  const ChangePricesBanner({super.key, this.highlightProductId});

  final String? highlightProductId;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final fontFamily = AppFonts.familyFor(Localizations.localeOf(context));

    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 4.h, 16.w, 8.h),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14.r),
        child: InkWell(
          onTap: () {
            final id = highlightProductId?.trim();
            context.push(
              AppRoutes.kChangePricesView,
              extra: id == null || id.isEmpty
                  ? null
                  : {'highlightProductId': id},
            );
          },
          borderRadius: BorderRadius.circular(14.r),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14.r),
              border: Border.all(color: const Color(0xFFE6EEF8)),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF16233A).withValues(alpha: 0.06),
                  blurRadius: 12.r,
                  offset: Offset(0, 4.h),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 44.w,
                  height: 44.w,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: LightColor.defaultColor,
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Icon(
                    Icons.sell_rounded,
                    color: Colors.white,
                    size: 22.sp,
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        s.changePrices,
                        style: TextStyle(
                          fontFamily: fontFamily,
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w800,
                          color: LightColor.defaultColor,
                          height: 1.2,
                        ),
                      ),
                      SizedBox(height: 3.h),
                      Text(
                        s.changePricesSubtitle,
                        style: TextStyle(
                          fontFamily: fontFamily,
                          fontSize: 12.sp,
                          color: const Color(0xFF6B7280),
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Directionality.of(context) == TextDirection.rtl
                      ? Icons.chevron_left_rounded
                      : Icons.chevron_right_rounded,
                  color: LightColor.defaultColor,
                  size: 26.sp,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
