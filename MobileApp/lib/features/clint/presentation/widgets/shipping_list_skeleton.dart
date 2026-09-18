import 'package:alrasmarket/core/theme/colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shimmer/shimmer.dart';

/// Shimmer placeholders matching compact [ShippingCard] list items.
class ShippingListSkeleton extends StatelessWidget {
  const ShippingListSkeleton({super.key, this.itemCount = 5});

  final int itemCount;

  @override
  Widget build(BuildContext context) {
    final base = Colors.grey.shade300;
    final highlight = Colors.grey.shade100;

    return SliverPadding(
      padding: EdgeInsets.fromLTRB(
        16.w,
        0,
        16.w,
        16.h + kBottomNavigationBarHeight,
      ),
      sliver: SliverList.separated(
        itemCount: itemCount,
        separatorBuilder: (_, __) => SizedBox(height: 16.h),
        itemBuilder: (_, __) {
          return Shimmer.fromColors(
            baseColor: base,
            highlightColor: highlight,
            period: const Duration(milliseconds: 1200),
            child: Container(
              padding: EdgeInsets.fromLTRB(12.w, 14.h, 12.w, 14.h),
              decoration: BoxDecoration(
                color: AppColors.card(context),
                borderRadius: BorderRadius.circular(14.r),
                border: Border.all(color: AppColors.border(context)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: FractionallySizedBox(
                      widthFactor: 0.45,
                      child: Container(
                        height: 16.h,
                        decoration: BoxDecoration(
                          color: base,
                          borderRadius: BorderRadius.circular(4.r),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 12.h),
                  Container(
                    height: 44.h,
                    decoration: BoxDecoration(
                      color: base,
                      borderRadius: BorderRadius.circular(22.r),
                    ),
                  ),
                  SizedBox(height: 10.h),
                  Center(
                    child: Container(
                      width: 120.w,
                      height: 14.h,
                      decoration: BoxDecoration(
                        color: base,
                        borderRadius: BorderRadius.circular(4.r),
                      ),
                    ),
                  ),
                  SizedBox(height: 12.h),
                  Container(
                    height: 12.h,
                    decoration: BoxDecoration(
                      color: base,
                      borderRadius: BorderRadius.circular(4.r),
                    ),
                  ),
                  SizedBox(height: 6.h),
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: FractionallySizedBox(
                      widthFactor: 0.72,
                      child: Container(
                        height: 12.h,
                        decoration: BoxDecoration(
                          color: base,
                          borderRadius: BorderRadius.circular(4.r),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 14.h),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 36.h,
                          decoration: BoxDecoration(
                            color: base,
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                        ),
                      ),
                      SizedBox(width: 10.w),
                      Expanded(
                        child: Container(
                          height: 36.h,
                          decoration: BoxDecoration(
                            color: base,
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
