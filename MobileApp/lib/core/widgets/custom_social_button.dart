import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';

import '../../../core/theme/colors.dart';

class CustomSocialButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final String assetImage; // image path from assets

  const CustomSocialButton({
    super.key,
    required this.label,
    required this.onPressed,
    required this.assetImage,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52.h,
      child: TextButton(
        style: TextButton.styleFrom(
          side: BorderSide(color: LightColor.defaultColor),
          backgroundColor: Colors.transparent,
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.r),
          ),
        ),
        onPressed: onPressed,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            SizedBox(width: 50.w),
            SvgPicture.asset(
              assetImage,
              width: 28.w,
              height: 28.h,
              //color: LightColor.defaultColor,
            ),
            SizedBox(width: 12.w),
            Text(
              label,
              style: TextStyle(
                color: LightColor.defaultColor,
                fontWeight: FontWeight.bold,
                fontSize: 16.sp,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
