import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shimmer/shimmer.dart';

/// Placeholder matching [BannerSlider] layout while home banners load.
class BannerSliderShimmer extends StatelessWidget {
  const BannerSliderShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    final base = Colors.grey.shade300;
    final highlight = Colors.grey.shade100;
    return SizedBox(
      height: 136.h,
      width: double.infinity,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 24.w),
        child: Shimmer.fromColors(
          baseColor: base,
          highlightColor: highlight,
          period: const Duration(milliseconds: 1200),
          child: Row(
            children: [
              Expanded(
                flex: 8,
                child: Container(
                  margin: EdgeInsets.symmetric(horizontal: 5.w),
                  decoration: BoxDecoration(
                    color: base,
                    borderRadius: BorderRadius.circular(18.r),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
