import 'package:alrasmarket/core/theme/app_fonts.dart';
import 'package:alrasmarket/features/clint/data/models/category_model.dart';
import 'package:alrasmarket/features/clint/presentation/widgets/category_image.dart';
import 'package:alrasmarket/features/company/presentation/widgets/create_ad/create_ad_design.dart';
import 'package:alrasmarket/generated/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class CreateAdCategorySelectionField extends StatelessWidget {
  const CreateAdCategorySelectionField({
    super.key,
    required this.categories,
    required this.isLoading,
    required this.selectedCategoryId,
    required this.onCategoryChanged,
  });

  final List<CategoryModel> categories;
  final bool isLoading;
  final int? selectedCategoryId;
  final void Function(int categoryId, String label) onCategoryChanged;

  @override
  Widget build(BuildContext context) {
    final fontFamily = AppFonts.familyFor(Localizations.localeOf(context));
    final fieldTextStyle = TextStyle(
      color: CreateAdDesign.text,
      fontFamily: fontFamily,
      fontSize: 13.sp,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          S.of(context).category,
          style: TextStyle(
            color: CreateAdDesign.text,
            fontFamily: fontFamily,
            fontSize: 12.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 6.h),
        DropdownButtonFormField<int>(
          value: categories.any((c) => c.categoryId == selectedCategoryId)
              ? selectedCategoryId
              : null,
          hint: Text(
            isLoading ? '...' : S.of(context).selectCategory,
            style: fieldTextStyle,
          ),
          icon: Icon(
            Icons.keyboard_arrow_down_rounded,
            color: const Color(0xFF6B7280),
            size: 20.sp,
          ),
          dropdownColor: CreateAdDesign.cardBg,
          style: fieldTextStyle,
          isDense: true,
          menuMaxHeight: 320.h,
          decoration: InputDecoration(
            filled: true,
            fillColor: CreateAdDesign.cardBg,
            isDense: true,
            contentPadding: EdgeInsets.symmetric(
              horizontal: 12.w,
              vertical: 10.h,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10.r),
              borderSide: BorderSide(
                color: CreateAdDesign.border,
                width: 1.2,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10.r),
              borderSide: const BorderSide(
                color: Color(0xFF3A7DC5),
                width: 1.2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10.r),
              borderSide: BorderSide(color: Colors.red.shade400, width: 1.2),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10.r),
              borderSide: BorderSide(color: Colors.red.shade400, width: 1.2),
            ),
          ),
          items: categories
              .map(
                (category) => DropdownMenuItem<int>(
                  value: category.categoryId,
                  child: Row(
                    children: [
                      SizedBox(
                        width: 20.w,
                        height: 20.h,
                        child: CategoryImage(
                          imageUrl: category.imageUrl,
                          fit: BoxFit.cover,
                          borderRadius: BorderRadius.circular(4.r),
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Flexible(
                        child: Text(
                          category.displayName(context),
                          style: fieldTextStyle,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              )
              .toList(),
          selectedItemBuilder: (context) => categories
              .map(
                (category) => Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Text(
                    category.displayName(context),
                    style: fieldTextStyle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              )
              .toList(),
          validator: (value) {
            if (value == null) {
              return S.of(context).thisFieldIsRequired;
            }
            return null;
          },
          onChanged: isLoading || categories.isEmpty
              ? null
              : (value) {
                  if (value == null) return;
                  final category = categories.firstWhere(
                    (item) => item.categoryId == value,
                  );
                  // Keep English label for API matching; UI uses displayName.
                  onCategoryChanged(
                    category.categoryId,
                    category.nameEn.trim().isNotEmpty
                        ? category.nameEn.trim()
                        : category.displayName(context),
                  );
                },
        ),
      ],
    );
  }
}
