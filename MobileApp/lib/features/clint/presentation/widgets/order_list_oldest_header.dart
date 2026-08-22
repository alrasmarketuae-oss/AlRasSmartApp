import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class OrderListOldestHeader extends StatelessWidget {
  const OrderListOldestHeader({
    super.key,
    required this.label,
    required this.fontFamily,
  });

  final String label;
  final String fontFamily;

  @override
  Widget build(BuildContext context) {
    const lineColor = Color(0xFFCBD5E1);

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6.h),
      child: Row(
        children: [
          const Expanded(child: Divider(color: lineColor, height: 1)),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 12.w),
            child: Text(
              label.toUpperCase(),
              style: TextStyle(
                fontFamily: fontFamily,
                fontSize: 11.sp,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF94A3B8),
                letterSpacing: 0.8,
              ),
            ),
          ),
          const Expanded(child: Divider(color: lineColor, height: 1)),
        ],
      ),
    );
  }
}
