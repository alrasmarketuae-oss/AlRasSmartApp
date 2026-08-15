import 'package:alrasmarket/core/theme/colors.dart';
import 'package:alrasmarket/core/widgets/product_price_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class SendBookingYourOfferCard extends StatelessWidget {
  const SendBookingYourOfferCard({
    super.key,
    required this.offer,
    required this.unit,
    required this.currency,
    required this.fontFamily,
  });

  final String offer;
  final String unit;
  final String currency;
  final String fontFamily;

  @override
  Widget build(BuildContext context) {
    final unitLabel = unit.trim().isEmpty ? 'Ton' : unit.trim();
    final amountStyle = TextStyle(
      color: AppColors.title(context).withValues(alpha: 0.75),
      fontFamily: fontFamily,
      fontSize: 14.sp,
      fontWeight: FontWeight.w500,
    );

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: AppColors.border(context)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ProductPriceText(
            amount: offer,
            currency: currency,
            amountStyle: amountStyle,
            iconSize: 16,
          ),
          Text(
            ' / $unitLabel',
            style: amountStyle,
          ),
        ],
      ),
    );
  }
}
