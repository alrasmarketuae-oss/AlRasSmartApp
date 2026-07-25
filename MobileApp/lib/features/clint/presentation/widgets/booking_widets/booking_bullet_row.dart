import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class BookingBulletRow extends StatelessWidget {
  const BookingBulletRow({
    super.key,
    required this.text,
    required this.fontFamily,
  });

  final String text;
  final String fontFamily;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: EdgeInsets.only(top: 6.h, right: 10.w),
            width: 8.w,
            height: 8.h,
            decoration: const BoxDecoration(
              color: Color(0xFFC83D30),
              shape: BoxShape.circle,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: const Color(0xFF333333).withValues(alpha: 0.8),
                fontFamily: fontFamily,
                fontSize: 14.sp,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
