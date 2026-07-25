import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class CreateAdHeroBanner extends StatelessWidget {
  const CreateAdHeroBanner({super.key});

  static const _assetPath = 'assets/images/create_ad_banner.png';
  /// Native asset size 962×162 — keep full image visible (no cover crop).
  static const _aspectRatio = 962 / 162;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(bottom: 8.h),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2F6AAD).withValues(alpha: 0.2),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12.r),
        child: AspectRatio(
          aspectRatio: _aspectRatio,
          child: Image.asset(
            _assetPath,
            fit: BoxFit.contain,
            alignment: Alignment.center,
            width: double.infinity,
            errorBuilder: (context, error, stackTrace) => Container(
              color: const Color(0xFF2F6AAD),
              alignment: Alignment.centerLeft,
              padding: EdgeInsets.symmetric(horizontal: 14.w),
              child: Text(
                'Create New Ad',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
