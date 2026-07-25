import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Product code + copy control. Always LTR so codes stay readable in Arabic UI,
/// while [mainAxisSize.min] keeps alignment consistent with other fact values.
class ProductDetailCopyCode extends StatelessWidget {
  const ProductDetailCopyCode({
    super.key,
    required this.code,
    required this.fontFamily,
    required this.isAr,
    this.fontSize,
    this.textColor = const Color(0xFF333333),
    this.iconColor = const Color(0xFF3A7DC5),
  });

  final String code;
  final String fontFamily;
  final bool isAr;
  final double? fontSize;
  final Color textColor;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final iconGap = 4.w;
        final iconSize = 14.sp;
        final maxIncoming =
            constraints.maxWidth.isFinite && constraints.maxWidth > 0
                ? constraints.maxWidth
                : 160.w;
        final textMax = (maxIncoming - iconSize - iconGap).clamp(48.0, maxIncoming);

        return Directionality(
          textDirection: TextDirection.ltr,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ConstrainedBox(
                constraints: BoxConstraints(maxWidth: textMax),
                child: Text(
                  code,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: textColor,
                    fontFamily: fontFamily,
                    fontSize: fontSize ?? 14.sp,
                    fontWeight: FontWeight.w600,
                    height: 1.4,
                  ),
                ),
              ),
              SizedBox(width: iconGap),
              InkWell(
                onTap: () async {
                  await Clipboard.setData(ClipboardData(text: code));
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        isAr ? 'تم نسخ كود المنتج' : 'Product code copied',
                      ),
                      duration: const Duration(milliseconds: 1200),
                    ),
                  );
                },
                child: Icon(
                  Icons.copy_rounded,
                  size: iconSize,
                  color: iconColor,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
