import 'package:alrasmarket/core/theme/colors.dart';
import 'package:alrasmarket/core/utils/assets.dart';
import 'package:alrasmarket/generated/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';

class ShippingBottomNavBar extends StatelessWidget {
  const ShippingBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.context,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;
  final BuildContext context;

  @override
  Widget build(BuildContext context) {
    final navItems = [
      (
        selectedIcon: AppAssets.blueHomeIcon,
        icon: AppAssets.homeIcon,
        label: S.of(context).home,
      ),
      (
        selectedIcon: AppAssets.blueProfileIcon,
        icon: AppAssets.profileIcon,
        label: S.of(context).profile,
      ),
    ];

    return Container(
      decoration: BoxDecoration(
        color: LightColor.surface,
        boxShadow: [
          BoxShadow(
            color: LightColor.black.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 8.h),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(
              navItems.length,
              (index) => _ShippingNavItem(
                iconPath: currentIndex == index
                    ? navItems[index].selectedIcon
                    : navItems[index].icon,
                label: navItems[index].label,
                isSelected: currentIndex == index,
                onTap: () => onTap(index),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ShippingNavItem extends StatelessWidget {
  const _ShippingNavItem({
    required this.iconPath,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String iconPath;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color =
        isSelected ? Theme.of(context).primaryColor : const Color(0xff999999);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12.r),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 8.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SvgPicture.asset(
              iconPath,
              width: isSelected ? 32.w : 24.w,
              height: isSelected ? 32.h : 24.h,
            ),
            SizedBox(height: 4.h),
            Text(
              label,
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
