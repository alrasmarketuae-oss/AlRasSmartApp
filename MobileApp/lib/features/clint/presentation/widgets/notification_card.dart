import 'package:alrasmarket/core/theme/colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';

class NotificationsCard extends StatelessWidget {
  const NotificationsCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.time,
    required this.icon,
    this.onTap,
    this.showUnreadDot = true,
  });

  final String title;
  final String subtitle;
  final String time;
  final String icon;
  final VoidCallback? onTap;
  final bool showUnreadDot;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8.r),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 2,
              offset: const Offset(0, 0),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
       Row(
  // لمحاذاة العناصر (العمود والأيقونة) من الأعلى
  crossAxisAlignment: CrossAxisAlignment.start, 
  children: [
    // 1. الحل السحري: تغليف العمود بـ Expanded ليأخذ كل المساحة المتبقية عدا مساحة الأيقونة
    Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start, // لجعل النصوص تبدأ من اليسار دائماً
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (showUnreadDot) ...[
                Container(
                  width: 8.w,
                  height: 8.h,
                  margin: EdgeInsets.only(top: 6.h),
                  decoration: const BoxDecoration(
                    color: Color(0xFF3A7DC5),
                    shape: BoxShape.circle,
                  ),
                ),
                SizedBox(width: 8.w),
              ],
              // تذكير: كان هنا مسافة إضافية SizedBox(width: 8.w) قمت بحذفها لتناسق المسافات
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: const Color(0xFF333333),
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          // الآن الـ subtitle محمي لأن العمود بالكامل داخل Expanded
          Text(
            subtitle,
            style: TextStyle(
              color:  LightColor.greyTextColor,
              fontSize: 14.sp,
              fontWeight: FontWeight.normal,
              height: 1.5,
            ),
          ),
        ],
      ),
    ),
    
    // مسافة بين النصوص وبين الأيقونة جهة اليمين
    SizedBox(width: 16.w), 

    // 2. الأيقونة الزرقاء ثابتة الحجم في أقصى اليمين
    Container(
      width: 48.w,
      height: 48.h,
      margin: EdgeInsets.only(top: 6.h),
      decoration: const BoxDecoration(
        color: Color(0xFF3A7DC5),
        shape: BoxShape.circle,
      ),
      child: Padding(
        padding: EdgeInsets.all(4.w), // اختياري: لإعطاء مسافة داخلية للـ SVG ليظهر بشكل متناسق
        child: SvgPicture.asset(icon),
      ),
    ),
  ],
),
            SizedBox(height: 4.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  time,
                  style: TextStyle(
                    color:  LightColor.greyTextColor60,
                    fontSize: 12.sp,
                    fontWeight: FontWeight.normal,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
