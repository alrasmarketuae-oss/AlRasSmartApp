import 'package:alrasmarket/core/theme/app_fonts.dart';
import 'package:alrasmarket/core/theme/colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class MyAdsFilterChipItem {
  const MyAdsFilterChipItem({
    required this.label,
    required this.icon,
    this.accentColor,
  });

  final String label;
  final IconData icon;
  /// When set, unselected chip uses this accent; selected fills with it.
  final Color? accentColor;
}

/// Pill chips used on Offers service (and similar): selected = solid brand blue.
class MyAdsFilterChips extends StatelessWidget {
  const MyAdsFilterChips({
    super.key,
    required this.items,
    required this.selectedIndex,
    required this.onSelected,
  });

  final List<MyAdsFilterChipItem> items;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  static const _selectedBg = LightColor.defaultColor;
  static const _unselectedBg = Color(0xFFFFFFFF);
  static const _unselectedBorder = Color(0xFFE2E8F0);
  static const _unselectedText = LightColor.defaultColor;
  static const _unselectedIcon = LightColor.defaultColor;

  @override
  Widget build(BuildContext context) {
    final fontFamily = AppFonts.familyFor(Localizations.localeOf(context));

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 4.h),
      child: Row(
        children: List.generate(items.length, (index) {
          final item = items[index];
          final isSelected = index == selectedIndex;

          return Padding(
            padding: EdgeInsets.only(
              right: index != items.length - 1 ? 8.w : 0,
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => onSelected(index),
                borderRadius: BorderRadius.circular(24.r),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOutCubic,
                  padding: EdgeInsets.symmetric(
                    horizontal: 14.w,
                    vertical: 9.h,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24.r),
                    color: isSelected ? _selectedBg : _unselectedBg,
                    border: Border.all(
                      color: isSelected ? _selectedBg : _unselectedBorder,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        item.icon,
                        size: 16.sp,
                        color: isSelected ? Colors.white : _unselectedIcon,
                      ),
                      SizedBox(width: 6.w),
                      Text(
                        item.label,
                        style: TextStyle(
                          fontFamily: fontFamily,
                          fontSize: 12.5.sp,
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.w500,
                          color: isSelected ? Colors.white : _unselectedText,
                          height: 1.2,
                        ),
                      ),
                    ],
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

/// Account type filters: equal-width icon cards (no horizontal scroll).
class MyAdsTypeFilterCards extends StatelessWidget {
  const MyAdsTypeFilterCards({
    super.key,
    required this.items,
    required this.selectedIndex,
    required this.onSelected,
  });

  final List<MyAdsFilterChipItem> items;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  static const _brand = LightColor.defaultColor;
  static const _selectedBg = Color(0xFFE8F2FC);
  static const _unselectedIcon = Color(0xFF94A3B8);
  static const _unselectedText = Color(0xFF64748B);

  @override
  Widget build(BuildContext context) {
    final fontFamily = AppFonts.familyFor(Localizations.localeOf(context));
    final gap = 4.w;

    return Padding(
      padding: EdgeInsets.fromLTRB(12.w, 8.h, 12.w, 4.h),
      child: Row(
        children: List.generate(items.length, (index) {
          final item = items[index];
          final isSelected = index == selectedIndex;

          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                right: index != items.length - 1 ? gap : 0,
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => onSelected(index),
                  borderRadius: BorderRadius.circular(10.r),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: EdgeInsets.symmetric(
                      vertical: 8.h,
                      horizontal: 2.w,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected ? _selectedBg : Colors.white,
                      borderRadius: BorderRadius.circular(10.r),
                      border: Border.all(
                        color: isSelected ? _brand : const Color(0xFFE8EDF2),
                        width: isSelected ? 1.4 : 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          item.icon,
                          size: 16.sp,
                          color: isSelected ? _brand : _unselectedIcon,
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          item.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: fontFamily,
                            fontSize: 9.sp,
                            fontWeight:
                                isSelected ? FontWeight.w700 : FontWeight.w500,
                            color: isSelected ? _brand : _unselectedText,
                            height: 1.05,
                          ),
                        ),
                      ],
                    ),
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

/// Account status filters: equal-width compact pills (no horizontal scroll).
class MyAdsStatusFilterChips extends StatelessWidget {
  const MyAdsStatusFilterChips({
    super.key,
    required this.items,
    required this.selectedIndex,
    required this.onSelected,
  });

  final List<MyAdsFilterChipItem> items;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  static const _brand = LightColor.defaultColor;

  @override
  Widget build(BuildContext context) {
    final fontFamily = AppFonts.familyFor(Localizations.localeOf(context));
    final gap = 3.w;

    return Padding(
      padding: EdgeInsets.fromLTRB(12.w, 2.h, 12.w, 8.h),
      child: Row(
        children: List.generate(items.length, (index) {
          final item = items[index];
          final isSelected = index == selectedIndex;
          final accent = item.accentColor ?? _brand;
          final bg = isSelected ? accent : Colors.white;
          final fg = isSelected ? Colors.white : accent;

          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                right: index != items.length - 1 ? gap : 0,
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => onSelected(index),
                  borderRadius: BorderRadius.circular(18.r),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: EdgeInsets.symmetric(
                      horizontal: 2.w,
                      vertical: 7.h,
                    ),
                    decoration: BoxDecoration(
                      color: bg,
                      borderRadius: BorderRadius.circular(18.r),
                      border: Border.all(color: accent, width: 1.2),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(item.icon, size: 13.sp, color: fg),
                        SizedBox(height: 2.h),
                        Text(
                          item.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: fontFamily,
                            fontSize: 8.5.sp,
                            fontWeight:
                                isSelected ? FontWeight.w700 : FontWeight.w500,
                            color: fg,
                            height: 1.05,
                          ),
                        ),
                      ],
                    ),
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
