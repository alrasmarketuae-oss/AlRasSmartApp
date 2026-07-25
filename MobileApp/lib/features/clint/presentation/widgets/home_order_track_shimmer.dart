import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shimmer/shimmer.dart';

/// Placeholder matching [_HomeLatestOrderCard] while myOrders loads on home.
class HomeOrderTrackShimmer extends StatelessWidget {
  const HomeOrderTrackShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    final base = Colors.grey.shade300;
    final highlight = Colors.grey.shade100;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(50, 50, 50, 0.15),
            offset: Offset(0, 0),
            blurRadius: 2,
          ),
        ],
      ),
      child: Shimmer.fromColors(
        baseColor: base,
        highlightColor: highlight,
        period: const Duration(milliseconds: 1200),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 160.w,
              height: 16.h,
              decoration: BoxDecoration(
                color: base,
                borderRadius: BorderRadius.circular(4.r),
              ),
            ),
            SizedBox(height: 8.h),
            Container(
              width: 100.w,
              height: 14.h,
              decoration: BoxDecoration(
                color: base,
                borderRadius: BorderRadius.circular(4.r),
              ),
            ),
            SizedBox(height: 16.h),
            Row(
              children: List.generate(
                5,
                (_) => Expanded(
                  child: Column(
                    children: [
                      Container(
                        width: 30.w,
                        height: 30.h,
                        decoration: BoxDecoration(
                          color: base,
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                      ),
                      SizedBox(height: 10.h),
                      Container(
                        width: 40.w,
                        height: 10.h,
                        decoration: BoxDecoration(
                          color: base,
                          borderRadius: BorderRadius.circular(4.r),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(height: 16.h),
            Container(
              width: double.infinity,
              height: 46.h,
              decoration: BoxDecoration(
                color: base,
                borderRadius: BorderRadius.circular(8.r),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
