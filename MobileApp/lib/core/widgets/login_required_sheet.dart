import 'package:alrasmarket/core/router/app_router.dart';
import 'package:alrasmarket/core/serveses/auth_service.dart';
import 'package:alrasmarket/core/services_locator/services_locator.dart';
import 'package:alrasmarket/core/theme/colors.dart';
import 'package:alrasmarket/features/clint/presentation/controller/cubit/clint_cubit.dart';
import 'package:alrasmarket/features/company/presentation/controller/cubit/company_cubit.dart';
import 'package:alrasmarket/features/person/presentation/controller/cubit/person_cubit.dart';
import 'package:alrasmarket/generated/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

/// Guest catalog home (Apple requires browseable content before login).
const String kGuestHomeRoute = AppRoutes.kCompanyHomeView;

void goToGuestHome(BuildContext context) {
  final clint = sl<ClintCubit>();
  if (!clint.isClosed) {
    clint.setTab(0);
    clint.clearHomeCatalogMemory();
  }
  final company = sl<CompanyCubit>();
  if (!company.isClosed) {
    company.setTab(0);
  }
  final person = sl<PersonCubit>();
  if (!person.isClosed) {
    person.setTab(0);
  }
  context.go(kGuestHomeRoute);
}

/// Returns true when the user is signed in. Otherwise shows the login card.
bool ensureLoggedIn(BuildContext context) {
  if (AuthService.instance.isAuthenticated) return true;
  showLoginRequiredDialog(context);
  return false;
}

Future<void> showLoginRequiredDialog(BuildContext context) {
  final s = S.of(context);
  return showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (dialogContext) {
      return Dialog(
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
                Icons.lock_outline_rounded,
                size: 36.sp,
                color: LightColor.defaultColor,
              ),
              SizedBox(height: 12.h),
              Text(
                s.loginRequiredTitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1B3B5F),
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                s.loginRequiredMessage,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF6B7A90),
                  height: 1.4,
                ),
              ),
              SizedBox(height: 18.h),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                    context.push(AppRoutes.kLoginView);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: LightColor.defaultColor,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: EdgeInsets.symmetric(vertical: 12.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                  ),
                  child: Text(
                    s.login,
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 8.h),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                    context.push(AppRoutes.krecording);
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: LightColor.defaultColor,
                    padding: EdgeInsets.symmetric(vertical: 12.h),
                    side: BorderSide(color: LightColor.defaultColor),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                  ),
                  child: Text(
                    s.createAccount,
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
