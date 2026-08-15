import 'package:alrasmarket/core/theme/colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ChatSessionDivider extends StatelessWidget {
  const ChatSessionDivider({
    super.key,
    required this.label,
  });

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.h),
      child: Center(
        child: Container(
          constraints: BoxConstraints(maxWidth: 0.9.sw),
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 6.h),
          decoration: BoxDecoration(
            color: AppColors.iconSoft(context),
            borderRadius: BorderRadius.circular(20.r),
            border: Border.all(color: AppColors.border(context)),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11.sp,
              fontWeight: FontWeight.w600,
              color: AppColors.subtitle(context),
            ),
          ),
        ),
      ),
    );
  }
}
