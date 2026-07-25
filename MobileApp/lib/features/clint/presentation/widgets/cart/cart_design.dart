import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class CartDesign {
  CartDesign._();

  static const Color brand = Color(0xFF3A7DC5);
  static const Color pageBg = Color(0xFFF4F7FA);
  static const Color cardBg = Colors.white;
  static const Color text = Color(0xFF1F2937);
  static const Color muted = Color(0xFF6B7280);
  static const Color border = Color(0xFFE5E7EB);
  static const Color selectedBorder = Color(0xFF3A7DC5);
  static const Color priceGreen = Color(0xFF22C55E);
  static const Color danger = Color(0xFFE53935);
  static const Color infoBg = Color(0xFFEFF6FF);
  static const Color infoBorder = Color(0xFFBFDBFE);
  static const Color infoText = Color(0xFF1D4ED8);

  static List<BoxShadow> get cardShadow => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.05),
          blurRadius: 10,
          offset: const Offset(0, 3),
        ),
      ];

  static BorderRadius get cardRadius => BorderRadius.circular(14.r);
}

class CartSectionTitle extends StatelessWidget {
  const CartSectionTitle({
    super.key,
    required this.title,
    required this.icon,
  });

  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18.sp, color: CartDesign.brand),
        SizedBox(width: 8.w),
        Text(
          title,
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.w800,
            color: CartDesign.text,
          ),
        ),
      ],
    );
  }
}
