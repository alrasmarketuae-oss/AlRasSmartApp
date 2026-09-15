import 'package:alrasmarket/core/utils/assets.dart';
import 'package:alrasmarket/features/auth/presentation/controller/cubit/auth_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';

class LanguageButton extends StatelessWidget {
  final String languageText;
  final VoidCallback? onTap;

  const LanguageButton({super.key, this.languageText = 'Arabic', this.onTap});

  @override
  Widget build(BuildContext context) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    // Force LTR so icon stays left of the label in Arabic and English.
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Align(
        alignment: Alignment.centerLeft,
        child: InkWell(
          onTap: onTap ?? () => AuthCubit.get(context).setLocale(),
          borderRadius: BorderRadius.circular(12.r),
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 6.w, horizontal: 8.w),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SvgPicture.asset(
                  AppAssets.languageIcon,
                  width: 24.w,
                  height: 24.h,
                ),
                SizedBox(width: 8.w),
                Text(
                  isAr ? 'English' : 'اللغة العربية',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xff333333),
                    decoration:
                        !isAr ? TextDecoration.none : TextDecoration.underline,
                    decorationColor: const Color(0xff333333),
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
