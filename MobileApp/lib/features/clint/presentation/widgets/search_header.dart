import 'package:alrasmarket/core/router/app_router.dart';
import 'package:alrasmarket/core/serveses/auth_service.dart';
import 'package:alrasmarket/core/theme/colors.dart';
import 'package:alrasmarket/core/widgets/app_header.dart';
import 'package:alrasmarket/core/widgets/app_search_field.dart';
import 'package:alrasmarket/features/clint/presentation/controller/cubit/clint_cubit.dart';
import 'package:alrasmarket/features/company/presentation/controller/cubit/company_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

class SearchHeader extends StatelessWidget {
  const SearchHeader({
    super.key,
    this.title,
    this.isBackButton = true,
    this.isSearch = true,
    this.initialQuery,
    this.searchController,
    this.onSearchSubmitted,
    this.onImageSearchTap,
    this.onFilterTap,
    this.searchMode = AppSearchMode.catalog,
    this.searchHint,
    this.onLocalSearchChanged,
    this.showImageSearch = true,
  });

  final String? title;
  final bool isBackButton;
  final bool isSearch;
  final String? initialQuery;
  final TextEditingController? searchController;
  final ValueChanged<String>? onSearchSubmitted;
  final VoidCallback? onImageSearchTap;
  final VoidCallback? onFilterTap;
  final AppSearchMode searchMode;
  final String? searchHint;
  final ValueChanged<String>? onLocalSearchChanged;
  final bool showImageSearch;

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.paddingOf(context).top;
    final topPad = topInset > 0 ? topInset + 8.h : 12.h;

    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, topPad, 16.w, 0),
      child: Column(
        children: [
          Row(
            children: [
              if (isBackButton) ...[
                IconButton(
                  onPressed: () => _goBack(context),
                  padding: EdgeInsets.zero,
                  constraints: BoxConstraints.tightFor(width: 40.w, height: 40.w),
                  tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                  icon: Icon(
                    Icons.arrow_back_ios_new_rounded,
                    size: 18.sp,
                    color: LightColor.defaultColor,
                  ),
                ),
                SizedBox(width: 4.w),
              ],
              const Expanded(child: AppHeader()),
            ],
          ),
          if (isSearch) SizedBox(height: 16.h),
          if (isSearch)
            AppSearchField(
              mode: searchMode,
              initialQuery: initialQuery,
              controller: searchController,
              hintText: searchHint,
              onSubmitted: onSearchSubmitted,
              onChanged: onLocalSearchChanged,
              onImageSearchTap: onImageSearchTap,
              onFilterTap: onFilterTap,
              showBackButton: false,
              showImageSearch: showImageSearch,
            ),
          SizedBox(height: 16.h),
          if (title != null)
            Center(
              child: Text(
                title!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18.sp,
                  color: LightColor.defaultColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          if (title != null) SizedBox(height: 8.h),
        ],
      ),
    );
  }

  static void goBack(BuildContext context) {
    if (context.canPop()) {
      context.pop();
      return;
    }
    if (AuthService.instance.isAdminAccount) {
      context.go('${AppRoutes.kAdminHomeView}?tab=1');
      return;
    }
    try {
      context.read<ClintCubit>().setTab(0);
    } catch (_) {}
    try {
      context.read<CompanyCubit>().setTab(0);
    } catch (_) {}
  }

  static void _goBack(BuildContext context) => goBack(context);
}
