import 'package:alrasmarket/core/utils/assets.dart';
import 'package:alrasmarket/core/theme/colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';

class ConfirmCircalView extends StatelessWidget {
  const ConfirmCircalView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SvgPicture.asset(
            AppAssets.checkCircleIcon,
            width: 120.w,
            height: 120.h,
          ),
          SizedBox(height: 16.h),
          Container(
            decoration: const BoxDecoration(),
            padding: EdgeInsets.zero,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  'Request posted \n successfully',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: const Color.fromRGBO(26, 26, 26, 1),
                    fontSize: 24.sp,
                    letterSpacing: 0,
                    fontWeight: FontWeight.w600,
                    height: 1.5,
                  ),
                ),
                SizedBox(height: 18.h),
                Container(
                  decoration: const BoxDecoration(),
                  padding: EdgeInsets.zero,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text(
                        'Your request has been posted successfully and suppliers will be able to see it',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: LightColor.greyTextColor,
                          fontSize: 14.sp,
                          letterSpacing: 0,
                          fontWeight: FontWeight.normal,
                          height: 1.5,
                        ),
                      ),
                      SizedBox(height: 12.h),
                      Text(
                        'We will notify you when any offers are received',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: LightColor.greyTextColor,
                          fontSize: 14.sp,
                          letterSpacing: 0,
                          fontWeight: FontWeight.normal,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 24.h),
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              color: Color.fromRGBO(242, 247, 255, 1),
            ),
            padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 20.h),
            child: Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  height: 52.h,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: LightColor.defaultColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      elevation: 0,
                    ),
                    onPressed: () {},
                    child: Text(
                      'View all requests',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16.sp,
                        letterSpacing: 0,
                        fontWeight: FontWeight.normal,
                        height: 1.5,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 16.h),
                SizedBox(
                  width: double.infinity,
                  height: 52.h,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: LightColor.defaultColor, width: 2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                    ),
                    onPressed: () {},
                    child: Text(
                      'Back to Home',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: LightColor.defaultColor,
                        fontSize: 16.sp,
                        letterSpacing: 0,
                        fontWeight: FontWeight.normal,
                        height: 1.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
