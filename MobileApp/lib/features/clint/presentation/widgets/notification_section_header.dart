import 'package:alrasmarket/generated/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class NotificationSectionHeader extends StatelessWidget {
  const NotificationSectionHeader({
    super.key,
    required this.title,
    this.showMarkAllAsRead = false,
    this.onMarkAllAsRead,
  });

  final String title;
  final bool showMarkAllAsRead;
  final VoidCallback? onMarkAllAsRead;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              color: const Color(0xFF333333),
              fontSize: 16.sp,
              fontWeight: FontWeight.normal,
              height: 1.5,
            ),
          ),
          if (showMarkAllAsRead)
            InkWell(
              onTap: onMarkAllAsRead,
              child: Text(
                S.of(context).markAllAsRead,
                style: TextStyle(
                  color: const Color(0xFF3A7DC5),
                  fontSize: 14.sp,
                  fontWeight: FontWeight.normal,
                  height: 1.5,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
