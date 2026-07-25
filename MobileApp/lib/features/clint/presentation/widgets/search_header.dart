import 'package:alrasmarket/core/theme/colors.dart';
import 'package:alrasmarket/core/widgets/app_header.dart';
import 'package:alrasmarket/features/clint/presentation/widgets/search_form_feild.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

class SearchHeader extends StatelessWidget {
  final String? title;
  final bool isBackButton;
  final bool isSearch;
  final String? initialQuery;
  final TextEditingController? searchController;
  final ValueChanged<String>? onSearchSubmitted;
  final VoidCallback? onImageSearchTap;
  final VoidCallback? onFilterTap;

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
  });

  @override
  Widget build(BuildContext context) {
    final canPop = isBackButton && context.canPop();

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Column(
        children: [
          SizedBox(height: 20.h),
          Row(
            children: [
              if (canPop && !isSearch) ...[
                IconButton(
                  onPressed: () => context.pop(),
                  padding: EdgeInsets.zero,
                  constraints: BoxConstraints.tightFor(width: 40.w, height: 40.w),
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
            SearchFormFiled(
              initialQuery: initialQuery,
              controller: searchController,
              onSubmitted: onSearchSubmitted,
              onImageSearchTap: onImageSearchTap,
              onFilterTap: onFilterTap,
              showBackButton: isBackButton,
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
}
