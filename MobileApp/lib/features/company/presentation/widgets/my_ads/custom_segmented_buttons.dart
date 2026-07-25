import 'package:alrasmarket/core/theme/app_fonts.dart';
import 'package:alrasmarket/core/theme/colors.dart';
import 'package:alrasmarket/features/company/presentation/models/my_ads_filter.dart';
import 'package:alrasmarket/generated/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class CustomSegmentedButtons extends StatelessWidget {
  const CustomSegmentedButtons({
    super.key,
    required this.selectedIndex,
    required this.onSelected,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final fontFamily = AppFonts.familyFor(Localizations.localeOf(context));
    final s = S.of(context);
    final labels = MyAdsFilter.values.map((filter) => filter.label(s)).toList();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      child: Row(
        children: List.generate(labels.length, (index) {
          final isSelected = index == selectedIndex;

          return GestureDetector(
            onTap: () => onSelected(index),
            child: Container(
              margin: EdgeInsets.only(
                right: index != labels.length - 1 ? 8.w : 0,
              ),
              padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8.r),
                color: isSelected
                    ? LightColor.defaultColor
                    : Colors.transparent,
                border: isSelected
                    ? null
                    : Border.all(color: LightColor.defaultColor, width: 2),
              ),
              child: Center(
                child: Text(
                  labels[index],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isSelected ? Colors.white : LightColor.defaultColor,
                    fontFamily: fontFamily,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w400,
                    height: 1.5,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
