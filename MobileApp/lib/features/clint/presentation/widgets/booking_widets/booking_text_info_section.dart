import 'package:alrasmarket/features/clint/presentation/widgets/booking_widets/booking_details_card.dart';
import 'package:alrasmarket/features/clint/presentation/widgets/booking_widets/booking_details_section_title.dart';
import 'package:alrasmarket/features/clint/presentation/widgets/booking_widets/booking_paragraph_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class BookingTextInfoSection extends StatelessWidget {
  const BookingTextInfoSection({
    super.key,
    required this.title,
    required this.text,
    required this.fontFamily,
  });

  final String title;
  final String text;
  final String fontFamily;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        BookingDetailsSectionTitle(title: title, fontFamily: fontFamily),
        SizedBox(height: 8.h),
        BookingDetailsCard(
          children: [
            BookingParagraphRow(text: text, fontFamily: fontFamily),
          ],
        ),
      ],
    );
  }
}
