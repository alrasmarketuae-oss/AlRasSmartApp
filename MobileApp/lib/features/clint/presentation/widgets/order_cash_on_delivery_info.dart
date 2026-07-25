import 'package:alrasmarket/features/clint/presentation/widgets/booking_widets/booking_details_section_title.dart';
import 'package:alrasmarket/generated/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Shown on non-retail order flows where payment is always on delivery.
class OrderCashOnDeliveryInfo extends StatelessWidget {
  const OrderCashOnDeliveryInfo({
    super.key,
    required this.fontFamily,
  });

  final String fontFamily;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        BookingDetailsSectionTitle(
          title: s.paymentOnDelivery,
          fontFamily: fontFamily,
        ),
        SizedBox(height: 8.h),
        Text(
          s.paymentOnDeliveryDescription,
          style: TextStyle(
            color: const Color(0xFF333333).withValues(alpha: 0.8),
            fontFamily: fontFamily,
            fontSize: 14.sp,
            height: 1.6,
          ),
        ),
      ],
    );
  }
}
