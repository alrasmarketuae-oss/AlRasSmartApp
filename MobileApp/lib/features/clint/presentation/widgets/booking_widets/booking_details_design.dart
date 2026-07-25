import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Visual tokens for Booking product details (UI-only).
class BookingDetailsDesign {
  BookingDetailsDesign._();

  static const Color brand = Color(0xFF2F6AAD);
  static const Color brandSoft = Color(0xFF3A7DC5);
  static const Color pageBg = Color(0xFFF4F7FA);
  static const Color cardBg = Colors.white;
  static const Color border = Color(0xFFE6EBF2);
  static const Color text = Color(0xFF1F2937);
  static const Color muted = Color(0xFF6B7280);
  static const Color priceGreen = Color(0xFF619D50);
  static const Color iconBg = Color(0xFFEAF3FB);
  /// Thin pencil-gray line before Posted Date / Product Code.
  static const Color metaDivider = Color(0xFFC8CCD4);

  static double get cardRadius => 14.r;

  static Widget metaSectionDivider({double top = 2, double bottom = 10}) {
    return Padding(
      padding: EdgeInsets.only(top: top.h, bottom: bottom.h),
      child: const Divider(
        height: 1,
        thickness: 0.8,
        color: metaDivider,
      ),
    );
  }

  static List<BoxShadow> get cardShadow => [
        BoxShadow(
          color: const Color(0xFF0F172A).withValues(alpha: 0.05),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ];
}

class BookingDetailsSectionCard extends StatelessWidget {
  const BookingDetailsSectionCard({
    super.key,
    required this.title,
    required this.icon,
    required this.child,
    required this.fontFamily,
  });

  final String title;
  final IconData icon;
  final Widget child;
  final String fontFamily;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(14.w, 12.h, 14.w, 12.h),
      decoration: BoxDecoration(
        color: BookingDetailsDesign.cardBg,
        borderRadius: BorderRadius.circular(BookingDetailsDesign.cardRadius),
        border: Border.all(color: BookingDetailsDesign.border),
        boxShadow: BookingDetailsDesign.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32.w,
                height: 32.w,
                decoration: BoxDecoration(
                  color: BookingDetailsDesign.iconBg,
                  borderRadius: BorderRadius.circular(9.r),
                ),
                child: Icon(
                  icon,
                  size: 17.sp,
                  color: BookingDetailsDesign.brandSoft,
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: BookingDetailsDesign.brand,
                    fontFamily: fontFamily,
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          child,
        ],
      ),
    );
  }
}

class BookingDetailsFactTile extends StatelessWidget {
  const BookingDetailsFactTile({
    super.key,
    required this.icon,
    required this.label,
    required this.fontFamily,
    this.value,
    this.valueWidget,
    this.valueColor,
    this.valueBold = false,
  });

  final IconData icon;
  final String label;
  final String fontFamily;
  final String? value;
  final Widget? valueWidget;
  final Color? valueColor;
  final bool valueBold;

  @override
  Widget build(BuildContext context) {
    final resolved = value?.trim() ?? '';
    if (valueWidget == null && resolved.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16.sp, color: BookingDetailsDesign.brandSoft),
          SizedBox(width: 8.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: BookingDetailsDesign.text,
                    fontFamily: fontFamily,
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 2.h),
                valueWidget ??
                    Text(
                      resolved,
                      style: TextStyle(
                        color: valueColor ?? BookingDetailsDesign.muted,
                        fontFamily: fontFamily,
                        fontSize: 13.sp,
                        fontWeight:
                            valueBold ? FontWeight.w700 : FontWeight.w500,
                        height: 1.3,
                      ),
                    ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Renders fact tiles as equal two-column rows (always 2 slots per row).
class BookingDetailsFactsGrid extends StatelessWidget {
  const BookingDetailsFactsGrid({super.key, required this.tiles});

  final List<Widget> tiles;

  @override
  Widget build(BuildContext context) {
    if (tiles.isEmpty) return const SizedBox.shrink();

    final rows = <Widget>[];
    for (var i = 0; i < tiles.length; i += 2) {
      final a = tiles[i];
      final hasB = i + 1 < tiles.length;
      rows.add(
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: a),
            SizedBox(width: 10.w),
            Expanded(child: hasB ? tiles[i + 1] : const SizedBox.shrink()),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: rows,
    );
  }
}
