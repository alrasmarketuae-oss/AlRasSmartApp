import 'package:alrasmarket/features/clint/presentation/widgets/booking_widets/booking_details_design.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Full description beside the hero image — shrinks font to fit available height.
class AdHeroDescriptionText extends StatelessWidget {
  const AdHeroDescriptionText({
    super.key,
    required this.text,
    required this.fontFamily,
    this.maxFontSize,
    this.minFontSize,
    this.color,
  });

  final String text;
  final String fontFamily;
  final double? maxFontSize;
  final double? minFontSize;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    if (text.trim().isEmpty) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) {
        if (!constraints.hasBoundedHeight || constraints.maxHeight <= 0) {
          return Text(
            text,
            style: TextStyle(
              color: color ?? BookingDetailsDesign.muted,
              fontFamily: fontFamily,
              fontSize: maxFontSize ?? 12.sp,
              height: 1.35,
            ),
          );
        }

        final maxFs = maxFontSize ?? 12.sp;
        final minFs = minFontSize ?? 8.sp;
        var fontSize = maxFs;
        final direction = Directionality.of(context);
        final baseColor = color ?? BookingDetailsDesign.muted;

        while (fontSize > minFs) {
          final painter = TextPainter(
            text: TextSpan(
              text: text,
              style: TextStyle(
                color: baseColor,
                fontFamily: fontFamily,
                fontSize: fontSize,
                height: 1.35,
              ),
            ),
            textDirection: direction,
          )..layout(maxWidth: constraints.maxWidth);
          if (painter.height <= constraints.maxHeight) break;
          fontSize -= 0.5;
        }

        return Text(
          text,
          style: TextStyle(
            color: baseColor,
            fontFamily: fontFamily,
            fontSize: fontSize.clamp(minFs, maxFs),
            height: 1.35,
          ),
        );
      },
    );
  }
}
