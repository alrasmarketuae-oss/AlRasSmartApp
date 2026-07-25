import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/theme/colors.dart';
import '../../../core/utils/assets.dart';
import 'custom_social_icon.dart';

class BackButtonWidget extends StatelessWidget {
  BackButtonWidget({
    super.key,
    this.onTap,
    this.height,
    this.width,
    this.isReverse = false,
  });
  final VoidCallback? onTap;
  double? height;
  double? width;
  bool isReverse = false;

  @override
  Widget build(BuildContext context) {
    bool isEnglish = Localizations.localeOf(context).languageCode == 'en';
    if (isReverse) {
      isEnglish = !isEnglish;
    }
    String assetImage = isEnglish ? AppAssets.backIconAR : AppAssets.backIconEN;
    return Container(
      height: width ?? 40.h,
      width: width ?? 40.w,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: LightColor.defaultColor, width: 2.w),
      ),
      child: CustomSocialIcon(
        onTap: () {
          Navigator.pop(context);
        },
        assetImage: assetImage,
        width: 24.w,
        height: 24.h,
      ),
    );
  }
}
