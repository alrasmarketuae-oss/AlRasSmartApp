import 'package:alrasmarket/core/router/app_router.dart';
import 'package:alrasmarket/core/router/where_to_go.dart';
import 'package:alrasmarket/core/theme/app_fonts.dart';
import 'package:alrasmarket/core/theme/colors.dart';
import 'package:alrasmarket/core/utils/assets.dart';
import 'package:alrasmarket/core/widgets/primary_button.dart';
import 'package:alrasmarket/features/clint/presentation/widgets/search_header.dart';
import 'package:alrasmarket/generated/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';

class SubmitOfferSuccessView extends StatelessWidget {
  const SubmitOfferSuccessView({super.key});

  @override
  Widget build(BuildContext context) {
    final fontFamily = AppFonts.familyFor(Localizations.localeOf(context));
    final l10n = S.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FA),
      body: SafeArea(
        child: Column(
          children: [
            const SearchHeader(isSearch: false),
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.w),
                child: Column(
                  children: [
                SizedBox(height: 30.h),
                    Container(
                      width: 100.r,
                      height: 100.r,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: SvgPicture.asset(
                        AppAssets.checkCircleIcon,
                        width: 90.r,
                        height: 90.r,
                      ),
                    ),
                    SizedBox(height: 32.h),
                    Text(
                      l10n.offerSentSuccessfullyTitle,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: LightColor.greyTextColor,
                        fontFamily: fontFamily,
                        fontSize: 24.sp,
                        fontWeight: FontWeight.bold,
                        height: 1.4,
                      ),
                    ),
                    SizedBox(height: 16.h),
                    Text(
                      l10n.offerSentSuccessfullySubtitle,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: const Color(0xFF333333).withValues(alpha: 0.7),
                        fontFamily: fontFamily,
                        fontSize: 14.sp,
                        height: 1.5,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      l10n.offerSentNotifyWhenReviewed,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: LightColor.greyTextColor,
                        fontFamily: fontFamily,
                        fontSize: 14.sp,
                        height: 1.5,
                      ),
                    ),
                    SizedBox(height: 30.h),
                   Column(
                     mainAxisAlignment: MainAxisAlignment.start,
                     crossAxisAlignment: CrossAxisAlignment.stretch,
                     children: [
                       PrimaryButton(
                         text: l10n.showAllRequests,
                         backgroundColor: const Color(0xFF3A7DC5),
                         onPressed: () =>
                             context.go(AppRoutes.kRequestsServiceView),
                       ),
                       SizedBox(height: 12.h),
                       OutlinedButton(
                         onPressed: () => context.go(whereToGo()),
                         style: OutlinedButton.styleFrom(
                           side: const BorderSide(
                             color: Color(0xFF3A7DC5),
                             width: 1.5,
                           ),
                           padding: EdgeInsets.symmetric(vertical: 14.h),
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
                     ],
                   ),
         
                  ],
                ),
              ),
            ),
        ],
        ),
      ),
    );
  }
}
