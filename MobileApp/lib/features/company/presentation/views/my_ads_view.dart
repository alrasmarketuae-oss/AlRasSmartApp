import 'package:alrasmarket/core/router/app_router.dart';
import 'package:alrasmarket/core/services_locator/services_locator.dart';
import 'package:alrasmarket/core/theme/app_fonts.dart';
import 'package:alrasmarket/core/theme/colors.dart';
import 'package:alrasmarket/features/clint/presentation/controller/cubit/clint_cubit.dart';
import 'package:alrasmarket/features/clint/presentation/controller/cubit/clint_states.dart';
import 'package:alrasmarket/features/clint/presentation/widgets/order_card.dart';
import 'package:alrasmarket/features/company/presentation/controller/cubit/company_cubit.dart';
import 'package:alrasmarket/features/company/presentation/models/my_ads_filter.dart';
import 'package:alrasmarket/features/company/presentation/models/my_ads_listing_status_filter.dart';
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
  });

  /// When true, hides back button (embedded in bottom navigation).
  final bool isTabView;

  /// When set (e.g. from a new-order notification), scroll/highlight that ad.
  final String? highlightProductId;

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
      // Clear filters so the highlighted product is visible.
      if (widget.highlightProductId != null &&
          widget.highlightProductId!.trim().isNotEmpty) {
        cubit.setMyListingsFilter(null);
        cubit.setMyListingsStatusFilter(null);
        setState(() {
          _selectedTypeFilterIndex = 0;
          _selectedStatusFilterIndex = 0;
          _accountSectionIndex = 0;
        });
      }
      cubit.loadMyListings(context);
    });
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

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
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
          backgroundColor: Colors.white,
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              MyAdsHeaderWidget(showBackButton: !widget.isTabView),
              _AccountSectionTabs(
                selectedIndex: _accountSectionIndex,
                onSelected: _onAccountSectionSelected,
              ),
              if (_accountSectionIndex == 0) ...[
                MyAdsTypeFilterCards(
                  items: typeItems,
                  selectedIndex: _selectedTypeFilterIndex,
                  onSelected: _onTypeFilterSelected,
                ),
                MyAdsStatusFilterChips(
                  items: statusItems,
                  selectedIndex: _selectedStatusFilterIndex,
                  onSelected: _onStatusFilterSelected,
                ),
                Expanded(
                  child: _MyAdsRefreshableList(
                    highlightProductId: widget.highlightProductId,
                  ),
                ),
              ] else
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
      (label: s.myAds, icon: Icons.badge_outlined),
      (label: s.myOffers, icon: Icons.local_offer_outlined),
    ];

    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 4.h),
      child: Row(
        children: List.generate(items.length, (index) {
          final isSelected = selectedIndex == index;
          final item = items[index];
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
                  padding: EdgeInsets.symmetric(vertical: 12.h),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10.r),
                    color: isSelected
                        ? LightColor.defaultColor
                        : Colors.white,
                    border: Border.all(
                      color: LightColor.defaultColor,
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        item.icon,
                        size: 18.sp,
                        color: isSelected
                            ? Colors.white
                            : LightColor.defaultColor,
                      ),
                      SizedBox(width: 6.w),
                      Text(
                        item.label,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: isSelected
                              ? Colors.white
                              : LightColor.defaultColor,
                          fontFamily: fontFamily,
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                        ),
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

class _MyAdsRefreshableList extends StatelessWidget {
  const _MyAdsRefreshableList({this.highlightProductId});

  final String? highlightProductId;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () => context.read<CompanyCubit>().reloadMyListings(),
      child: MyAdsListPlaceholderWidget(
        highlightProductId: highlightProductId,
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
