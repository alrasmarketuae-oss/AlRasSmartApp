import 'package:alrasmarket/core/router/app_router.dart';
import 'package:alrasmarket/core/utils/assets.dart';
import 'package:alrasmarket/generated/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

class TrackOrderCustomerServiceCard extends StatelessWidget {
  const TrackOrderCustomerServiceCard({
    super.key,
    required this.fontFamily,
    this.phoneNumber,
  });

  final String fontFamily;
  final String? phoneNumber;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: const Color(0xFFEAECF0)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              s.customerService,
              style: TextStyle(
                color: const Color(0xFF333333),
                fontFamily: fontFamily,
                fontSize: 15.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          _ActionIconButton(
            backgroundColor: const Color(0xFFFFF3E0),
            onTap: () => context.push(AppRoutes.kTechnicalSupportView),
            child: SvgPicture.asset(
              AppAssets.chatFillIcon,
              width: 22.w,
              height: 22.h,
              colorFilter: const ColorFilter.mode(
                Color(0xFFF57C00),
                BlendMode.srcIn,
              ),
            ),
          ),
          SizedBox(width: 10.w),
          _ActionIconButton(
            backgroundColor: const Color(0xFFE8F5E9),
            onTap: () => _callPhone(context),
            child: SvgPicture.asset(
              AppAssets.profilePhoneIcon,
              width: 22.w,
              height: 22.h,
              colorFilter: const ColorFilter.mode(
                Color(0xFF4CAF50),
                BlendMode.srcIn,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _callPhone(BuildContext context) async {
    final raw = phoneNumber?.trim();
    if (raw == null || raw.isEmpty) return;

    final uri = Uri(scheme: 'tel', path: raw.replaceAll(' ', ''));
    if (!await launchUrl(uri)) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open phone dialer.')),
      );
    }
  }
}

class _ActionIconButton extends StatelessWidget {
  const _ActionIconButton({
    required this.backgroundColor,
    required this.onTap,
    required this.child,
  });

  final Color backgroundColor;
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10.r),
      child: Container(
        width: 44.w,
        height: 44.w,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(10.r),
        ),
        alignment: Alignment.center,
        child: child,
      ),
    );
  }
}
