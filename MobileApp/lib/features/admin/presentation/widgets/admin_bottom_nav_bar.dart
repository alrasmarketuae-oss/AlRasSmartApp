import 'package:alrasmarket/core/theme/colors.dart';
import 'package:alrasmarket/core/utils/assets.dart';
import 'package:alrasmarket/generated/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';

class AdminBottomNavBar extends StatelessWidget {
  const AdminBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final items = [
      (
        selectedIcon: AppAssets.blueHomeIcon,
        icon: AppAssets.homeIcon,
        label: isAr ? 'الشركات' : 'Companies',
      ),
      (
        selectedIcon: AppAssets.blueProfileIcon,
        icon: AppAssets.profileIcon,
        label: S.of(context).profile,
      ),
    ];

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
        top: false,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
          child: Row(
            children: [
              for (var i = 0; i < items.length; i++)
                Expanded(
                  child: InkWell(
                    onTap: () => onTap(i),
                    borderRadius: BorderRadius.circular(16.r),
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 6.h),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SvgPicture.asset(
                            currentIndex == i
                                ? items[i].selectedIcon
                                : items[i].icon,
                            width: 24.w,
                            height: 24.w,
                          ),
                          SizedBox(height: 4.h),
                          Text(
                            items[i].label,
                            style: TextStyle(
                              fontSize: 11.sp,
                              fontWeight: currentIndex == i
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: currentIndex == i
                                  ? LightColor.defaultColor
                                  : AppColors.subtitle(context),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
