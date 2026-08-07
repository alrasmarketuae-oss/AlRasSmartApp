import 'package:alrasmarket/core/utils/product_grid_layout.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shimmer/shimmer.dart';

/// Shimmer placeholders matching [ServiceProductsGrid] / product cards.
class ProductGridSkeleton extends StatelessWidget {
  const ProductGridSkeleton({
    super.key,
    this.useOfferCard = false,
    this.itemCount = 6,
  });

  final bool useOfferCard;
  final int itemCount;

  @override
  Widget build(BuildContext context) {
    final horizontalPadding =
        ProductGridLayout.categoryHorizontalPadding(context);
    final crossSpacing = 16.w;
    final mainSpacing = 16.h;
    final base = Colors.grey.shade300;
    final highlight = Colors.grey.shade100;

    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverPadding(
          padding: EdgeInsets.fromLTRB(24.w, 8.h, 24.w, 24.h),
          sliver: SliverGrid(
            gridDelegate: useOfferCard
                ? ProductGridLayout.offerDelegate(
                    context,
                    horizontalPadding: horizontalPadding,
                    crossAxisSpacing: crossSpacing,
                    mainAxisSpacing: mainSpacing,
                  )
                : ProductGridLayout.delegate(
                    context,
                    horizontalPadding: horizontalPadding,
                    crossAxisSpacing: crossSpacing,
                    mainAxisSpacing: mainSpacing,
                  ),
            delegate: SliverChildBuilderDelegate(
              (context, index) => Shimmer.fromColors(
                baseColor: base,
                highlightColor: highlight,
                period: const Duration(milliseconds: 1200),
                child: _ProductCardSkeleton(
                  useOfferExtras: useOfferCard,
                  baseColor: base,
                ),
              ),
              childCount: itemCount,
            ),
          ),
        ),
      ],
    );
  }
}

class _ProductCardSkeleton extends StatelessWidget {
  const _ProductCardSkeleton({
    required this.useOfferExtras,
    required this.baseColor,
  });

  final bool useOfferExtras;
  final Color baseColor;

  @override
  Widget build(BuildContext context) {
    final imageHeight = ProductGridLayout.cardImageDisplayHeight(context);
    final contentInsets = ProductGridLayout.cardContentInsets(context);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: imageHeight,
            color: baseColor,
          ),
          Expanded(
            child: Padding(
              padding: contentInsets,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (useOfferExtras) ...[
                    Container(
                      height: ProductGridLayout.offerDealBandHeight(context),
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: baseColor,
                        borderRadius: BorderRadius.circular(4.r),
                      ),
                    ),
                    SizedBox(height: 6.h),
                  ],
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
                    widthFactor: 0.72,
                    child: Container(
                      height: 14.h,
                      decoration: BoxDecoration(
                        color: baseColor,
                        borderRadius: BorderRadius.circular(4.r),
                      ),
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Container(
                    height: 11.h,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: baseColor,
                      borderRadius: BorderRadius.circular(4.r),
                    ),
                  ),
                  SizedBox(height: 4.h),
                  FractionallySizedBox(
                    widthFactor: 0.55,
                    child: Container(
                      height: 11.h,
                      decoration: BoxDecoration(
                        color: baseColor,
                        borderRadius: BorderRadius.circular(4.r),
                      ),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    height: 1,
                    color: baseColor.withValues(alpha: 0.7),
                  ),
                  SizedBox(height: 8.h),
                  Container(
                    height: 16.h,
                    width: 90.w,
                    decoration: BoxDecoration(
                      color: baseColor,
                      borderRadius: BorderRadius.circular(4.r),
                    ),
                  ),
                  SizedBox(height: 6.h),
                  Container(
                    height: 11.h,
                    width: 70.w,
                    decoration: BoxDecoration(
                      color: baseColor,
                      borderRadius: BorderRadius.circular(4.r),
                    ),
                  ),
                  if (useOfferExtras) ...[
                    SizedBox(height: 6.h),
                    Container(
                      height: ProductGridLayout.offerTimerBlockHeight(context),
                      width: 100.w,
                      decoration: BoxDecoration(
                        color: baseColor,
                        borderRadius: BorderRadius.circular(4.r),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
