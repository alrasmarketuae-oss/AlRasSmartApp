import 'package:alrasmarket/core/theme/colors.dart';
import 'package:alrasmarket/core/router/app_router.dart';
import 'package:alrasmarket/features/clint/data/models/category_model.dart';
import 'package:alrasmarket/features/clint/presentation/widgets/category_label.dart';
import 'package:alrasmarket/features/clint/presentation/widgets/category_image.dart';
import 'package:alrasmarket/features/clint/presentation/widgets/search_header.dart';
import 'package:alrasmarket/generated/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../controller/cubit/clint_cubit.dart';
import '../controller/cubit/clint_states.dart';

class CategoriesView extends StatefulWidget {
  const CategoriesView({super.key});

  @override
  State<CategoriesView> createState() => _CategoriesViewState();
}

class _CategoriesViewState extends State<CategoriesView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ClintCubit>().fetchCategories(force: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ClintCubit, ClintStates>(
      builder: (context, state) {
        final cubit = context.read<ClintCubit>();
        final categories = cubit.categories;
        final isLoading = cubit.isLoadingCategories && categories.isEmpty;
        final error = cubit.categoriesError;

        return SafeArea(
          child: Scaffold(
            backgroundColor: AppColors.scaffold(context),
            body: Column(
              children: [
                SearchHeader(title: S.of(context).categories),
                SizedBox(height: 12.h),
                Expanded(
                  child: isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : error != null && categories.isEmpty
                          ? _CategoriesError(
                              message: error,
                              onRetry: () => cubit.fetchCategories(force: true),
                            )
                          : RefreshIndicator(
                              onRefresh: () => cubit.fetchCategories(force: true),
                              child: categories.isEmpty
                                  ? ListView(
                                      physics: const AlwaysScrollableScrollPhysics(),
                                      children: [
                                        SizedBox(height: 120.h),
                                        Center(
                                          child: Text(
                                            S.of(context).categories,
                                            style: TextStyle(fontSize: 14.sp),
                                          ),
                                        ),
                                      ],
                                    )
                                  : GridView.builder(
                                      padding: EdgeInsets.fromLTRB(
                                        24.w,
                                        4.h,
                                        24.w,
                                        4.h + kBottomNavigationBarHeight,
                                      ),
                                      physics:
                                          const AlwaysScrollableScrollPhysics(),
                                      gridDelegate:
                                          SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: 3,
                                        mainAxisSpacing: 16.h,
                                        crossAxisSpacing: 12.w,
                                        // Image tile + gap + 2-line label (legacy layout).
                                        childAspectRatio:
                                            101 / (141.33 + 12 + 36),
                                      ),
                                      itemCount: categories.length,
                                      itemBuilder: (context, index) {
                                        final category = categories[index];
                                        final label =
                                            category.displayName(context);
                                        return _CategoryGridItem(
                                          category: category,
                                          label: label,
                                          onTap: () => context.push(
                                            '${AppRoutes.kCategoryProductsView}'
                                            '?categoryId=${category.categoryId}'
                                            '&title=${Uri.encodeComponent(label)}',
                                          ),
                                        );
                                      },
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

class _CategoriesError extends StatelessWidget {
  const _CategoriesError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 24.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, textAlign: TextAlign.center, style: TextStyle(fontSize: 14.sp)),
            SizedBox(height: 12.h),
            TextButton(onPressed: onRetry, child: Text(S.of(context).retry)),
          ],
        ),
      ),
    );
  }
}

class _CategoryGridItem extends StatelessWidget {
  const _CategoryGridItem({
    required this.category,
    required this.label,
    required this.onTap,
  });

  final CategoryModel category;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.card(context),
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(color: AppColors.border(context)),
              ),
              clipBehavior: Clip.antiAlias,
              child: CategoryImage(
                imageUrl: category.imageUrl,
                fit: BoxFit.cover,
                borderRadius: BorderRadius.circular(8.r),
              ),
            ),
          ),
          SizedBox(height: 12.h),
          CategoryLabel(
            label: label,
            maxLines: 2,
            baseFontSize: 14.sp,
            fontWeight: FontWeight.w400,
            color: AppColors.title(context),
          ),
        ],
      ),
    );
  }
}
