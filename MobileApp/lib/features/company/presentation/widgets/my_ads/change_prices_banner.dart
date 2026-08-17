import 'package:alrasmarket/core/router/app_router.dart';
import 'package:alrasmarket/core/serveses/auth_service.dart';
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
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    final isCompanyCustomer = AuthService.instance.isCompanyCustomerAccount;
    final title =
        isCompanyCustomer ? s.changeTargetPrices : s.changePrices;
    final subtitle = isCompanyCustomer
        ? s.changeTargetPricesSubtitle
        : s.changePricesSubtitle;

    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 4.h, 16.w, 8.h),
      child: Material(
        color: AppColors.card(context),
        elevation: 0,
        borderRadius: BorderRadius.circular(16.r),
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
          borderRadius: BorderRadius.circular(16.r),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(color: const Color(0xFFE7EEF6)),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF16233A).withValues(alpha: 0.06),
                  blurRadius: 10.r,
                  offset: Offset(0, 3.h),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 42.w,
                  height: 42.w,
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
                        title,
                        style: TextStyle(
                          fontFamily: fontFamily,
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF16233A),
                          height: 1.15,
                        ),
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: fontFamily,
                          fontSize: 11.sp,
                          color: const Color(0xFF6B7280),
                          height: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 28.w,
                  height: 28.w,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: LightColor.defaultColor,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isRtl
                        ? Icons.chevron_left_rounded
                        : Icons.chevron_right_rounded,
                    color: Colors.white,
                    size: 18.sp,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
