import 'package:alrasmarket/features/clint/presentation/controller/cubit/clint_cubit.dart';
import 'package:alrasmarket/features/clint/presentation/controller/cubit/clint_states.dart';
import 'package:alrasmarket/features/clint/presentation/models/service_product_type.dart';
import 'package:alrasmarket/features/clint/presentation/widgets/product_grid_skeleton.dart';
import 'package:alrasmarket/features/clint/presentation/widgets/search_header.dart';
import 'package:alrasmarket/features/clint/presentation/widgets/service_products_grid.dart';
import 'package:alrasmarket/features/company/data/models/my_listing_product_model.dart';
import 'package:alrasmarket/features/company/presentation/widgets/my_ads/my_ads_filter_chips.dart';
import 'package:alrasmarket/generated/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class OffersServiceView extends StatefulWidget {
  const OffersServiceView({super.key});

  @override
  State<OffersServiceView> createState() => _OffersServiceViewState();
}

class _OffersServiceViewState extends State<OffersServiceView> {
  _OfferSort _sort = _OfferSort.all;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<ClintCubit>().fetchProductsByType(ServiceProductType.offers);
      }
    });
  }

  Future<void> _refresh() {
    return context.read<ClintCubit>().fetchProductsByType(
      ServiceProductType.offers,
      forceRefresh: true,
    );
  }

  List<MyListingProductModel> _sorted(List<MyListingProductModel> items) {
    final copy = List<MyListingProductModel>.from(items);
    switch (_sort) {
      case _OfferSort.all:
        return copy;
      case _OfferSort.topDiscount:
        final discounted = copy
            .where((p) => p.isDiscountActive && p.discountPercentValue > 0)
            .toList();
        discounted.sort((a, b) {
          final byDiscount =
              b.discountPercentValue.compareTo(a.discountPercentValue);
          if (byDiscount != 0) return byDiscount;
          return a.productName.compareTo(b.productName);
        });
        return discounted;
      case _OfferSort.endingSoon:
        final endingSoon = copy.where(_isEndingWithinOneDay).toList();
        endingSoon.sort((a, b) {
          final aRemaining = a.discountRemaining ?? const Duration(days: 9999);
          final bRemaining = b.discountRemaining ?? const Duration(days: 9999);
          return aRemaining.compareTo(bRemaining);
        });
        return endingSoon;
    }
  }

  bool _isEndingWithinOneDay(MyListingProductModel product) {
    if (!product.isDiscountActive) return false;
    final remaining = product.discountRemaining;
    if (remaining == null) return false;
    return remaining > Duration.zero && remaining < const Duration(days: 1);
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final filterItems = [
      MyAdsFilterChipItem(
        label: s.allOffers,
        icon: Icons.local_offer_outlined,
      ),
      MyAdsFilterChipItem(
        label: s.topDiscount,
        icon: Icons.workspace_premium_outlined,
      ),
      MyAdsFilterChipItem(
        label: s.endingSoon,
        icon: Icons.access_time_rounded,
      ),
    ];

    return BlocBuilder<ClintCubit, ClintStates>(
      buildWhen: (previous, current) =>
          (current is FetchProductsByTypeLoadingState &&
              current.productType == ServiceProductType.offers) ||
          (current is FetchProductsByTypeSuccessState &&
              current.productType == ServiceProductType.offers) ||
          (current is FetchProductsByTypeErrorState &&
              current.productType == ServiceProductType.offers) ||
          current is ClintTabState,
      builder: (context, state) {
        final cubit = ClintCubit.get(context);
        final offerProducts = _sorted(cubit.offersProducts);

        return Scaffold(
          backgroundColor: Colors.white,
          body: Column(
            children: [
              SearchHeader(title: s.offers),
              MyAdsFilterChips(
                items: filterItems,
                selectedIndex: _sort.index,
                onSelected: (index) =>
                    setState(() => _sort = _OfferSort.values[index]),
              ),
              SizedBox(height: 4.h),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _refresh,
                  child: cubit.isLoadingOffersProducts && offerProducts.isEmpty
                      ? const ProductGridSkeleton(useOfferCard: true)
                      : offerProducts.isEmpty
                          ? ListView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              children: [
                                SizedBox(height: 120.h),
                                Center(
                                  child: Text(
                                    'No Offers Available Currently',
                                    style: TextStyle(fontSize: 16.sp),
                                  ),
                                ),
                              ],
                            )
                          : ServiceProductsGrid(
                              products: offerProducts,
                              useOfferCard: true,
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

enum _OfferSort { all, topDiscount, endingSoon }
