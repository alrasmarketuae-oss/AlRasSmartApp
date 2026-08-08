import 'package:alrasmarket/core/theme/app_fonts.dart';
import 'package:alrasmarket/core/theme/colors.dart';
import 'package:alrasmarket/core/utils/product_grid_layout.dart';
import 'package:alrasmarket/features/company/data/models/my_listing_product_model.dart';
import 'package:alrasmarket/features/company/presentation/controller/cubit/company_cubit.dart';
import 'package:alrasmarket/features/company/presentation/controller/cubit/company_states.dart';
import 'package:alrasmarket/features/company/presentation/models/my_ads_filter.dart';
import 'package:alrasmarket/features/company/presentation/widgets/my_ads/my_ad_announcement_card.dart';
import 'package:alrasmarket/generated/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class MyAdsListPlaceholderWidget extends StatefulWidget {
  const MyAdsListPlaceholderWidget({
    super.key,
    this.highlightProductId,
    this.onHighlightedProductFound,
  });

  final String? highlightProductId;

  /// Called once when the highlighted listing is found (e.g. to light its type filter).
  final ValueChanged<MyListingProductModel>? onHighlightedProductFound;

  /// Account My Ads: phone = 2 columns, tablet = 3.
  static int _crossAxisCount(BuildContext context) =>
      ProductGridLayout.isTablet(context) ? 3 : 2;

  @override
  State<MyAdsListPlaceholderWidget> createState() =>
      _MyAdsListPlaceholderWidgetState();
}

class _MyAdsListPlaceholderWidgetState
    extends State<MyAdsListPlaceholderWidget> {
  final ScrollController _scrollController = ScrollController();
  String? _scrolledForId;
  String? _notifiedHighlightId;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  bool _idsMatch(String a, String b) =>
      a.trim().toLowerCase() == b.trim().toLowerCase();

  void _scrollToHighlightIfNeeded({
    required List products,
    required int columns,
    required double cellHeight,
    required double mainSpacing,
  }) {
    final targetId = widget.highlightProductId?.trim() ?? '';
    if (targetId.isEmpty || products.isEmpty) return;
    if (_scrolledForId != null && _idsMatch(_scrolledForId!, targetId)) {
      return;
    }

    final index = products.indexWhere(
      (p) => _idsMatch(p.productId.toString(), targetId),
    );
    if (index < 0) return;

    _scrolledForId = targetId;
    final matched = products[index];
    if (_notifiedHighlightId == null ||
        !_idsMatch(_notifiedHighlightId!, targetId)) {
      _notifiedHighlightId = targetId;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.onHighlightedProductFound?.call(matched);
      });
    }

    final row = index ~/ columns;
    final offset = row * (cellHeight + mainSpacing);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;
      final max = _scrollController.position.maxScrollExtent;
      _scrollController.animateTo(
        offset.clamp(0.0, max),
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeOutCubic,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CompanyCubit, CompanyStates>(
      buildWhen: (previous, current) => current is CompanyMyListingsState,
      builder: (context, state) {
        if (state is! CompanyMyListingsState) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state.isLoading) {
          return ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: const [
              SizedBox(height: 240),
              Center(child: CircularProgressIndicator()),
            ],
          );
        }

        if (state.errorMessage != null) {
          return ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              SizedBox(height: 120.h),
              _MessageView(
                icon: Icons.error_outline,
                title: state.errorMessage!,
              ),
            ],
          );
        }

        final products = state.filteredProducts;
        if (products.isEmpty) {
          final hasFilters = (state.typeFilter != null &&
                  state.typeFilter!.isNotEmpty) ||
              (state.statusFilter != null && state.statusFilter!.isNotEmpty);
          return ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              SizedBox(height: 120.h),
              _MessageView(
                icon: Icons.inventory_2_outlined,
                title: state.products.isEmpty
                    ? 'No products found'
                    : (hasFilters
                        ? S.of(context).noAdsMatchFilter
                        : 'No products found'),
              ),
            ],
          );
        }

        final preferRetail = state.preferRetailPricing;
        final preferCategory = state.typeFilter ==
            MyAdsFilter.categoriesFilterKey;
        final showBothPricing = state.typeFilter == null ||
            state.typeFilter!.isEmpty;

        final horizontalPadding = 24.w;
        final crossSpacing = 12.w;
        final mainSpacing = 12.h;
        final columns = MyAdsListPlaceholderWidget._crossAxisCount(context);
        final isTablet = ProductGridLayout.isTablet(context);
        final cellHeight = isTablet ? 370.h : 320.h;
        final highlightId = widget.highlightProductId?.trim() ?? '';

        _scrollToHighlightIfNeeded(
          products: products,
          columns: columns,
          cellHeight: cellHeight,
          mainSpacing: mainSpacing,
        );

        return GridView.builder(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.symmetric(
            horizontal: horizontalPadding,
            vertical: 8.h,
          ),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: crossSpacing,
            mainAxisSpacing: mainSpacing,
            mainAxisExtent: cellHeight,
          ),
          itemCount: products.length,
          itemBuilder: (context, index) {
            final product = products[index];
            final highlighted = highlightId.isNotEmpty &&
                _idsMatch(product.productId, highlightId);
            return MyAdAnnouncementCard(
              product: product,
              compact: true,
              highlighted: highlighted,
              persistentGlow: product.pendingOffersCount > 0,
              preferRetailPricing: preferRetail,
              preferCategoryLabel: preferCategory,
              showBothPricingChannels: showBothPricing,
            );
          },
        );
      },
    );
  }
}

class _MessageView extends StatelessWidget {
  const _MessageView({
    required this.icon,
    required this.title,
  });

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    final fontFamily = AppFonts.familyFor(Localizations.localeOf(context));

    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 32.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 56.sp,
              color: LightColor.defaultColor.withValues(alpha: 0.5),
            ),
            SizedBox(height: 16.h),
            Text(
              title,
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: fontFamily,
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
                color: LightColor.greyTextColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
