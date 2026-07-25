import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class BookingDetailsSectionTitle extends StatelessWidget {
  const BookingDetailsSectionTitle({
    super.key,
    required this.title,
    required this.fontFamily,
  });

  final String title;
  final String fontFamily;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: TextStyle(
        color: const Color(0xFF333333),
        fontFamily: fontFamily,
        fontSize: 15.sp,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}
