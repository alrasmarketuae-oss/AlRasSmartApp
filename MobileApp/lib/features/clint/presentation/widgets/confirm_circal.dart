import 'package:alrasmarket/core/router/app_router.dart';
import 'package:alrasmarket/core/router/where_to_go.dart';
import 'package:alrasmarket/core/theme/app_fonts.dart';
import 'package:alrasmarket/core/theme/colors.dart';
import 'package:alrasmarket/core/utils/assets.dart';
import 'package:alrasmarket/generated/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';

class ConfirmCircalView extends StatelessWidget {
  const ConfirmCircalView({super.key, this.productId});

  /// Id of the request that was just published, used to highlight it in My Ads.
  final String? productId;

  void _openMyRequests(BuildContext context) {
    final id = productId?.trim() ?? '';
    context.go(
      AppRoutes.kMyAdsView,
      extra: id.isEmpty ? null : {'highlightProductId': id},
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);
    final fontFamily = AppFonts.familyFor(Localizations.localeOf(context));

    return SafeArea(
      child: Scaffold(
        body: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SvgPicture.asset(
              AppAssets.checkCircleIcon,
              width: 120.w,
              height: 120.h,
            ),
            SizedBox(height: 16.h),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.w),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    l10n.requestPublishedSuccessfully,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: const Color.fromRGBO(26, 26, 26, 1),
                      fontFamily: fontFamily,
                      fontSize: 24.sp,
                      letterSpacing: 0,
                      fontWeight: FontWeight.w600,
                      height: 1.5,
                    ),
                  ),
                  SizedBox(height: 18.h),
                  Text(
                    l10n
                        .yourRequestWillBePublishedAndApprovedSuppliersCanSubmitTheirOffersYouWillReceiveANotificationWhenOffersArrive,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: LightColor.greyTextColor,
                      fontFamily: fontFamily,
                      fontSize: 14.sp,
                      letterSpacing: 0,
                      fontWeight: FontWeight.normal,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 24.h),
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Color.fromRGBO(242, 247, 255, 1),
              ),
              padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 20.h),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 52.h,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: LightColor.defaultColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        elevation: 0,
                      ),
                      onPressed: () => _openMyRequests(context),
                      child: Text(
                        l10n.showAllRequests,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontFamily: fontFamily,
                          fontSize: 16.sp,
                          letterSpacing: 0,
                          fontWeight: FontWeight.normal,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 16.h),
                  SizedBox(
                    width: double.infinity,
                    height: 52.h,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                          color: LightColor.defaultColor,
                          width: 2,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                      ),
                      onPressed: () => context.go(whereToGo()),
                      child: Text(
                        l10n.backToHome,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: LightColor.defaultColor,
                          fontFamily: fontFamily,
                          fontSize: 16.sp,
                          letterSpacing: 0,
                          fontWeight: FontWeight.normal,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
