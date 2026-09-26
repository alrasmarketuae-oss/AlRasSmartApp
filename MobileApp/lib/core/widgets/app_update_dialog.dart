import 'package:alrasmarket/core/services/app_update_checker.dart';
import 'package:alrasmarket/core/theme/colors.dart';
import 'package:alrasmarket/generated/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:url_launcher/url_launcher.dart';

Future<void> showAppUpdateDialog(
  BuildContext context, {
  required AppUpdateInfo info,
}) {
  final s = S.of(context);
  final isAr = Localizations.localeOf(context).languageCode == 'ar';
  final force = info.kind == AppUpdateKind.force;
  final custom = isAr ? info.messageAr : info.messageEn;
  final body = (custom != null && custom.trim().isNotEmpty)
      ? custom.trim()
      : (force ? s.appUpdateForceMessage : s.appUpdateMessage);

  return showDialog<void>(
    context: context,
    barrierDismissible: !force,
    builder: (dialogContext) {
      return PopScope(
        canPop: !force,
        child: Dialog(
          insetPadding: EdgeInsets.symmetric(horizontal: 28.w),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18.r),
          ),
          child: Padding(
            padding: EdgeInsets.fromLTRB(20.w, 22.h, 20.w, 16.h),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.system_update_rounded,
                  size: 40.sp,
                  color: LightColor.defaultColor,
                ),
                SizedBox(height: 12.h),
                Text(
                  s.appUpdateTitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1B3B5F),
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  body,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF6B7A90),
                    height: 1.4,
                  ),
                ),
                SizedBox(height: 6.h),
                Text(
                  '${info.installedVersion} → ${info.latestVersion}',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w700,
                    color: LightColor.defaultColor,
                  ),
                ),
                SizedBox(height: 18.h),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () async {
                      final uri = Uri.tryParse(info.storeUrl);
                      if (uri != null) {
                        await launchUrl(uri, mode: LaunchMode.externalApplication);
                      }
                      if (force) return;
                      if (dialogContext.mounted) {
                        Navigator.of(dialogContext).pop();
                      }
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: LightColor.defaultColor,
                      padding: EdgeInsets.symmetric(vertical: 12.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                    ),
                    child: Text(
                      s.appUpdateNow,
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                if (!force) ...[
                  SizedBox(height: 8.h),
                  TextButton(
                    onPressed: () async {
                      await AppUpdateChecker.dismissSoftUpdate(info.latestVersion);
                      if (dialogContext.mounted) {
                        Navigator.of(dialogContext).pop();
                      }
                    },
                    child: Text(
                      s.appUpdateLater,
                      style: TextStyle(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF6B7A90),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    },
  );
}
