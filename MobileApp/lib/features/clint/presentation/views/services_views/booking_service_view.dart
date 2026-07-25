import 'package:alrasmarket/features/clint/presentation/controller/cubit/clint_cubit.dart';
import 'package:alrasmarket/features/clint/presentation/controller/cubit/clint_states.dart';
import 'package:alrasmarket/features/clint/presentation/models/service_product_type.dart';
import 'package:alrasmarket/features/clint/presentation/widgets/search_header.dart';
import 'package:alrasmarket/features/clint/presentation/widgets/service_products_grid.dart';
import 'package:alrasmarket/generated/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class BookingServiceView extends StatefulWidget {
  const BookingServiceView({super.key});

  @override
  State<BookingServiceView> createState() => _BookingServiceViewState();
}

class _BookingServiceViewState extends State<BookingServiceView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final cubit = context.read<ClintCubit>();
      cubit.clearBookingYourOffer();
      cubit.fetchProductsByType(ServiceProductType.booking);
    });
  }

  Future<void> _refresh() {
    return context
        .read<ClintCubit>()
        .fetchProductsByType(ServiceProductType.booking, forceRefresh: true);
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ClintCubit, ClintStates>(
      buildWhen: (previous, current) =>
          current is FetchProductsByTypeLoadingState &&
              current.productType == ServiceProductType.booking ||
          current is FetchProductsByTypeSuccessState &&
              current.productType == ServiceProductType.booking ||
          current is FetchProductsByTypeErrorState &&
              current.productType == ServiceProductType.booking ||
          current is ClintTabState,
      builder: (context, state) {
        final cubit = ClintCubit.get(context);
        final bookingProducts = cubit.bookingProducts;

        return SafeArea(
          child: Scaffold(
            body: Column(
              children: [
                SearchHeader(title: S.of(context).booking),
                SizedBox(height: 12.h),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _refresh,
                    child: cubit.isLoadingBookingProducts &&
                            bookingProducts.isEmpty
                        ? ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            children: [
                              SizedBox(height: 120.h),
                              const Center(
                                child: CircularProgressIndicator(),
                              ),
                            ],
                          )
                        : bookingProducts.isEmpty
                            ? ListView(
                                physics: const AlwaysScrollableScrollPhysics(),
                                children: [
                                  SizedBox(height: 120.h),
                                  Center(
                                    child: Text(
                                      'No Booking Products Available',
                                      style: TextStyle(fontSize: 16.sp),
                                    ),
                                  ),
                                ],
                              )
                            : ServiceProductsGrid(products: bookingProducts),
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
