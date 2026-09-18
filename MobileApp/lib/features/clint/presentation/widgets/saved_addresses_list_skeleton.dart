import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shimmer/shimmer.dart';

/// Shimmer placeholders matching saved-address list cards.
class SavedAddressesListSkeleton extends StatelessWidget {
  const SavedAddressesListSkeleton({super.key, this.itemCount = 6});

  final int itemCount;

  @override
  Widget build(BuildContext context) {
    final base = Colors.grey.shade300;
    final highlight = Colors.grey.shade100;

    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
      itemCount: itemCount,
      separatorBuilder: (_, __) => SizedBox(height: 12.h),
      itemBuilder: (_, __) {
        return Shimmer.fromColors(
          baseColor: base,
          highlightColor: highlight,
          period: const Duration(milliseconds: 1200),
          child: Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12.r),
              boxShadow: const [
                BoxShadow(
                  color: Color.fromRGBO(0, 0, 0, 0.06),
                  blurRadius: 4,
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 24.w,
                  height: 24.w,
                  decoration: BoxDecoration(
                    color: base,
                    borderRadius: BorderRadius.circular(6.r),
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FractionallySizedBox(
                        widthFactor: 0.55,
                        alignment: AlignmentDirectional.centerStart,
                        child: Container(
                          height: 14.h,
                          decoration: BoxDecoration(
                            color: base,
                            borderRadius: BorderRadius.circular(4.r),
                          ),
                        ),
                      ),
                      SizedBox(height: 8.h),
                      FractionallySizedBox(
                        widthFactor: 0.35,
                        alignment: AlignmentDirectional.centerStart,
                        child: Container(
                          height: 12.h,
                          decoration: BoxDecoration(
                            color: base,
                            borderRadius: BorderRadius.circular(4.r),
                          ),
                        ),
                      ),
                      SizedBox(height: 8.h),
                      Container(
                        height: 12.h,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: base,
                          borderRadius: BorderRadius.circular(4.r),
                        ),
                      ),
                      SizedBox(height: 6.h),
                      FractionallySizedBox(
                        widthFactor: 0.7,
                        alignment: AlignmentDirectional.centerStart,
                        child: Container(
                          height: 12.h,
                          decoration: BoxDecoration(
                            color: base,
                            borderRadius: BorderRadius.circular(4.r),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 8.w),
                Container(
                  width: 20.w,
                  height: 20.w,
                  decoration: BoxDecoration(
                    color: base,
                    borderRadius: BorderRadius.circular(4.r),
                  ),
                ),
                SizedBox(width: 8.w),
                Container(
                  width: 20.w,
                  height: 20.w,
                  decoration: BoxDecoration(
                    color: base,
                    borderRadius: BorderRadius.circular(4.r),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
