import 'package:alrasmarket/core/utils/assets.dart';
import 'package:alrasmarket/core/utils/utc_date_time.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Shows ad publish date/time (UTC from API → local display).
class ProductPostedAtText extends StatelessWidget {
  const ProductPostedAtText({
    super.key,
    required this.createdAt,
    this.fontFamily,
    this.fontSize,
    this.color = const Color(0xFF6B7280),
    this.showIcon = true,
  });

  final String createdAt;
  final String? fontFamily;
  final double? fontSize;
  final Color color;
  final bool showIcon;

  @override
  Widget build(BuildContext context) {
    final text = UtcDateTime.formatDateTimeLocal(createdAt);
    if (text.isEmpty) return const SizedBox.shrink();

    final size = fontSize ?? 11.sp;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showIcon) ...[
          SvgPicture.asset(
            AppAssets.clockIcon,
            width: 12.w,
            height: 12.h,
            colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
          ),
          SizedBox(width: 4.w),
        ],
        Flexible(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: color,
              fontFamily: fontFamily,
              fontSize: size,
              height: 1.3,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
      ],
    );
  }
}
