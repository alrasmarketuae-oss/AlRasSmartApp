import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class NotificationSectionHeader extends StatelessWidget {
  const NotificationSectionHeader({
    super.key,
    required this.title,
  });

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      child: Align(
        alignment: AlignmentDirectional.centerStart,
        child: Text(
          title,
          style: TextStyle(
            color: const Color(0xFF333333),
            fontSize: 16.sp,
            fontWeight: FontWeight.normal,
            height: 1.5,
          ),
        ),
      ),
    );
  }
}
