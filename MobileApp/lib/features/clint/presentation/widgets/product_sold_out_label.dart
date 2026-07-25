import 'package:alrasmarket/core/theme/app_fonts.dart';
import 'package:alrasmarket/generated/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Bold sold-out label for product details / cards.
class ProductSoldOutLabel extends StatelessWidget {
  const ProductSoldOutLabel({
    super.key,
    this.fontFamily,
    this.fontSize,
    this.centered = true,
  });

  final String? fontFamily;
  final double? fontSize;
  final bool centered;

  @override
  Widget build(BuildContext context) {
    final family =
        fontFamily ?? AppFonts.familyFor(Localizations.localeOf(context));
    return Text(
      S.of(context).soldOut,
      textAlign: centered ? TextAlign.center : TextAlign.start,
      style: TextStyle(
        color: const Color(0xFFDC2626),
        fontFamily: family,
        fontSize: fontSize ?? 16.sp,
        fontWeight: FontWeight.w800,
        height: 1.3,
      ),
    );
  }
}
