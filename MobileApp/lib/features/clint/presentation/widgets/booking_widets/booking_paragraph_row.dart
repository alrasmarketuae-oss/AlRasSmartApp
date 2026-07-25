import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class BookingParagraphRow extends StatelessWidget {
  const BookingParagraphRow({
    super.key,
    required this.text,
    required this.fontFamily,
  });

  final String text;
  final String fontFamily;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        color: const Color(0xFF333333).withValues(alpha: 0.8),
        fontFamily: fontFamily,
        fontSize: 14.sp,
        height: 1.5,
      ),
    );
  }
}
