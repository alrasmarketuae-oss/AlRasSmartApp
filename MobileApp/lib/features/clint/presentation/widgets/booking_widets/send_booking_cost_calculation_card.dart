import 'package:alrasmarket/core/widgets/product_price_text.dart';
import 'package:alrasmarket/generated/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class SendBookingCostCalculationCard extends StatelessWidget {
  const SendBookingCostCalculationCard({
    super.key,
    required this.fontFamily,
    required this.unitPrice,
    required this.quantity,
    required this.currency,
  });

  final String fontFamily;
  final double unitPrice;
  final double quantity;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final total = unitPrice * quantity;
    final qtyDisplay = quantity % 1 == 0
        ? quantity.toInt().toString()
        : quantity.toStringAsFixed(2);
    final totalAmount = total.toStringAsFixed(total % 1 == 0 ? 0 : 2);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: const Color(0xFFEAECF0)),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      s.pricePerUnitTimesQuantity,
                      style: TextStyle(
                        color: const Color(0xFF333333),
                        fontFamily: fontFamily,
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      '($unitPrice × $qtyDisplay)',
                      style: TextStyle(
                        color: const Color(0xFF333333).withValues(alpha: 0.55),
                        fontFamily: fontFamily,
                        fontSize: 12.sp,
                      ),
                    ),
                  ],
                ),
              ),
              ProductPriceText(
                amount: totalAmount,
                currency: currency,
                amountStyle: TextStyle(
                  color: const Color(0xFF333333),
                  fontFamily: fontFamily,
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w700,
                ),
                iconSize: 16,
              ),
            ],
          ),
          SizedBox(height: 12.h),
          const Divider(color: Color(0xFFEAECF0), height: 1),
          SizedBox(height: 12.h),
          Row(
            children: [
              Expanded(
                child: Text(
                  s.total,
                  style: TextStyle(
                    color: const Color(0xFF333333),
                    fontFamily: fontFamily,
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              ProductPriceText(
                amount: totalAmount,
                currency: currency,
                amountStyle: TextStyle(
                  color: const Color(0xFF3A7DC5),
                  fontFamily: fontFamily,
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w700,
                ),
                iconSize: 14,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
