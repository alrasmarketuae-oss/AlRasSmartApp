import 'package:alrasmarket/core/theme/app_fonts.dart';
import 'package:alrasmarket/core/theme/brand_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Locale-aware colored brand title.
///
/// Arabic: «تطبيق الراس الذكى» (optional تطبيق) with ال blue / راس red / الذكى green.
/// English: «Al Ras Smart App» with Al blue / Ras red / Smart green / App dark.
class ColoredBrandTitle extends StatelessWidget {
  const ColoredBrandTitle({
    super.key,
    this.fontSize,
    this.includeAppWord = true,
  });

  final double? fontSize;

  /// When true: Arabic includes «تطبيق», English includes «App».
  final bool includeAppWord;

  @override
  Widget build(BuildContext context) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final base = TextStyle(
      fontFamily: isAr ? AppFonts.cairo : AppFonts.inter,
      fontSize: fontSize ?? 26.sp,
      fontWeight: FontWeight.w800,
      height: 1.25,
      letterSpacing: 0,
    );

    if (isAr) {
      return Directionality(
        textDirection: TextDirection.rtl,
        child: Text.rich(
          TextSpan(
            children: [
              if (includeAppWord) ...[
                TextSpan(
                  text: 'تطبيق ',
                  style: base.copyWith(color: BrandColors.darkBlue),
                ),
              ],
              TextSpan(
                text: 'ال',
                style: base.copyWith(color: BrandColors.primaryBlue),
              ),
              TextSpan(
                text: 'راس',
                style: base.copyWith(color: BrandColors.primaryRed),
              ),
              TextSpan(text: ' ', style: base),
              TextSpan(
                text: 'الذكى',
                style: base.copyWith(color: BrandColors.primaryGreen),
              ),
            ],
          ),
          textAlign: TextAlign.center,
        ),
      );
    }

    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: 'Al',
            style: base.copyWith(color: BrandColors.primaryBlue),
          ),
          TextSpan(text: ' ', style: base),
          TextSpan(
            text: 'Ras',
            style: base.copyWith(color: BrandColors.primaryRed),
          ),
          TextSpan(text: ' ', style: base),
          TextSpan(
            text: 'Smart',
            style: base.copyWith(color: BrandColors.primaryGreen),
          ),
          if (includeAppWord) ...[
            TextSpan(text: ' ', style: base),
            TextSpan(
              text: 'App',
              style: base.copyWith(color: BrandColors.darkBlue),
            ),
          ],
        ],
      ),
      textAlign: TextAlign.center,
    );
  }
}

/// Thin line with blue / red / green center dots.
class BrandDotDivider extends StatelessWidget {
  const BrandDotDivider({super.key, this.width});

  final double? width;

  @override
  Widget build(BuildContext context) {
    final lineColor = BrandColors.primaryBlue.withValues(alpha: 0.22);
    return SizedBox(
      width: width ?? 168.w,
      child: Row(
        children: [
          Expanded(child: Divider(color: lineColor, thickness: 1)),
          SizedBox(width: 8.w),
          _dot(BrandColors.primaryBlue),
          SizedBox(width: 6.w),
          _dot(BrandColors.primaryRed),
          SizedBox(width: 6.w),
          _dot(BrandColors.primaryGreen),
          SizedBox(width: 8.w),
          Expanded(child: Divider(color: lineColor, thickness: 1)),
        ],
      ),
    );
  }

  Widget _dot(Color color) {
    return Container(
      width: 7.w,
      height: 7.w,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}
