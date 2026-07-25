import 'package:alrasmarket/core/widgets/currency_icon.dart';
import 'package:alrasmarket/generated/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:alrasmarket/core/utils/assets.dart';

class HighlightAdCard extends StatelessWidget {
  const HighlightAdCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            offset: Offset.zero,
            blurRadius: 2.r,
          ),
        ],
        gradient: const LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [
            Color(0xFFD0091E),
            Color(0xFF0066CC),
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              SvgPicture.asset(AppAssets.starIcon, width: 24.w, height: 24.h),
              SizedBox(width: 8.w),
              Text(
                S.of(context).highlightAd,
                style: TextStyle(
                  color: Colors.white,
                  fontFamily: 'Inter',
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w700,
                  height: 1.5,
                ),
              ),
              const Spacer(),
              SvgPicture.asset(AppAssets.circalIcon, width: 24.w, height: 24.h),
            ],
          ),
          SizedBox(height: 12.h),
          Text(
            S.of(context).highlightAdDescription,
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontFamily: 'Inter',
              fontSize: 14.sp,
              fontWeight: FontWeight.w400,
              height: 1.5,
            ),
          ),
          SizedBox(height: 16.h),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              _HighlightPriceRow(
                amount: '199',
                faded: true,
              ),
              SizedBox(width: 12.w),
              _HighlightPriceRow(
                amount: '99',
                suffix: '/month',
                emphasized: true,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HighlightPriceRow extends StatelessWidget {
  const _HighlightPriceRow({
    required this.amount,
    this.suffix,
    this.faded = false,
    this.emphasized = false,
  });

  final String amount;
  final String? suffix;
  final bool faded;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final color = faded
        ? Colors.white.withOpacity(0.6)
        : Colors.white;
    final amountSize = emphasized ? 18.sp : 12.sp;
    final weight = emphasized ? FontWeight.w700 : FontWeight.w400;

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(
          amount,
          style: TextStyle(
            color: color,
            fontSize: amountSize,
            fontWeight: weight,
            height: 1.5,
            decoration: faded ? TextDecoration.lineThrough : null,
          ),
        ),
        SizedBox(width: 4.w),
        ColorFiltered(
          colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
          child: const CurrencyIcon(currency: 'AED', size: 16),
        ),
        if (suffix != null && suffix!.isNotEmpty) ...[
          SizedBox(width: 4.w),
          Text(
            suffix!,
            style: TextStyle(
              color: color,
              fontSize: emphasized ? 14.sp : 12.sp,
              fontWeight: weight,
              height: 1.5,
            ),
          ),
        ],
      ],
    );
  }
}
