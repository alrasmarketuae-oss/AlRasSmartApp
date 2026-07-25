import 'package:alrasmarket/core/router/app_router.dart';
import 'package:alrasmarket/core/router/where_to_go.dart';
import 'package:alrasmarket/core/theme/app_fonts.dart';
import 'package:alrasmarket/core/widgets/primary_button.dart';
import 'package:alrasmarket/generated/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

class PaymentCancelView extends StatelessWidget {
  const PaymentCancelView({super.key});

  @override
  Widget build(BuildContext context) {
    final fontFamily = AppFonts.familyFor(Localizations.localeOf(context));
    final l10n = S.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FA),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.cancel_outlined,
                size: 88.r,
                color: Colors.orange.shade700,
              ),
              SizedBox(height: 24.h),
              Text(
                'Payment cancelled',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: const Color(0xFF333333),
                  fontFamily: fontFamily,
                  fontSize: 22.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 12.h),
              Text(
                'No charge was completed. You can return to your cart and try again.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: const Color(0xFF333333).withValues(alpha: 0.65),
                  fontFamily: fontFamily,
                  fontSize: 14.sp,
                  height: 1.5,
                ),
              ),
              SizedBox(height: 32.h),
              PrimaryButton(
                text: 'Back to cart',
                backgroundColor: const Color(0xFF3A7DC5),
                onPressed: () => context.go(AppRoutes.kCartView),
                height: 48.h,
                borderRadius: 8.r,
              ),
              SizedBox(height: 12.h),
              OutlinedButton(
                onPressed: () => context.go(whereToGo()),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFF3A7DC5), width: 1.5),
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
            ],
          ),
        ),
      ),
    );
  }
}
