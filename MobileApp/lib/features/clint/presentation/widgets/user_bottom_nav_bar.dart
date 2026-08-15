import 'package:alrasmarket/generated/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:alrasmarket/core/theme/colors.dart';
import 'package:flutter_svg/svg.dart';

import '../../../../core/utils/assets.dart';

/// Bottom navigation bar for main user layout.
class UserBottomNavBar extends StatelessWidget {
  const UserBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.context,
    this.isPerson = false,
    this.showMyAds = true,
    this.unreadBadgeCount = 0,
    this.pendingOrdersBadgeCount = 0,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;
  final BuildContext context;
  final bool isPerson;
  final bool showMyAds;
  final int unreadBadgeCount;
  final int pendingOrdersBadgeCount;

  @override
  Widget build(BuildContext context) {
    final navItems = [
      (
        selectedIcon: AppAssets.blueHomeIcon,
        icon: AppAssets.homeIcon,
        label: S.of(context).home,
        outlinedCircle: false,
        badgeCount: 0,
      ),
      if (!isPerson)
        (
          selectedIcon: AppAssets.blueAddOrderIcon,
          icon: AppAssets.addOrderIcon,
          label: S.of(context).createOrder,
          outlinedCircle: false,
          badgeCount: 0,
        ),
      (
        selectedIcon: AppAssets.blueOrdersIcon,
        icon: AppAssets.ordersIcon,
        label: S.of(context).myOrders,
        outlinedCircle: false,
        badgeCount: pendingOrdersBadgeCount,
      ),
      if (showMyAds)
        (
          selectedIcon: AppAssets.blueMyAdsIcon,
          icon: AppAssets.myAdsIcon,
          label: S.of(context).myAds,
          outlinedCircle: false,
          badgeCount: 0,
        ),
      (
        selectedIcon: AppAssets.blueProfileIcon,
        icon: AppAssets.profileIcon,
        label: S.of(context).profile,
        outlinedCircle: true,
        badgeCount: 0,
      ),
    ];

    final dense = navItems.length > 4;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.navBar(context),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 6.h),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(
              navItems.length,
              (index) => BottomNavItem(
                iconPath: currentIndex == index
                    ? navItems[index].selectedIcon
                    : navItems[index].icon,
                label: navItems[index].label,
                isSelected: currentIndex == index,
                onTap: () => onTap(index),
                dense: dense,
                outlinedCircle: navItems[index].outlinedCircle,
                badgeCount: navItems[index].badgeCount,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class BottomNavItem extends StatelessWidget {
  const BottomNavItem({
    super.key,
    required this.iconPath,
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.dense = false,
    this.outlinedCircle = false,
    this.badgeCount = 0,
  });

  final String iconPath;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final bool dense;
  final bool outlinedCircle;
  final int badgeCount;

  @override
  Widget build(BuildContext context) {
    final color = isSelected
        ? LightColor.defaultColor
        : const Color(0xff999999);

    final iconSize = 24.w;

    Widget iconWidget = SvgPicture.asset(
      iconPath,
      width: outlinedCircle ? iconSize * 0.72 : iconSize,
      height: outlinedCircle ? iconSize * 0.72 : iconSize,
      colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
    );

    if (outlinedCircle) {
      iconWidget = Container(
        width: iconSize + 4.w,
        height: iconSize + 4.w,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: color, width: 1.6),
        ),
        child: iconWidget,
      );
    }

    if (badgeCount > 0) {
      final labelText = badgeCount > 99 ? '99+' : '$badgeCount';
      iconWidget = Stack(
        clipBehavior: Clip.none,
        children: [
          iconWidget,
          Positioned(
            right: -8.w,
            top: -6.h,
            child: Container(
              constraints: BoxConstraints(minWidth: 16.w),
              padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
              decoration: BoxDecoration(
                color: const Color(0xFFE53935),
                borderRadius: BorderRadius.circular(10.r),
                border: Border.all(color: Colors.white, width: 1.2),
              ),
              child: Text(
                labelText,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 9.sp,
                  fontWeight: FontWeight.w700,
                  height: 1.1,
                ),
              ),
            ),
          ),
        ],
      );
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12.r),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: dense ? 4.w : 10.w,
          vertical: 6.h,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(height: 28.w, child: Center(child: iconWidget)),
            SizedBox(height: 4.h),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: dense ? 10.sp : 11.sp,
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
