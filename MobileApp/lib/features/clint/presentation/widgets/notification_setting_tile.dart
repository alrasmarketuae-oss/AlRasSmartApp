import 'package:alrasmarket/core/theme/colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class NotificationSwitchTile extends StatelessWidget {
  const NotificationSwitchTile({
    super.key,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: const Color(0xFF1A1A1A),
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                        height: 1.3,
                      ),
                ),
                SizedBox(height: 6.h),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: LightColor.greyTextColor,
                        fontSize: 13.sp,
                        fontWeight: FontWeight.normal,
                        height: 1.4,
                      ),
                ),
              ],
            ),
          ),
          SizedBox(width: 16.w),
          Switch.adaptive(
            value: value,
            activeColor:Colors.white,
            inactiveThumbColor:Colors.white,
            activeTrackColor: LightColor.defaultColor ,
            inactiveTrackColor:Color(0xFFD1D5DC),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
