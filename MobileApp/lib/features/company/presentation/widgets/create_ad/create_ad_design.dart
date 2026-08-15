import 'package:alrasmarket/core/theme/colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Visual tokens for the Create Ad screen (UI-only).
class CreateAdDesign {
  CreateAdDesign._();

  static const Color brand = Color(0xFF3A7DC5);
  static const Color brandDark = Color(0xFF2F6AAD);
  static Color get pageBg => AppColors.scaffoldColor;
  static Color get cardBg => AppColors.cardColor;
  static Color get border => AppColors.borderColor;
  static Color get iconBg => AppColors.iconSoftColor;
  static Color get text => AppColors.titleColor;
  static Color get muted => AppColors.subtitleColor;
  static const Color requiredStar = Color(0xFFE11D48);

  static double get cardRadius => 14.r;
  static double get fieldRadius => 10.r;

  static List<BoxShadow> get cardShadow => [
        BoxShadow(
          color: const Color(0xFF0F172A).withValues(alpha: 0.05),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ];
}

class CreateAdSectionCard extends StatelessWidget {
  const CreateAdSectionCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin ?? EdgeInsets.only(bottom: 8.h),
      padding: padding ?? EdgeInsets.all(10.w),
      decoration: BoxDecoration(
        color: CreateAdDesign.cardBg,
        borderRadius: BorderRadius.circular(CreateAdDesign.cardRadius),
        border: Border.all(color: CreateAdDesign.border),
        boxShadow: CreateAdDesign.cardShadow,
      ),
      child: child,
    );
  }
}

class CreateAdFieldIcon extends StatelessWidget {
  const CreateAdFieldIcon(this.icon, {super.key});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32.w,
      height: 32.w,
      decoration: BoxDecoration(
        color: CreateAdDesign.iconBg,
        borderRadius: BorderRadius.circular(9.r),
      ),
      child: Icon(icon, color: CreateAdDesign.brand, size: 16.sp),
    );
  }
}

class CreateAdRequiredLabel extends StatelessWidget {
  const CreateAdRequiredLabel(
    this.text, {
    super.key,
    required this.fontFamily,
    this.required = true,
  });

  final String text;
  final String fontFamily;
  final bool required;

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: text,
            style: TextStyle(
              color: CreateAdDesign.text,
              fontFamily: fontFamily,
              fontSize: 12.sp,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (required)
            TextSpan(
              text: ' *',
              style: TextStyle(
                color: CreateAdDesign.requiredStar,
                fontFamily: fontFamily,
                fontSize: 12.sp,
                fontWeight: FontWeight.w700,
              ),
            ),
        ],
      ),
    );
  }
}
