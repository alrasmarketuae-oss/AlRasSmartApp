import 'package:alrasmarket/core/theme/colors.dart';
import 'package:alrasmarket/core/utils/product_grid_layout.dart';
import 'package:alrasmarket/core/widgets/primary_button.dart';
import 'package:alrasmarket/features/clint/presentation/controller/cubit/clint_cubit.dart';
import 'package:alrasmarket/features/clint/presentation/controller/cubit/clint_states.dart';
import 'package:alrasmarket/features/clint/presentation/widgets/product%20_card.dart';
import 'package:alrasmarket/features/clint/presentation/widgets/search_header.dart';
import 'package:alrasmarket/generated/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class CategoryProductsView extends StatefulWidget {
  const CategoryProductsView({
    super.key,
    required this.categoryId,
    required this.categoryTitle,
  });

  final int categoryId;
  final String categoryTitle;

  @override
  State<CategoryProductsView> createState() => _CategoryProductsViewState();
}

class _CategoryProductsViewState extends State<CategoryProductsView> {
  @override
  void initState() {
    super.initState();
    context.read<ClintCubit>().fetchProductsByCategory(
          categoryId: widget.categoryId,
          forceRefresh: true,
        );
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return SafeArea(
      child: Scaffold(
        backgroundColor: AppColors.scaffold(context),
        body: Column(
          children: [
            SearchHeader(
              title: widget.categoryTitle,
              isSearch: false,
            ),
            Expanded(
              child: BlocBuilder<ClintCubit, ClintStates>(
                buildWhen: (previous, current) =>
                    current is FetchCategoryProductsLoadingState ||
                    current is FetchCategoryProductsSuccessState ||
                    current is FetchCategoryProductsErrorState,
                builder: (context, state) {
                  final cubit = context.read<ClintCubit>();
                  final isCurrentCategory =
                      cubit.activeCategoryId == widget.categoryId;

                  if (state is FetchCategoryProductsLoadingState &&
                      state.categoryId == widget.categoryId) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (state is FetchCategoryProductsErrorState &&
                      state.categoryId == widget.categoryId) {
                    return _MessageState(
                      message: state.message,
                      onRetry: () => cubit.fetchProductsByCategory(
                        categoryId: widget.categoryId,
                      ),
                    );
                  }

                  final products = isCurrentCategory
                      ? cubit.categoryProducts
                      : const [];

                  if (cubit.isLoadingCategoryProducts &&
                      products.isEmpty &&
                      isCurrentCategory) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (products.isEmpty) {
                    return _MessageState(
                      message: s.noProductsInCategory,
                      onRetry: () => cubit.fetchProductsByCategory(
                        categoryId: widget.categoryId,
                      ),
                    );
                  }

                  return GridView.builder(
                    padding: EdgeInsets.fromLTRB(24.w, 8.h, 24.w, 24.h),
                    gridDelegate: ProductGridLayout.delegate(
                      context,
                      horizontalPadding:
                          ProductGridLayout.categoryHorizontalPadding(context),
                      crossAxisSpacing: 16.w,
                      mainAxisSpacing: 16.h,
                    ),
                    itemCount: products.length,
                    itemBuilder: (context, index) {
                      final product = products[index];
                      return ProductCard(
                        title: product.productName.isEmpty
                            ? widget.categoryTitle
                            : product.productName,
                        product: product,
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageState extends StatelessWidget {
  const _MessageState({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 24.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15.sp, color: const Color(0xFF333333)),
            ),
            SizedBox(height: 16.h),
            PrimaryButton(
              text: s.retry,
              onPressed: onRetry,
              width: 180.w,
            ),
          ],
        ),
      ),
    );
  }
}
