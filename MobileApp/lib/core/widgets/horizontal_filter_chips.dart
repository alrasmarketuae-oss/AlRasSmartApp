import 'package:alrasmarket/core/theme/app_fonts.dart';
import 'package:alrasmarket/core/theme/colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class HorizontalFilterChips extends StatelessWidget {
  const HorizontalFilterChips({
    super.key,
    required this.labels,
    required this.selectedIndex,
    required this.onSelected,
    this.compact = false,
  });

  final List<String> labels;
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final fontFamily = AppFonts.familyFor(Localizations.localeOf(context));

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
              padding: EdgeInsets.symmetric(
                horizontal: compact ? 14.w : 20.w,
                vertical: compact ? 10.h : 14.h,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8.r),
                color: isSelected
                    ? LightColor.defaultColor
                    : Colors.transparent,
                border: isSelected
                    ? null
                    : Border.all(color: LightColor.defaultColor, width: 1.5),
              ),
              child: Text(
                labels[index],
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isSelected ? Colors.white : LightColor.defaultColor,
                  fontFamily: fontFamily,
                  fontSize: compact ? 12.sp : 14.sp,
                  fontWeight: FontWeight.w500,
                  height: 1.3,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
