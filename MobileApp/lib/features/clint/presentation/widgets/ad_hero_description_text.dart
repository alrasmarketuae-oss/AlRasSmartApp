import 'package:alrasmarket/features/clint/presentation/widgets/booking_widets/booking_details_design.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Description beside the hero image — fills the available height and ends
/// with "…" when it does not fit; the full text is shown further down.
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

  static const double _lineHeight = 1.35;

  /// Hero text longer than this is likely cut, so the full text should be
  /// repeated in a section below the hero.
  static bool needsFullTextBelow(String text) => text.trim().length > 80;

  @override
  Widget build(BuildContext context) {
    if (text.trim().isEmpty) return const SizedBox.shrink();

    final fontSize = maxFontSize ?? 12.sp;
    final style = TextStyle(
      color: color ?? BookingDetailsDesign.muted,
      fontFamily: fontFamily,
      fontSize: fontSize,
      height: _lineHeight,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        var maxLines = 3;
        if (constraints.hasBoundedHeight && constraints.maxHeight > 0) {
          final lineHeightPx = fontSize * _lineHeight;
          maxLines = (constraints.maxHeight / lineHeightPx).floor().clamp(1, 20);
        }
        return Text(
          text.replaceAll(RegExp(r'[\n\r]+'), ' • '),
          maxLines: maxLines,
          overflow: TextOverflow.ellipsis,
          style: style,
        );
      },
    );
  }
}

/// Full ad description under the hero: bullet list for multi-line text,
/// a paragraph otherwise.
class AdFullDescriptionSection extends StatelessWidget {
  const AdFullDescriptionSection({
    super.key,
    required this.title,
    required this.text,
    required this.fontFamily,
    this.icon = Icons.list_alt_rounded,
  });

  final String title;
  final String text;
  final String fontFamily;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final lines = text
        .split(RegExp(r'[\n\r]+'))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    final style = TextStyle(
      color: BookingDetailsDesign.text,
      fontFamily: fontFamily,
      fontSize: 13.sp,
      height: 1.45,
    );

    return BookingDetailsSectionCard(
      title: title,
      icon: icon,
      fontFamily: fontFamily,
      child: lines.length > 1
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final item in lines)
                  Padding(
                    padding: EdgeInsets.only(bottom: 6.h),
                    child: Text('• $item', style: style),
                  ),
              ],
            )
          : Text(text.trim(), style: style),
    );
  }
}
