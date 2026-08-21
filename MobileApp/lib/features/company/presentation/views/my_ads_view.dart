import 'package:alrasmarket/core/router/app_router.dart';
import 'package:alrasmarket/core/serveses/auth_service.dart';
import 'package:alrasmarket/core/services_locator/services_locator.dart';
import 'package:alrasmarket/core/theme/app_fonts.dart';
import 'package:alrasmarket/core/theme/colors.dart';
import 'package:alrasmarket/features/clint/presentation/controller/cubit/clint_cubit.dart';
import 'package:alrasmarket/features/clint/presentation/controller/cubit/clint_states.dart';
import 'package:alrasmarket/features/clint/presentation/widgets/order_card.dart';
import 'package:alrasmarket/features/company/data/models/my_listing_product_model.dart';
import 'package:alrasmarket/features/company/presentation/controller/cubit/company_cubit.dart';
import 'package:alrasmarket/features/company/presentation/controller/cubit/company_states.dart';
import 'package:alrasmarket/features/company/presentation/models/my_ads_filter.dart';
import 'package:alrasmarket/features/company/presentation/models/my_ads_listing_status_filter.dart';
import 'package:alrasmarket/features/company/presentation/controller/cubit/create_ad_cubit.dart';
import 'package:alrasmarket/features/company/presentation/views/create_ad.dart';
import 'package:alrasmarket/features/company/presentation/widgets/my_ads/change_prices_banner.dart';
import 'package:alrasmarket/features/company/presentation/widgets/my_ads/my_ads_filter_chips.dart';
import 'package:alrasmarket/features/company/presentation/widgets/my_ads/my_ads_header_widget.dart';
import 'package:alrasmarket/features/company/presentation/widgets/my_ads/my_ads_list_placeholder_widget.dart';
import 'package:alrasmarket/generated/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

/// Account tab: My Ads (listings) + My Offers (offers submitted on Request ads).
class MyAdsView extends StatefulWidget {
  const MyAdsView({
    super.key,
    this.isTabView = false,
    this.highlightProductId,
    this.actingOwnerId,
    this.companyName,
  });

  /// When true, hides back button (embedded in bottom navigation).
  final bool isTabView;

  /// When set (e.g. from a new-order notification), scroll/highlight that ad.
  final String? highlightProductId;

  /// Admin managing this company's ads.
  final String? actingOwnerId;
  final String? companyName;

  @override
  State<MyAdsView> createState() => _MyAdsViewState();
}

class _MyAdsViewState extends State<MyAdsView> {
  int _accountSectionIndex = 0;
  int _selectedTypeFilterIndex = 0;
  int _selectedStatusFilterIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final cubit = context.read<CompanyCubit>();
      cubit.listingsOwnerId = widget.actingOwnerId;
      // Clear filters so the highlighted product is visible.
      if (widget.highlightProductId != null &&
          widget.highlightProductId!.trim().isNotEmpty) {
        cubit.setMyListingsFilter(
          _isCompanyCustomerAccount
              ? MyAdsFilter.requests.productTypeName
              : _isOverseasSupplierAccount
                  ? MyAdsFilter.booking.productTypeName
                  : null,
        );
        cubit.setMyListingsStatusFilter(null);
        setState(() {
          _selectedTypeFilterIndex = _isCompanyCustomerAccount
              ? MyAdsFilter.requests.index
              : _isOverseasSupplierAccount
                  ? MyAdsFilter.booking.index
                  : 0;
          _selectedStatusFilterIndex = 0;
          _accountSectionIndex = 0;
        });
      } else if (_isCompanyCustomerAccount) {
        // Company customers only publish Requests — lock type filter.
        cubit.setMyListingsFilter(MyAdsFilter.requests.productTypeName);
        setState(() => _selectedTypeFilterIndex = MyAdsFilter.requests.index);
      } else if (_isOverseasSupplierAccount) {
        // Non-UAE suppliers only publish Booking — hide other ad-type filters.
        cubit.setMyListingsFilter(MyAdsFilter.booking.productTypeName);
        setState(() => _selectedTypeFilterIndex = MyAdsFilter.booking.index);
      }
      cubit.loadMyListings(context);
    });
  }

  @override
  void dispose() {
    if (widget.actingOwnerId != null &&
        widget.actingOwnerId!.trim().isNotEmpty) {
      sl<CompanyCubit>().listingsOwnerId = null;
    }
    super.dispose();
  }

  Future<void> _openCreateAd() async {
    final cubit = sl<CreateAdCubit>()..actingOwnerId = widget.actingOwnerId;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => CreateAdView(cubit: cubit),
      ),
    );
    if (!mounted) return;
    await context.read<CompanyCubit>().reloadMyListings();
  }

  void _onAccountSectionSelected(int index) {
    setState(() => _accountSectionIndex = index);
    if (index == 1) {
      context.read<ClintCubit>().fetchMyOffers();
    }
  }

  void _onTypeFilterSelected(int index) {
    setState(() => _selectedTypeFilterIndex = index);
    final filter = MyAdsFilter.values[index];
    context.read<CompanyCubit>().setMyListingsFilter(filter.productTypeName);
  }

  void _onStatusFilterSelected(int index) {
    setState(() => _selectedStatusFilterIndex = index);
    final filter = MyAdsListingStatusFilter.values[index];
    final value = switch (filter) {
      MyAdsListingStatusFilter.all => null,
      MyAdsListingStatusFilter.active => 'active',
      MyAdsListingStatusFilter.paused => 'paused',
      MyAdsListingStatusFilter.underReview => 'review',
      MyAdsListingStatusFilter.soldOut => 'sold_out',
    };
    context.read<CompanyCubit>().setMyListingsStatusFilter(value);
  }

  void _onHighlightedProductFound(MyListingProductModel product) {
    if (_isCompanyCustomerAccount || _isOverseasSupplierAccount) return;
    final filter = _filterForProduct(product);
    final index = MyAdsFilter.values.indexOf(filter);
    if (index < 0 || index == _selectedTypeFilterIndex) return;
    // Keep "All" if we can't map — otherwise light the matching type chip in blue.
    if (filter == MyAdsFilter.all) return;
    _onTypeFilterSelected(index);
  }

  MyAdsFilter _filterForProduct(MyListingProductModel product) {
    if (product.isCategoryCatalogProduct) return MyAdsFilter.categories;
    if (product.isRequestProduct) return MyAdsFilter.requests;
    if (product.isOfferProduct) return MyAdsFilter.offers;
    if (product.isBookingProduct) return MyAdsFilter.booking;
    if (product.productTypeId == 1) return MyAdsFilter.retail;
    return MyAdsFilter.all;
  }

  bool get _isActingForCompany =>
      widget.actingOwnerId != null && widget.actingOwnerId!.trim().isNotEmpty;

  bool get _isCompanyCustomerAccount =>
      !_isActingForCompany && AuthService.instance.isCompanyCustomerAccount;

  /// Overseas / non-UAE supplier: Booking ads only — hide other ad-type chips.
  bool get _isOverseasSupplierAccount =>
      !_isActingForCompany &&
      AuthService.instance.isSupplierAccount &&
      !AuthService.instance.isUaePhoneNumber;

  bool get _hideAdTypeFilters =>
      _isCompanyCustomerAccount || _isOverseasSupplierAccount;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final showMyOffersSection =
        !_isCompanyCustomerAccount && !_isActingForCompany;
    final typeItems = MyAdsFilter.values
        .map(
          (filter) => MyAdsFilterChipItem(
            label: filter.label(s),
            icon: filter.icon,
          ),
        )
        .toList();
    final statusItems = MyAdsListingStatusFilter.values
        .map(
          (filter) => MyAdsFilterChipItem(
            label: filter.label(s),
            icon: filter.icon,
            accentColor: filter.accentColor,
          ),
        )
        .toList();

    return BlocProvider.value(
      value: sl<CompanyCubit>(),
      child: SafeArea(
        child: Scaffold(
          backgroundColor: AppColors.scaffold(context),
          floatingActionButton: _isActingForCompany
              ? FloatingActionButton.extended(
                  onPressed: _openCreateAd,
                  backgroundColor: LightColor.defaultColor,
                  icon: const Icon(Icons.add_rounded, color: Colors.white),
                  label: Text(
                    Localizations.localeOf(context).languageCode == 'ar'
                        ? 'إضافة إعلان'
                        : 'Add ad',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                )
              : null,
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              MyAdsHeaderWidget(
                showBackButton: !widget.isTabView,
                title: widget.companyName,
              ),
              const ChangePricesBanner(),
              if (showMyOffersSection)
                _AccountSectionTabs(
                  selectedIndex: _accountSectionIndex,
                  onSelected: _onAccountSectionSelected,
                ),
              if (!showMyOffersSection || _accountSectionIndex == 0) ...[
                if (!_hideAdTypeFilters)
                  MyAdsTypeFilterCards(
                    items: typeItems,
                    selectedIndex: _selectedTypeFilterIndex,
                    onSelected: _onTypeFilterSelected,
                  ),
                BlocBuilder<CompanyCubit, CompanyStates>(
                  buildWhen: (previous, current) =>
                      current is CompanyMyListingsState,
                  builder: (context, state) {
                    final products = state is CompanyMyListingsState
                        ? state.typeFilteredProducts
                        : const <MyListingProductModel>[];
                    final counts = MyAdsListingStatusFilter.values
                        .map(
                          (filter) =>
                              products.where(filter.matches).length,
                        )
                        .toList();
                    return MyAdsStatusFilterChips(
                      items: statusItems,
                      selectedIndex: _selectedStatusFilterIndex,
                      onSelected: _onStatusFilterSelected,
                      counts: counts,
                    );
                  },
                ),
                _RecentListingsHeader(
                  onViewAll: () {
                    if (_hideAdTypeFilters) {
                      if (_selectedStatusFilterIndex != 0) {
                        _onStatusFilterSelected(0);
                      }
                    } else if (_selectedTypeFilterIndex != 0 ||
                        _selectedStatusFilterIndex != 0) {
                      _onTypeFilterSelected(0);
                      _onStatusFilterSelected(0);
                    }
                  },
                ),
                Expanded(
                  child: _MyAdsRefreshableList(
                    highlightProductId: widget.highlightProductId,
                    onHighlightedProductFound: _onHighlightedProductFound,
                  ),
                ),
              ] else if (showMyOffersSection)
                const Expanded(
                  child: _MyOffersRefreshableList(),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AccountSectionTabs extends StatelessWidget {
  const _AccountSectionTabs({
    required this.selectedIndex,
    required this.onSelected,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final fontFamily = AppFonts.familyFor(Localizations.localeOf(context));
    final items = [
      (label: s.myAds, icon: Icons.description_outlined),
      (label: s.myOffers, icon: Icons.local_offer_outlined),
    ];

    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 6.h),
      child: Row(
        children: List.generate(items.length, (index) {
          final isSelected = selectedIndex == index;
          final item = items[index];
          final fg = isSelected ? Colors.white : LightColor.defaultColor;
          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                right: index == 0 ? 8.w : 0,
                left: index == 1 ? 8.w : 0,
              ),
              child: GestureDetector(
                onTap: () => onSelected(index),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: EdgeInsets.symmetric(
                    horizontal: 12.w,
                    vertical: 12.h,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16.r),
                    color: isSelected
                        ? LightColor.defaultColor
                        : AppColors.card(context),
                    border: Border.all(
                      color: LightColor.defaultColor,
                      width: 1.4,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Icon(item.icon, size: 16.sp, color: fg),
                      SizedBox(width: 6.w),
                      Expanded(
                        child: Text(
                          item.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: fg,
                            fontFamily: fontFamily,
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Icon(
                        Icons.chevron_right_rounded,
                        size: 18.sp,
                        color: fg,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _RecentListingsHeader extends StatelessWidget {
  const _RecentListingsHeader({required this.onViewAll});

  final VoidCallback onViewAll;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final fontFamily = AppFonts.familyFor(Localizations.localeOf(context));

    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 2.h, 8.w, 4.h),
      child: Row(
        children: [
          Expanded(
            child: Text(
              s.recentListings,
              style: TextStyle(
                fontFamily: fontFamily,
                fontSize: 14.5.sp,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF16233A),
              ),
            ),
          ),
          TextButton(
            onPressed: onViewAll,
            style: TextButton.styleFrom(
              foregroundColor: LightColor.defaultColor,
              padding: EdgeInsets.symmetric(horizontal: 8.w),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  s.viewAll,
                  style: TextStyle(
                    fontFamily: fontFamily,
                    fontSize: 12.5.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Icon(Icons.chevron_right_rounded, size: 18.sp),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MyAdsRefreshableList extends StatelessWidget {
  const _MyAdsRefreshableList({
    this.highlightProductId,
    this.onHighlightedProductFound,
  });

  final String? highlightProductId;
  final ValueChanged<MyListingProductModel>? onHighlightedProductFound;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () => context.read<CompanyCubit>().reloadMyListings(),
      child: MyAdsListPlaceholderWidget(
        highlightProductId: highlightProductId,
        onHighlightedProductFound: onHighlightedProductFound,
      ),
    );
  }
}

class _MyOffersRefreshableList extends StatelessWidget {
  const _MyOffersRefreshableList();

  @override
  Widget build(BuildContext context) {
    final fontFamily = AppFonts.familyFor(Localizations.localeOf(context));
    final s = S.of(context);

    return BlocBuilder<ClintCubit, ClintStates>(
      buildWhen: (previous, current) =>
          current is FetchMyOffersLoadingState ||
          current is FetchMyOffersSuccessState ||
          current is FetchMyOffersErrorState,
      builder: (context, state) {
        final cubit = ClintCubit.get(context);

        return RefreshIndicator(
          onRefresh: () => cubit.fetchMyOffers(),
          child: cubit.isLoadingMyOffers && cubit.myOffers.isEmpty
              ? ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: const [
                    SizedBox(height: 240),
                    Center(child: CircularProgressIndicator()),
                  ],
                )
              : cubit.myOffersError != null && cubit.myOffers.isEmpty
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        SizedBox(height: 120.h),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 24.w),
                          child: Text(
                            cubit.myOffersError!,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: fontFamily,
                              fontSize: 14.sp,
                            ),
                          ),
                        ),
                      ],
                    )
                  : cubit.myOffers.isEmpty
                      ? ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: [
                            SizedBox(height: 120.h),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 24.w),
                              child: Text(
                                s.noOffersYet,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontFamily: fontFamily,
                                  fontSize: 14.sp,
                                ),
                              ),
                            ),
                          ],
                        )
                      : ListView.separated(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: EdgeInsets.symmetric(
                            horizontal: 24.w,
                            vertical: 8.h,
                          ),
                          itemCount: cubit.myOffers.length,
                          separatorBuilder: (_, __) => SizedBox(height: 24.h),
                          itemBuilder: (context, index) {
                            final order = cubit.myOffers[index];
                            return InkWell(
                              onTap: () => context.push(
                                AppRoutes.kTrackOrderView,
                                extra: {'order': order},
                              ),
                              child: OrderCard(order: order),
                            );
                          },
                        ),
        );
      },
    );
  }
}
