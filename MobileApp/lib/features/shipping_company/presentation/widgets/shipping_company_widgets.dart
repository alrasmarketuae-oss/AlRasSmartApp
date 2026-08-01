import 'package:alrasmarket/core/utils/assets.dart';
import 'package:alrasmarket/core/widgets/language_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

const Color kShippingBg = Color(0xffF2F7FF);
const Color kShippingPrimary = Color(0xff3A7DC5);
const Color kShippingGreen = Color(0xff5F9D49);

class ShippingCompanyShell extends StatelessWidget {
  const ShippingCompanyShell({
    super.key,
    required this.companyName,
    required this.child,
    this.title,
    this.showBack = false,
    this.onBack,
  });

  final String companyName;
  final String? title;
  final Widget child;
  final bool showBack;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kShippingBg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
              child: Row(
                children: [
                  Image.asset(AppAssets.logo, width: 44.w, height: 36.h),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: Text(
                      companyName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xff2B2F38),
                      ),
                    ),
                  ),
                  const LanguageButton(),
                  SizedBox(width: 8.w),
                  Container(
                    width: 40.w,
                    height: 40.w,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10.r),
                      gradient: const LinearGradient(
                        colors: [Color(0xFF3C80C8), Color(0xFF64A051)],
                      ),
                    ),
                    child: Image.asset(
                      AppAssets.servicesIcon5,
                      width: 22.w,
                      height: 22.w,
                    ),
                  ),
                ],
              ),
            ),
            if (showBack || title != null)
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 8.w),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: onBack ?? () => Navigator.of(context).maybePop(),
                      icon: Icon(Icons.arrow_back_ios_new, color: kShippingPrimary, size: 20.sp),
                    ),
                    if (title != null)
                      Expanded(
                        child: Text(
                          title!,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 17.sp,
                            fontWeight: FontWeight.w700,
                            color: kShippingPrimary,
                          ),
                        ),
                      ),
                    if (title != null) SizedBox(width: 48.w),
                  ],
                ),
              ),
            Expanded(child: child),
          ],
        ),
      ),
    );
  }
}

class ShippingStatCardsRow extends StatelessWidget {
  const ShippingStatCardsRow({
    super.key,
    required this.activeCount,
    required this.underReviewCount,
    required this.rejectedCount,
    required this.activeLabel,
    required this.reviewLabel,
    required this.rejectedLabel,
  });

  final int activeCount;
  final int underReviewCount;
  final int rejectedCount;
  final String activeLabel;
  final String reviewLabel;
  final String rejectedLabel;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            count: activeCount,
            label: activeLabel,
            color: kShippingPrimary,
          ),
        ),
        SizedBox(width: 8.w),
        Expanded(
          child: _StatCard(
            count: underReviewCount,
            label: reviewLabel,
            color: kShippingGreen,
          ),
        ),
        SizedBox(width: 8.w),
        Expanded(
          child: _StatCard(
            count: rejectedCount,
            label: rejectedLabel,
            color: const Color(0xffE53935),
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.count,
    required this.label,
    required this.color,
  });

  final int count;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 14.h, horizontal: 8.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Column(
        children: [
          Text(
            '$count',
            style: TextStyle(
              fontSize: 22.sp,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11.sp,
              fontWeight: FontWeight.w600,
              color: const Color(0xff555555),
            ),
          ),
        ],
      ),
    );
  }
}

class ShippingGradientActionCard extends StatelessWidget {
  const ShippingGradientActionCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.colors,
    required this.onTap,
    this.titleColor,
    this.subtitleColor,
    this.iconColor,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final List<Color> colors;
  final VoidCallback onTap;
  final Color? titleColor;
  final Color? subtitleColor;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final resolvedTitleColor = titleColor ?? const Color(0xFF1A2B4A);
    final resolvedSubtitleColor = subtitleColor ?? const Color(0xFF3D4F6F);
    final resolvedIconColor = iconColor ?? resolvedTitleColor;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14.r),
        child: Ink(
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14.r),
            gradient: LinearGradient(colors: colors),
            border: Border.all(color: resolvedTitleColor.withValues(alpha: 0.18)),
            boxShadow: [
              BoxShadow(
                color: resolvedTitleColor.withValues(alpha: 0.12),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 44.w,
                height: 44.w,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.92),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: resolvedIconColor, size: 24.sp),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w800,
                        color: resolvedTitleColor,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w600,
                        color: resolvedSubtitleColor,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ShippingProfileField extends StatelessWidget {
  const ShippingProfileField({
    super.key,
    required this.label,
    required this.controller,
    this.keyboardType,
    this.readOnly = false,
  });

  final String label;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final bool readOnly;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13.sp,
            fontWeight: FontWeight.w600,
            color: const Color(0xff444444),
          ),
        ),
        SizedBox(height: 8.h),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10.r),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextField(
            controller: controller,
            readOnly: readOnly,
            keyboardType: keyboardType,
            decoration: InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
              prefixIcon: Icon(Icons.edit_outlined, color: kShippingPrimary, size: 18.sp),
            ),
          ),
        ),
        SizedBox(height: 14.h),
      ],
    );
  }
}

class ShippingFormSectionLabel extends StatelessWidget {
  const ShippingFormSectionLabel({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h, top: 4.h),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 14.sp,
          fontWeight: FontWeight.w700,
          color: const Color(0xff333333),
        ),
      ),
    );
  }
}

class ShippingFormField extends StatelessWidget {
  const ShippingFormField({
    super.key,
    required this.hint,
    required this.controller,
    this.suffix,
    this.prefix,
    this.icon = Icons.location_on_outlined,
    this.keyboardType,
    this.inputFormatters,
    this.maxLines = 1,
  });

  final String hint;
  final TextEditingController controller;
  final String? suffix;
  final String? prefix;
  final IconData icon;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: const Color(0xffE4EAF2)),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        maxLines: maxLines,
        decoration: InputDecoration(
          hintText: hint,
          prefixText: prefix,
          suffixText: suffix,
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 14.h),
          prefixIcon: Icon(icon, color: kShippingPrimary, size: 20.sp),
        ),
      ),
    );
  }
}

class ShippingPrimaryButton extends StatelessWidget {
  const ShippingPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50.h,
      child: ElevatedButton(
        onPressed: loading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: kShippingPrimary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
        ),
        child: loading
            ? SizedBox(
                width: 22.w,
                height: 22.w,
                child: const CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Text(
                label,
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }
}

class ShippingInfoBox extends StatelessWidget {
  const ShippingInfoBox({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: const Color(0xffE8F2FC),
        borderRadius: BorderRadius.circular(10.r),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, color: kShippingPrimary, size: 20.sp),
          SizedBox(width: 10.w),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: 12.sp,
                color: const Color(0xff444444),
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ShippingMainHeader extends StatelessWidget {
  const ShippingMainHeader({
    super.key,
    this.companyName,
  });

  final String? companyName;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 4.h),
      child: Row(
        children: [
          Image.asset(AppAssets.logo, width: 44.w, height: 36.h),
          if (companyName != null && companyName!.isNotEmpty) ...[
            SizedBox(width: 10.w),
            Expanded(
              child: Text(
                companyName!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xff2B2F38),
                ),
              ),
            ),
          ] else
            const Spacer(),
          const LanguageButton(),
        ],
      ),
    );
  }
}

class ShippingSettingsTile extends StatelessWidget {
  const ShippingSettingsTile({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.isDestructive = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool isDestructive;

  @override
  Widget build(BuildContext context) {
    final color = isDestructive ? const Color(0xffE53935) : kShippingPrimary;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(10.r),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10.r),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10.r),
            border: Border.all(color: const Color(0xffE4EAF2)),
          ),
          child: Row(
            children: [
              Container(
                width: 36.w,
                height: 36.w,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 20.sp),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: isDestructive ? color : const Color(0xff333333),
                  ),
                ),
              ),
              if (onTap != null)
                Icon(
                  Icons.arrow_forward_ios,
                  size: 14.sp,
                  color: Colors.grey.shade400,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
