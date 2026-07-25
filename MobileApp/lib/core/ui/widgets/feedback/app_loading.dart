import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Design System Loading Widget
/// 
/// Usage:
/// ```dart
/// AppLoading()
/// ```
class AppLoading extends StatelessWidget {
  const AppLoading({
    super.key,
    this.size,
    this.color,
    this.strokeWidth,
  });

  final double? size;
  final Color? color;
  final double? strokeWidth;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        height: size ?? 40.h,
        width: size ?? 40.w,
        child: CircularProgressIndicator(
          strokeWidth: strokeWidth ?? 3,
          valueColor: AlwaysStoppedAnimation<Color>(
            color ?? Theme.of(context).primaryColor,
          ),
        ),
      ),
    );
  }
}

