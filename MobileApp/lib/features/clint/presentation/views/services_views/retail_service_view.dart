import 'package:alrasmarket/features/clint/presentation/controller/cubit/clint_cubit.dart';
import 'package:alrasmarket/features/clint/presentation/controller/cubit/clint_states.dart';
import 'package:alrasmarket/features/clint/presentation/models/service_product_type.dart';
import 'package:alrasmarket/features/clint/presentation/widgets/product_grid_skeleton.dart';
import 'package:alrasmarket/features/clint/presentation/widgets/search_header.dart';
import 'package:alrasmarket/features/clint/presentation/widgets/service_products_grid.dart';
import 'package:alrasmarket/generated/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class RetailServiceView extends StatefulWidget {
  const RetailServiceView({super.key});

  @override
  State<RetailServiceView> createState() => _RetailServiceViewState();
}

class _RetailServiceViewState extends State<RetailServiceView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context
            .read<ClintCubit>()
            .fetchProductsByType(ServiceProductType.retail);
      }
    });
  }

  Future<void> _refresh() {
    return context
        .read<ClintCubit>()
        .fetchProductsByType(ServiceProductType.retail, forceRefresh: true);
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ClintCubit, ClintStates>(
      buildWhen: (previous, current) =>
          current is FetchProductsByTypeLoadingState &&
              current.productType == ServiceProductType.retail ||
          current is FetchProductsByTypeSuccessState &&
              current.productType == ServiceProductType.retail ||
          current is FetchProductsByTypeErrorState &&
              current.productType == ServiceProductType.retail ||
          current is ClintTabState,
      builder: (context, state) {
        final cubit = ClintCubit.get(context);
        final retailProducts = cubit.retailProducts;

        return SafeArea(
          child: Scaffold(
            body: Column(
              children: [
                SearchHeader(title: S.of(context).retail),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _refresh,
                    child: cubit.isLoadingRetailProducts && retailProducts.isEmpty
                        ? const ProductGridSkeleton()
                        : retailProducts.isEmpty
                            ? ListView(
                                physics: const AlwaysScrollableScrollPhysics(),
                                children: [
                                  SizedBox(height: 120.h),
                                  Center(
                                    child: Text(
                                      S.of(context).noProductsInCategory,
                                      style: TextStyle(fontSize: 16.sp),
                                    ),
                                  ),
                                ],
                              )
                            : ServiceProductsGrid(
                                products: retailProducts,
                                preferRetailChannel: true,
                              ),
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
