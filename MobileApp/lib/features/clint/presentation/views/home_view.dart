import 'dart:async';

import 'package:alrasmarket/core/router/app_router.dart';
import 'package:alrasmarket/core/serveses/auth_service.dart';
import 'package:alrasmarket/core/theme/colors.dart';
import 'package:alrasmarket/core/utils/assets.dart';
import 'package:alrasmarket/core/utils/product_grid_layout.dart';
import 'package:alrasmarket/features/clint/domain/entities/banner_adds.dart';
import 'package:alrasmarket/features/clint/presentation/controller/cubit/clint_cubit.dart';
import 'package:alrasmarket/features/clint/presentation/controller/cubit/clint_states.dart';
import 'package:alrasmarket/features/clint/presentation/widgets/product _card.dart';
import 'package:alrasmarket/features/clint/presentation/widgets/banner_slider.dart';
import 'package:alrasmarket/features/clint/presentation/widgets/banner_slider_shimmer.dart';
import 'package:alrasmarket/features/clint/presentation/widgets/search_header.dart';
import 'package:alrasmarket/core/utils/category_localization.dart';
import 'package:alrasmarket/features/clint/data/models/category_model.dart';
import 'package:alrasmarket/features/clint/presentation/widgets/category_label.dart';
import 'package:alrasmarket/features/clint/presentation/widgets/category_image.dart';
import 'package:alrasmarket/generated/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

/// Shown when home banners API fails; uses bundled assets (same idea as the old hard-coded banners).
final List<BannerAdds> _localFallbackBanners = [
  BannerAdds(
    bannerId: -2,
    imageUrl: AppAssets.bannerImage2,
    isActive: true,
    linkUrl: 'https://www.google.com',
  ),
  BannerAdds(
    bannerId: -1,
    imageUrl: AppAssets.bannerImage,
    isActive: true,
    linkUrl: 'https://www.google.com',
  ),
  BannerAdds(
    bannerId: -2,
    imageUrl: AppAssets.bannerImage2,
    isActive: true,
    linkUrl: 'https://www.google.com',
  ),
];

class HomeView extends StatefulWidget {
  const HomeView({super.key, this.isPerson = false, this.isCompany = false});

  final bool isPerson;
  final bool isCompany;

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _loadHomeData();
    });
  }

  void _loadHomeData() {
    final cubit = context.read<ClintCubit>();
    final isPersonalCustomer = AuthService.instance.isPersonalCustomerAccount;
    final isGuest = AuthService.instance.isGuest;
    // Guest must never keep a previous personal retail feed in memory.
    if (isGuest) {
      cubit.clearHomeCatalogMemory();
    }
    // Guest browses category catalog (same feed path as company home).
    unawaited(
      cubit.preloadHomeFromDisk(isPerson: isPersonalCustomer).whenComplete(() {
        if (!mounted) return;
        cubit.refreshHomeFeed(
          isPerson: isPersonalCustomer,
          resetCached: isGuest,
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ClintCubit, ClintStates>(
      buildWhen: (previous, current) =>
          current is ClintInitialState ||
          current is ClintTabState ||
          current is FetchBannersLoadingState ||
          current is FetchBannersSuccessState ||
          current is FetchBannersErrorState ||
          current is FetchCategoriesLoadingState ||
          current is FetchCategoriesSuccessState ||
          current is FetchCategoriesErrorState ||
          current is FetchHomeProductsLoadingState ||
          current is FetchHomeProductsLoadingMoreState ||
          current is FetchHomeProductsSuccessState ||
          current is FetchHomeProductsErrorState,
      builder: (context, state) {
        final cubit = ClintCubit.get(context);
        final isPersonalCustomer =
            AuthService.instance.isPersonalCustomerAccount;
        final isCompanyCustomer =
            AuthService.instance.isCompanyCustomerAccount;
        final hideRetailService = isCompanyCustomer ||
            (AuthService.instance.isSupplierAccount &&
                !AuthService.instance.isUaePhoneNumber);
        final displayProducts = cubit.homeProducts;

        // Service sections under banners (hide Retail for overseas suppliers
        // and Retail/Requests for company-customer accounts).
        final servicesIcons = [
          if (!isCompanyCustomer)
            (
              iconPath: AppAssets.servicesIcon,
              name: S.of(context).requests,
              screen: AppRoutes.kRequestsServiceView,
            ),
          (
            iconPath: AppAssets.servicesIcon2,
            name: S.of(context).offers,
            screen: AppRoutes.kOffersServiceView,
          ),
          (
            iconPath: AppAssets.servicesIcon3,
            name: S.of(context).booking,
            screen: AppRoutes.kBookingServiceView,
          ),
          if (!hideRetailService)
            (
              iconPath: AppAssets.servicesIcon4,
              name: S.of(context).retail,
              screen: AppRoutes.kRetailServiceView,
            ),
          (
            iconPath: AppAssets.servicesIcon5,
            name: S.of(context).shippingPrice,
            screen: AppRoutes.kShippingPriceServiceView,
          ),
        ];

        return Scaffold(
          backgroundColor: AppColors.scaffold(context),
          body: Column(
            children: [
              SearchHeader(isBackButton: false),
              Expanded(
                child: NotificationListener<ScrollNotification>(
                  onNotification: (notification) {
                    if (notification is! ScrollUpdateNotification &&
                        notification is! ScrollEndNotification) {
                      return false;
                    }
                    final metrics = notification.metrics;
                    if (!metrics.hasPixels || !metrics.hasContentDimensions) {
                      return false;
                    }
                    final itemWidth =
                        (MediaQuery.sizeOf(context).width - 48.w - 12.w) / 2;
                    final itemHeight = itemWidth / (157 / 282);
                    final preloadExtent = 5 * (itemHeight + 12.h);
                    if (metrics.maxScrollExtent - metrics.pixels <=
                        preloadExtent) {
                      cubit.loadMoreHomeFeed(isPerson: isPersonalCustomer);
                    }
                    return false;
                  },
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        if (cubit.isLoadingHomeBanners)
                          const BannerSliderShimmer()
                        else if (cubit.homeBannersError != null ||
                            cubit.homeBanners.isEmpty)
                          BannerSlider(banners: _localFallbackBanners)
                        else
                          BannerSlider(banners: cubit.homeBanners),
                        Padding(
                          padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 8.h),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Guests browse like company home (services + categories).
                              // Protected tabs (ads, orders, account) show a login dialog.
                              if (!isPersonalCustomer) ...[
                                IntrinsicHeight(
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      for (
                                        var i = 0;
                                        i < servicesIcons.length;
                                        i++
                                      ) ...[
                                        if (i > 0) SizedBox(width: 8.w),
                                        Expanded(
                                          child: _ServiceIconItem(
                                            iconPath: servicesIcons[i].iconPath,
                                            name: servicesIcons[i].name,
                                            onTap: () => context.push(
                                              servicesIcons[i].screen,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                SizedBox(height: 20.h),
                              ],
                              if (isPersonalCustomer) SizedBox(height: 2.h),
                              if (!isPersonalCustomer) ...[
                                _HomeSectionHeader(
                                  title: S.of(context).categories,
                                  onViewAll: () =>
                                      context.push(AppRoutes.kCategoriesView),
                                ),
                                SizedBox(height: 12.h),
                                const _CategoriesStrip(),
                              ],
                            ],
                          ),
                        ),
                        BlocBuilder<ClintCubit, ClintStates>(
                          buildWhen: (previous, current) =>
                              current is FetchHomeProductsLoadingState ||
                              current is FetchHomeProductsLoadingMoreState ||
                              current is FetchHomeProductsSuccessState ||
                              current is FetchHomeProductsErrorState,
                          builder: (context, state) {
                            final homeCubit = context.read<ClintCubit>();
                            final products = displayProducts;
                            final isLoading = homeCubit.isLoadingHomeProducts;
                            final isLoadingMore =
                                homeCubit.isLoadingMoreHomeProducts;
                            final error = homeCubit.homeProductsError;

                            return Padding(
                              padding: EdgeInsets.symmetric(horizontal: 16.w),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (isPersonalCustomer) ...[
                                    _HomeSectionHeader(
                                      title: S.of(context).retail,
                                    ),
                                    SizedBox(height: 12.h),
                                  ],
                                  if (isLoading && products.isEmpty)
                                    const _HomeProductsGridShimmer()
                                  else if (error != null && products.isEmpty)
                                    _HomeProductsSectionError(
                                      message: error,
                                      onRetry: () => homeCubit.refreshHomeFeed(
                                        isPerson: isPersonalCustomer,
                                        resetCached: true,
                                      ),
                                    )
                                  else if (products.isEmpty)
                                    Padding(
                                      padding: EdgeInsets.symmetric(
                                        vertical: 8.h,
                                      ),
                                      child: Text(
                                        S.of(context).noSearchResults,
                                        style: TextStyle(
                                          fontSize: 13.sp,
                                          color: const Color(0xFF6B7280),
                                        ),
                                      ),
                                    )
                                  else ...[
                                    GridView.builder(
                                      shrinkWrap: true,
                                      physics:
                                          const NeverScrollableScrollPhysics(),
                                      gridDelegate:
                                          ProductGridLayout.delegate(
                                        context,
                                        horizontalPadding:
                                            ProductGridLayout
                                                .homeHorizontalPadding(
                                          context,
                                        ),
                                        crossAxisSpacing: 12.w,
                                        mainAxisSpacing: 12.h,
                                      ),
                                      itemCount: products.length,
                                      itemBuilder: (context, index) {
                                        final product = products[index];
                                        return ProductCard(
                                          title: product.productName.isEmpty
                                              ? S.of(context).premiumSaffron
                                              : product.productName,
                                          product: product,
                                          preferRetailChannel:
                                              isPersonalCustomer,
                                        );
                                      },
                                    ),
                                    if (isLoadingMore)
                                      Padding(
                                        padding: EdgeInsets.symmetric(
                                          vertical: 16.h,
                                        ),
                                        child: const Center(
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2.5,
                                            color: Color(0xFF3A7DC5),
                                          ),
                                        ),
                                      ),
                                  ],
                                ],
                              ),
                            );
                          },
                        ),
                        SizedBox(height: 50.h),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _HomeProductsGridShimmer extends StatelessWidget {
  const _HomeProductsGridShimmer();

  @override
  Widget build(BuildContext context) {
    const count = 4;
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: ProductGridLayout.delegate(
        context,
        horizontalPadding: ProductGridLayout.homeHorizontalPadding(context),
        crossAxisSpacing: 12.w,
        mainAxisSpacing: 12.h,
      ),
      itemCount: count,
      itemBuilder: (context, index) {
        return Container(
          decoration: BoxDecoration(
            color: const Color(0xFFE5E7EB),
            borderRadius: BorderRadius.circular(12.r),
          ),
        );
      },
    );
  }
}

class _HomeProductsSectionError extends StatelessWidget {
  const _HomeProductsSectionError({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.h),
      child: Column(
        children: [
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12.sp, color: const Color(0xFF6B7280)),
          ),
          TextButton(onPressed: onRetry, child: Text(S.of(context).retry)),
        ],
      ),
    );
  }
}

/// Home strip order (API [nameEn] values).
const _homeCategoryStripNamesEn = [
  'Nuts',
  'Pulses',
  'Herbs',
  'Spices',
  'Canned',
  'Rice',
  'Milk',
  'Coffee',
];

class _CategoriesStrip extends StatelessWidget {
  const _CategoriesStrip();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ClintCubit, ClintStates>(
      buildWhen: (previous, current) =>
          current is FetchCategoriesLoadingState ||
          current is FetchCategoriesSuccessState ||
          current is FetchCategoriesErrorState,
      builder: (context, state) {
        final cubit = context.read<ClintCubit>();
        final categories = cubit.categories;

        if (categories.isEmpty) {
          if (cubit.isLoadingCategories) {
            return const _CategoriesStripShimmer();
          }
          if (cubit.categoriesError != null) {
            return _CategoriesStripError(
              message: cubit.categoriesError!,
              onRetry: () => cubit.fetchCategories(force: true),
            );
          }
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) {
              cubit.fetchCategories(force: true);
            }
          });
          return const _CategoriesStripShimmer();
        }

        final row1 = _homeCategoryStripNamesEn.sublist(0, 4);
        final row2 = _homeCategoryStripNamesEn.sublist(4);

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _categoryRow(context, cubit, row1),
            SizedBox(height: 10.h),
            _categoryRow(context, cubit, row2),
          ],
        );
      },
    );
  }

  Widget _categoryRow(
    BuildContext context,
    ClintCubit cubit,
    List<String> namesEn,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < namesEn.length; i++) ...[
          if (i > 0) SizedBox(width: 8.w),
          Expanded(
            child: _CategoryCard(
              category: cubit.categoryByNameEn(namesEn[i]),
              fallbackLabel: localizedCategoryName(context, namesEn[i]),
            ),
          ),
        ],
      ],
    );
  }
}

class _CategoriesStripShimmer extends StatelessWidget {
  const _CategoriesStripShimmer();

  @override
  Widget build(BuildContext context) {
    Widget cell() => Container(
      decoration: BoxDecoration(
        color: const Color(0xFFE5E7EB),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Column(
        children: [
          AspectRatio(
            aspectRatio: 1,
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFD1D5DB),
                borderRadius: BorderRadius.vertical(top: Radius.circular(12.r)),
              ),
            ),
          ),
          SizedBox(height: 28.h),
        ],
      ),
    );

    Widget row() => Row(
      children: [
        for (var i = 0; i < 4; i++) ...[
          if (i > 0) SizedBox(width: 8.w),
          Expanded(child: cell()),
        ],
      ],
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        row(),
        SizedBox(height: 10.h),
        row(),
      ],
    );
  }
}

class _CategoriesStripError extends StatelessWidget {
  const _CategoriesStripError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 12.h),
      child: Column(
        children: [
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12.sp, color: const Color(0xFF6B7280)),
          ),
          TextButton(onPressed: onRetry, child: Text(S.of(context).retry)),
        ],
      ),
    );
  }
}

class _HomeSectionHeader extends StatelessWidget {
  const _HomeSectionHeader({required this.title, this.onViewAll});

  final String title;
  final VoidCallback? onViewAll;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w700,
              color: AppColors.title(context),
            ),
          ),
        ),
        if (onViewAll != null)
          InkWell(
            onTap: onViewAll,
            borderRadius: BorderRadius.circular(8.r),
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 4.h, horizontal: 2.w),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    S.of(context).viewAll,
                    style: TextStyle(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w500,
                      color: LightColor.defaultColor,
                    ),
                  ),
                  SizedBox(width: 2.w),
                  Icon(
                    Directionality.of(context) == TextDirection.rtl
                        ? Icons.chevron_left
                        : Icons.chevron_right,
                    size: 18.sp,
                    color: LightColor.defaultColor,
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({required this.category, required this.fallbackLabel});

  final CategoryModel? category;
  final String fallbackLabel;

  @override
  Widget build(BuildContext context) {
    final categoryId = category?.categoryId;
    final label = category == null
        ? fallbackLabel
        : category!.displayName(context);

    return GestureDetector(
      onTap: categoryId == null
          ? null
          : () => context.push(
              '${AppRoutes.kCategoryProductsView}'
              '?categoryId=$categoryId'
              '&title=${Uri.encodeComponent(label)}',
            ),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.card(context),
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: AppColors.border(context)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.07),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AspectRatio(
              aspectRatio: 1,
              child: CategoryImage(
                imageUrl: category?.imageUrl,
                fit: BoxFit.cover,
                borderRadius: BorderRadius.vertical(top: Radius.circular(12.r)),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(4.w, 8.h, 4.w, 10.h),
              child: CategoryLabel(
                label: label,
                maxLines: 1,
                baseFontSize: 12.sp,
                fontWeight: FontWeight.w600,
                color: AppColors.title(context),
                maxHeight: 18.h,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ServiceIconItem extends StatelessWidget {
  const _ServiceIconItem({
    required this.iconPath,
    required this.name,
    required this.onTap,
  });

  final String iconPath;
  final String name;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12.r),
        child: Ink(
          decoration: BoxDecoration(
            color: AppColors.card(context),
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: AppColors.border(context)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.fromLTRB(4.w, 10.h, 4.w, 8.h),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 28.w,
                  height: 28.w,
                  child: SvgPicture.asset(
                    iconPath,
                    fit: BoxFit.contain,
                  ),
                ),
                SizedBox(height: 6.h),
                SizedBox(
                  height: 14.h,
                  child: Text(
                    name.replaceAll('\n', ' ').trim(),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 10.sp,
                      height: 1.2,
                      color: AppColors.title(context),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
