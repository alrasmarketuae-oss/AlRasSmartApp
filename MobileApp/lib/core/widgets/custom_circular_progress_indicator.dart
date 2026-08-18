import 'package:alrasmarket/core/theme/colors.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class CustomCircleLoader extends StatelessWidget {
  final Color? color;
  final double? width;
  final double? indicatorSize;
  final double? strokeWidth;
  final double? radius;
  const CustomCircleLoader({
    super.key,
    this.color,
    this.width,
    this.indicatorSize,
    this.strokeWidth,
    this.radius,
  });

  @override
  Widget build(BuildContext context) {
    final bool isIOS = defaultTargetPlatform == TargetPlatform.iOS;
    final double defaultSize = isIOS ? 26.w : 24.w;
    final double defaultStrokeWidth = isIOS ? 3.5 : 3.0;

    return Center(
      child: SizedBox(
        width: indicatorSize ?? defaultSize,
        height: indicatorSize ?? defaultSize,
        child: isIOS
            ? CupertinoActivityIndicator(
                color: color ?? LightColor.defaultColor,
                radius: radius ?? 14.r,
              )
            : CircularProgressIndicator(
                color: color ?? LightColor.defaultColor,
                strokeWidth: strokeWidth ?? defaultStrokeWidth,
              ),
      ),
    );
  }
}
