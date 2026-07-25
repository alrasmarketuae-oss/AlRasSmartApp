import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Category name under home / view-all tiles: shrinks long labels and ellipsizes
/// so the image area keeps a stable size.
class CategoryLabel extends StatelessWidget {
  const CategoryLabel({
    super.key,
    required this.label,
    this.maxLines = 2,
    this.baseFontSize,
    this.color,
    this.fontWeight = FontWeight.w400,
    this.fontFamily = 'Inter',
    this.maxHeight,
  });

  final String label;
  final int maxLines;
  final double? baseFontSize;
  final Color? color;
  final FontWeight fontWeight;
  final String? fontFamily;
  final double? maxHeight;

  static double fontSizeFor(String text, {required double base}) {
    final len = text.trim().length;
    if (len <= 8) return base;
    if (len <= 14) return base * 0.93;
    if (len <= 20) return base * 0.86;
    if (len <= 28) return base * 0.78;
    return base * 0.72;
  }

  @override
  Widget build(BuildContext context) {
    final base = baseFontSize ?? 14.sp;
    final fontSize = fontSizeFor(label, base: base);
    final lineHeight = maxLines > 1 ? 1.25 : 1.2;
    final resolvedMaxHeight = maxHeight ?? (fontSize * lineHeight * maxLines + 2.h);

    return SizedBox(
      height: resolvedMaxHeight,
      width: double.infinity,
      child: Text(
        label,
        textAlign: TextAlign.center,
        maxLines: maxLines,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: color ?? const Color(0xCC333333),
          fontFamily: fontFamily,
          fontSize: fontSize,
          height: lineHeight,
          fontWeight: fontWeight,
        ),
      ),
    );
  }
}
