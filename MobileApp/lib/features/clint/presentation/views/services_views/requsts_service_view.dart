import 'package:alrasmarket/features/clint/presentation/controller/cubit/clint_cubit.dart';
import 'package:alrasmarket/features/clint/presentation/controller/cubit/clint_states.dart';
import 'package:alrasmarket/features/clint/presentation/models/service_product_type.dart';
import 'package:alrasmarket/features/clint/presentation/widgets/search_header.dart';
import 'package:alrasmarket/features/clint/presentation/widgets/service_products_grid.dart';
import 'package:alrasmarket/generated/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class RequestsServiceView extends StatefulWidget {
  const RequestsServiceView({super.key});

  @override
  State<RequestsServiceView> createState() => _RequestsServiceViewState();
}

class _RequestsServiceViewState extends State<RequestsServiceView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context
            .read<ClintCubit>()
            .fetchProductsByType(ServiceProductType.requests);
      }
    });
  }

  Future<void> _refresh() {
    return context
        .read<ClintCubit>()
        .fetchProductsByType(ServiceProductType.requests, forceRefresh: true);
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ClintCubit, ClintStates>(
      buildWhen: (previous, current) =>
          current is FetchProductsByTypeLoadingState &&
              current.productType == ServiceProductType.requests ||
          current is FetchProductsByTypeSuccessState &&
              current.productType == ServiceProductType.requests ||
          current is FetchProductsByTypeErrorState &&
              current.productType == ServiceProductType.requests ||
          current is ClintTabState,
      builder: (context, state) {
        final cubit = ClintCubit.get(context);
        final requestProducts = cubit.requestsProducts;

        return SafeArea(
          child: Scaffold(
            body: Column(
              children: [
                SearchHeader(title: S.of(context).requests),
                SizedBox(height: 12.h),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _refresh,
                    child: cubit.isLoadingRequestsProducts &&
                            requestProducts.isEmpty
                        ? ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            children: [
                              SizedBox(height: 120.h),
                              const Center(
                                child: CircularProgressIndicator(),
                              ),
                            ],
                          )
                        : requestProducts.isEmpty
                            ? ListView(
                                physics: const AlwaysScrollableScrollPhysics(),
                                children: [
                                  SizedBox(height: 120.h),
                                  Center(
                                    child: Text(
                                      'No Requests Available Currently',
                                      style: TextStyle(fontSize: 16.sp),
                                    ),
                                  ),
                                ],
                              )
                            : ServiceProductsGrid(products: requestProducts),
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
