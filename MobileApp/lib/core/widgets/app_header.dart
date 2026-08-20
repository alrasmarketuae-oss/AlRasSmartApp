import 'package:alrasmarket/core/router/app_router.dart';
import 'package:alrasmarket/core/widgets/login_required_sheet.dart';
import 'package:alrasmarket/core/serveses/auth_service.dart';
import 'package:alrasmarket/core/serveses/cached_constants.dart';
import 'package:alrasmarket/core/utils/assets.dart';
import 'package:alrasmarket/core/utils/string_display_format.dart';
import 'package:alrasmarket/core/widgets/header_notification_bell.dart';
import 'package:alrasmarket/core/widgets/profile_avatar.dart';
import 'package:alrasmarket/generated/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

class AppHeader extends StatelessWidget {
  final bool isRecording;
  const AppHeader({super.key, this.isRecording = false});

  static String displayName(String? raw, {required String fallback}) {
    final value = raw?.trim() ?? '';
    if (value.isEmpty) return fallback;
    return value.capitalizeFirst();
  }

  String? _accountSubtitle(BuildContext context, S s) {
    final auth = AuthService.instance;
    if (auth.isSupplierAccount) return s.supplierAccount;
    if (auth.isCompanyCustomerAccount) return s.companyCustomerAccount;
    if (auth.isAdminAccount) {
      return Localizations.localeOf(context).languageCode == 'ar'
          ? 'حساب أدمن'
          : 'Admin account';
    }
    if (auth.isPersonalCustomerAccount) return s.personalAccount;
    return null;
  }

  void _openProfile(BuildContext context) {
    if (!ensureLoggedIn(context)) return;
    if (AppRoutes.shouldSkipPush(context, AppRoutes.kEditProfileView)) return;
    context.push(AppRoutes.kEditProfileView);
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final display = displayName(
      name,
      fallback: s.alRasMarket,
    );
    final subtitle = _accountSubtitle(context, s);

    return Row(
      children: [
        InkWell(
          onTap: () => _openProfile(context),
          borderRadius: BorderRadius.circular(20.r),
          child: const HeaderProfileAvatar(),
        ),
        SizedBox(width: 8.w),
        Expanded(
          child: InkWell(
            onTap: () => _openProfile(context),
            borderRadius: BorderRadius.circular(8.r),
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 2.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    display,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    softWrap: false,
                    textHeightBehavior: const TextHeightBehavior(
                      applyHeightToFirstAscent: false,
                      applyHeightToLastDescent: false,
                    ),
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
                      height: 1.15,
                      letterSpacing: 0,
                    ),
                  ),
                  if (subtitle != null) ...[
                    SizedBox(height: 2.h),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      softWrap: false,
                      textHeightBehavior: const TextHeightBehavior(
                        applyHeightToFirstAscent: false,
                        applyHeightToLastDescent: false,
                      ),
                      style: TextStyle(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF64748B),
                        height: 1.15,
                        letterSpacing: 0,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
        if (!isRecording) ...[
          SizedBox(width: 4.w),
          const HeaderNotificationBell(),
          SizedBox(width: 2.w),
          Image.asset(AppAssets.logo, width: 48.w, height: 40.h),
        ],
      ],
    );
  }
}
