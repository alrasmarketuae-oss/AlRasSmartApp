import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import '../../generated/l10n.dart';

class CustomSocialIcon extends StatelessWidget {
  const CustomSocialIcon({
    super.key,
    required this.onTap,
    required this.assetImage,
    this.width,
    this.height,
    this.color,
    this.showText = false,
    this.text,
  });

  final VoidCallback onTap;
  final String assetImage;
  final double? width;
  final double? height;
  final Color? color;
  final bool showText;
  final String? text;

  @override
  Widget build(BuildContext context) {
    // If showText is true, show as button with text
    if (showText) {
      return GestureDetector(
        onTap: onTap,
        child: Container(
          width: 327.w,
          height: 52.h,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8.r),
            border: Border.all(
              color: const Color.fromRGBO(139, 94, 60, 1),
              width: 2,
            ),
          ),
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                // Google Icon
                SvgPicture.asset(
                  assetImage,
                  width: 24.w,
                  height: 24.h,
                  color: color,
                ),
                SizedBox(width: 12.w),
                // Text
                Text(
                  text ?? S.of(context).googleAccount,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: const Color.fromRGBO(139, 94, 60, 1),
                    fontFamily: 'Inter',
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w500,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Original icon-only version
    return GestureDetector(
      onTap: onTap,
      child: SvgPicture.asset(
        assetImage,
        width: width ?? 65.w,
        height: height ?? 65.h,
        color: color == null || color == Colors.black12 ? null : color,
      ),
    );
  }
}
