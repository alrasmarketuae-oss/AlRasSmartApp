import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shimmer/shimmer.dart';

/// Shimmer placeholders matching compact [MyAdAnnouncementCard] rows on Account.
class MyAdsListSkeleton extends StatelessWidget {
  const MyAdsListSkeleton({super.key, this.itemCount = 6});

  final int itemCount;

  @override
  Widget build(BuildContext context) {
    final base = Colors.grey.shade300;
    final highlight = Colors.grey.shade100;

    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(16.w, 4.h, 16.w, 16.h),
      itemCount: itemCount,
      separatorBuilder: (_, __) => SizedBox(height: 10.h),
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: base,
          highlightColor: highlight,
          period: const Duration(milliseconds: 1200),
          child: _MyAdCardSkeleton(baseColor: base),
        );
      },
    );
  }
}

class _MyAdCardSkeleton extends StatelessWidget {
  const _MyAdCardSkeleton({required this.baseColor});

  final Color baseColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 132.h,
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            width: 96.w,
            decoration: BoxDecoration(
              color: baseColor,
              borderRadius: BorderRadius.circular(10.r),
            ),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 14.h,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: baseColor,
                    borderRadius: BorderRadius.circular(4.r),
                  ),
                ),
                SizedBox(height: 6.h),
                FractionallySizedBox(
                  widthFactor: 0.65,
                  alignment: AlignmentDirectional.centerStart,
                  child: Container(
                    height: 12.h,
                    decoration: BoxDecoration(
                      color: baseColor,
                      borderRadius: BorderRadius.circular(4.r),
                    ),
                  ),
                ),
                SizedBox(height: 8.h),
                Row(
                  children: [
                    Container(
                      height: 18.h,
                      width: 64.w,
                      decoration: BoxDecoration(
                        color: baseColor,
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                    ),
                    SizedBox(width: 6.w),
                    Container(
                      height: 18.h,
                      width: 48.w,
                      decoration: BoxDecoration(
                        color: baseColor,
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Container(
                  height: 12.h,
                  width: 90.w,
                  decoration: BoxDecoration(
                    color: baseColor,
                    borderRadius: BorderRadius.circular(4.r),
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

/// Shimmer placeholders matching [OrderCard] rows on Account → My Offers.
class MyOffersListSkeleton extends StatelessWidget {
  const MyOffersListSkeleton({super.key, this.itemCount = 4});

  final int itemCount;

  @override
  Widget build(BuildContext context) {
    final base = Colors.grey.shade300;
    final highlight = Colors.grey.shade100;

    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 8.h),
      itemCount: itemCount,
      separatorBuilder: (_, __) => SizedBox(height: 24.h),
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: base,
          highlightColor: highlight,
          period: const Duration(milliseconds: 1200),
          child: _OfferCardSkeleton(baseColor: base),
        );
      },
    );
  }
}

class _OfferCardSkeleton extends StatelessWidget {
  const _OfferCardSkeleton({required this.baseColor});

  final Color baseColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48.w,
                height: 48.w,
                decoration: BoxDecoration(
                  color: baseColor,
                  borderRadius: BorderRadius.circular(10.r),
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
                        color: baseColor,
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
                          color: baseColor,
                          borderRadius: BorderRadius.circular(4.r),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 14.h),
          Container(
            height: 12.h,
            width: double.infinity,
            decoration: BoxDecoration(
              color: baseColor,
              borderRadius: BorderRadius.circular(4.r),
            ),
          ),
          SizedBox(height: 8.h),
          FractionallySizedBox(
            widthFactor: 0.7,
            alignment: AlignmentDirectional.centerStart,
            child: Container(
              height: 12.h,
              decoration: BoxDecoration(
                color: baseColor,
                borderRadius: BorderRadius.circular(4.r),
              ),
            ),
          ),
          SizedBox(height: 14.h),
          Container(
            height: 42.h,
            width: double.infinity,
            decoration: BoxDecoration(
              color: baseColor,
              borderRadius: BorderRadius.circular(10.r),
            ),
          ),
        ],
      ),
    );
  }
}
