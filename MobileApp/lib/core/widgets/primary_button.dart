import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../core/theme/colors.dart';

class PrimaryButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final double? height;
  final double? width;
  final double borderRadius;
  final TextStyle? textStyle;
  final Color? backgroundColor;
  final Color? textColor;
  final bool expandWidth;
  const PrimaryButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.height,
    this.width,
    this.borderRadius = 8,
    this.textStyle,
    this.backgroundColor,
    this.textColor,
    this.expandWidth = true,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height ?? 48.h,
      width: expandWidth ? (width ?? double.infinity) : width,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor ?? LightColor.defaultColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius.r),
          ),
        ),
        onPressed: isLoading ? null : onPressed,
        child: isLoading
            ? SizedBox(
                width: 18.sp,
                height: 18.sp,
                child: const CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Text(
                text,
                maxLines: 1,
                textAlign: TextAlign.center,
                style:
                    textStyle ??
                    TextStyle(
                      
                      fontSize: 16.sp,
                      fontFamily: Theme.of(context).textTheme.labelLarge?.fontFamily,
                       overflow: TextOverflow.ellipsis,
                      //  maxLines: 1,
                      fontWeight: FontWeight.bold,
                      color: textColor ?? Colors.white,
                    ),
              ),
      ),
    );
  }
}
