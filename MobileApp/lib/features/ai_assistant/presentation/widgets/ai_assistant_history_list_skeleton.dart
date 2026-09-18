import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shimmer/shimmer.dart';

/// Dark list skeleton matching AI history [_HistoryTile] rows.
class AiAssistantHistoryListSkeleton extends StatelessWidget {
  const AiAssistantHistoryListSkeleton({super.key, this.itemCount = 8});

  final int itemCount;

  static const _base = Color(0xFF374151);
  static const _highlight = Color(0xFF4B5563);
  static const _fill = Color(0xFF1F2937);
  static const _tile = Color(0xFF111827);

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 28.h),
      itemCount: itemCount,
      separatorBuilder: (_, __) => SizedBox(height: 10.h),
      itemBuilder: (_, __) {
        return Shimmer.fromColors(
          baseColor: _base,
          highlightColor: _highlight,
          period: const Duration(milliseconds: 1200),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
            decoration: BoxDecoration(
              color: _tile,
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(color: _fill),
            ),
            child: Row(
              children: [
                Container(
                  width: 44.w,
                  height: 44.w,
                  decoration: BoxDecoration(
                    color: _fill,
                    borderRadius: BorderRadius.circular(14.r),
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 14.h,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: _fill,
                          borderRadius: BorderRadius.circular(4.r),
                        ),
                      ),
                      SizedBox(height: 8.h),
                      FractionallySizedBox(
                        widthFactor: 0.45,
                        alignment: AlignmentDirectional.centerStart,
                        child: Container(
                          height: 12.h,
                          decoration: BoxDecoration(
                            color: _fill,
                            borderRadius: BorderRadius.circular(4.r),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 8.w),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      height: 11.h,
                      width: 48.w,
                      decoration: BoxDecoration(
                        color: _fill,
                        borderRadius: BorderRadius.circular(4.r),
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Container(
                      height: 18.w,
                      width: 18.w,
                      decoration: BoxDecoration(
                        color: _fill,
                        borderRadius: BorderRadius.circular(4.r),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
