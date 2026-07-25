import 'package:alrasmarket/core/widgets/currency_icon.dart';
import 'package:alrasmarket/generated/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class RetailTotalPriceCard extends StatelessWidget {
  const RetailTotalPriceCard({
    super.key,
    required this.fontFamily,
    required this.priceChild,
  });

  final String fontFamily;
  final Widget priceChild;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: const Color(0xFFEAECF0)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              s.total,
              style: TextStyle(
                color: const Color(0xFF333333),
                fontFamily: fontFamily,
                fontSize: 15.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          DefaultTextStyle(
            style: TextStyle(
              color: CurrencyIcon.green,
              fontFamily: fontFamily,
              fontSize: 16.sp,
              fontWeight: FontWeight.w700,
            ),
            child: priceChild,
          ),
        ],
      ),
    );
  }
}
