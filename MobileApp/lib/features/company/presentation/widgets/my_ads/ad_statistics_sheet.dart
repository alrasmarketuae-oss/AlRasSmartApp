import 'package:alrasmarket/core/services/product_engagement_service.dart';
import 'package:alrasmarket/core/theme/app_fonts.dart';
import 'package:alrasmarket/core/theme/colors.dart';
import 'package:alrasmarket/core/utils/string_display_format.dart';
import 'package:alrasmarket/features/company/data/models/my_listing_product_model.dart';
import 'package:alrasmarket/generated/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

Future<void> showAdStatisticsSheet(
  BuildContext context, {
  required MyListingProductModel product,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) => _AdStatisticsSheet(product: product),
  );
}

class _AdStatisticsSheet extends StatefulWidget {
  const _AdStatisticsSheet({required this.product});

  final MyListingProductModel product;

  @override
  State<_AdStatisticsSheet> createState() => _AdStatisticsSheetState();
}

class _AdStatisticsSheetState extends State<_AdStatisticsSheet> {
  bool _loading = true;
  ProductAdStatistics? _stats;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final stats = await ProductEngagementService.fetchOwnerStatistics(
      widget.product.productId,
    );
    if (!mounted) return;
    setState(() {
      _stats = stats;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final fontFamily = AppFonts.fontFamily(context);
    final title = widget.product.localeDisplayName.capitalizeFirst();

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.72,
      ),
      decoration: BoxDecoration(
        color: AppColors.scaffold(context),
        borderRadius: BorderRadius.vertical(top: Radius.circular(18.r)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(16.w, 10.h, 16.w, 16.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40.w,
                  height: 4.h,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD0D5DD),
                    borderRadius: BorderRadius.circular(99.r),
                  ),
                ),
              ),
              SizedBox(height: 14.h),
              Text(
                s.adStatistics,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: fontFamily,
                  fontSize: 17.sp,
                  fontWeight: FontWeight.w800,
                  color: AppColors.title(context),
                ),
              ),
              if (title.isNotEmpty) ...[
                SizedBox(height: 4.h),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: fontFamily,
                    fontSize: 13.sp,
                    color: LightColor.greyTextColor,
                  ),
                ),
              ],
              SizedBox(height: 16.h),
              if (_loading)
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 28.h),
                  child: const Center(child: CircularProgressIndicator()),
                )
              else if (_stats == null)
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 24.h),
                  child: Text(
                    isAr ? 'تعذر تحميل الإحصائيات' : 'Could not load statistics',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: fontFamily,
                      fontSize: 14.sp,
                      color: LightColor.greyTextColor,
                    ),
                  ),
                )
              else
                Flexible(
                  child: ListView(
                    shrinkWrap: true,
                    children: [
                      _StatRow(
                        icon: Icons.visibility_outlined,
                        label: s.adStatVisits,
                        value: _stats!.viewsCount,
                        fontFamily: fontFamily,
                      ),
                      if (_stats!.showCartAdds ||
                          widget.product.isRetailFeedProduct)
                        _StatRow(
                          icon: Icons.shopping_cart_outlined,
                          label: s.adStatCartAdds,
                          value: _stats!.cartAddsCount,
                          fontFamily: fontFamily,
                        ),
                      _StatRow(
                        icon: Icons.shopping_bag_outlined,
                        label: s.adStatPurchases,
                        value: _stats!.purchasesCount,
                        fontFamily: fontFamily,
                      ),
                      _StatRow(
                        icon: Icons.bookmark_border_rounded,
                        label: s.adStatFavorites,
                        value: _stats!.favoritesCount,
                        fontFamily: fontFamily,
                      ),
                      _StatRow(
                        icon: Icons.share_outlined,
                        label: s.adStatShares,
                        value: _stats!.sharesCount,
                        fontFamily: fontFamily,
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.fontFamily,
  });

  final IconData icon;
  final String label;
  final int value;
  final String fontFamily;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 10.h),
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: const Color(0xFFE4E7EC)),
      ),
      child: Row(
        children: [
          Container(
            width: 36.w,
            height: 36.w,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: Color(0xFFE8F2FC),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 18.sp, color: LightColor.defaultColor),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontFamily: fontFamily,
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                color: AppColors.title(context),
              ),
            ),
          ),
          Text(
            value.toString(),
            style: TextStyle(
              fontFamily: fontFamily,
              fontSize: 16.sp,
              fontWeight: FontWeight.w800,
              color: LightColor.defaultColor,
            ),
          ),
        ],
      ),
    );
  }
}
