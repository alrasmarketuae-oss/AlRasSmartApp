import 'package:alrasmarket/core/router/app_router.dart';
import 'package:alrasmarket/core/serveses/auth_service.dart';
import 'package:alrasmarket/core/services_locator/services_locator.dart';
import 'package:alrasmarket/core/theme/app_fonts.dart';
import 'package:alrasmarket/core/theme/brand_colors.dart';
import 'package:alrasmarket/core/utils/assets.dart';
import 'package:alrasmarket/core/widgets/colored_brand_title.dart';
import 'package:alrasmarket/features/auth/presentation/controller/cubit/auth_cubit.dart';
import 'package:alrasmarket/features/clint/presentation/controller/cubit/clint_cubit.dart';
import 'package:alrasmarket/generated/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

class RecordingView extends StatelessWidget {
  const RecordingView({super.key});

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final isAr = Localizations.localeOf(context).languageCode == 'ar';

    return Scaffold(
      backgroundColor: BrandColors.bgWhite,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w),
          child: Column(
            children: [
              SizedBox(height: 8.h),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: _LanguagePill(isArabic: isAr),
              ),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: constraints.maxHeight,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Image.asset(
                              AppAssets.logo,
                              width: 108.w,
                              fit: BoxFit.contain,
                              filterQuality: FilterQuality.high,
                            ),
                            SizedBox(height: 14.h),
                            Text(
                              s.welcomeTo,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 15.sp,
                                fontWeight: FontWeight.w600,
                                color: BrandColors.darkBlue,
                                fontFamily: AppFonts.cairo,
                              ),
                            ),
                            SizedBox(height: 4.h),
                            ColoredBrandTitle(fontSize: 24.sp),
                            SizedBox(height: 12.h),
                            const BrandDotDivider(),
                            SizedBox(height: 12.h),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 8.w),
                              child: Text(
                                s.welcomeTagline,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 13.sp,
                                  fontWeight: FontWeight.w500,
                                  color: const Color(0xFF6B7280),
                                  fontFamily: AppFonts.cairo,
                                  height: 1.45,
                                ),
                              ),
                            ),
                            SizedBox(height: 20.h),
                            IntrinsicHeight(
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Expanded(
                                    child: _RoleCard(
                                      color: BrandColors.primaryBlue,
                                      icon: Icons.person_outline_rounded,
                                      title: s.registerClient,
                                      subtitle: s.registerClientSubtitle,
                                      onTap: () => context.push(
                                        AppRoutes.kRegisterView,
                                        extra: {'isCompany': false},
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 12.w),
                                  Expanded(
                                    child: _RoleCard(
                                      color: BrandColors.primaryGreen,
                                      icon: Icons.storefront_outlined,
                                      title: s.registerSupplier,
                                      subtitle: s.registerSupplierSubtitle,
                                      onTap: () => context.push(
                                        AppRoutes.kRegisterView,
                                        extra: {'isCompany': true},
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: 12.h),
                            _ActionCard(
                              icon: Icons.login_rounded,
                              iconColor: BrandColors.primaryBlue,
                              title: s.login,
                              subtitle: s.loginSubtitle,
                              onTap: () => context.push(AppRoutes.kLoginView),
                            ),
                            SizedBox(height: 10.h),
                            _ActionCard(
                              icon: Icons.directions_boat_filled_outlined,
                              iconColor: BrandColors.darkBlue,
                              title: s.shippingCompany,
                              subtitle: isAr
                                  ? 'شحن سريع وآمن'
                                  : s.shippingCompanySubtitle,
                              onTap: () =>
                                  context.push(AppRoutes.kShippingLoginView),
                            ),
                            SizedBox(height: 10.h),
                            _ActionCard(
                              icon: Icons.person_outline_rounded,
                              iconColor: BrandColors.primaryBlue,
                              title: isAr ? 'دخول زائر' : s.loginAsGuest,
                              subtitle: isAr
                                  ? 'تصفح بدون تسجيل دخول'
                                  : 'Browse without signing in',
                              onTap: () async {
                                await AuthService.instance.clearAuthData();
                                final clintCubit = sl<ClintCubit>();
                                if (!clintCubit.isClosed) {
                                  clintCubit.clearHomeCatalogMemory();
                                  clintCubit.setTab(0);
                                }
                                if (!context.mounted) return;
                                context.go(AppRoutes.kClientHomeView);
                              },
                            ),
                            SizedBox(height: 16.h),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LanguagePill extends StatelessWidget {
  const _LanguagePill({required this.isArabic});

  final bool isArabic;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: BrandColors.bgWhite,
      borderRadius: BorderRadius.circular(22.r),
      child: InkWell(
        onTap: () => AuthCubit.get(context).setLocale(),
        borderRadius: BorderRadius.circular(22.r),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 7.h),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22.r),
            border: Border.all(color: const Color(0xFFD5DEE8)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SvgPicture.asset(
                AppAssets.languageIcon,
                width: 16.w,
                height: 16.w,
                colorFilter: const ColorFilter.mode(
                  BrandColors.primaryBlue,
                  BlendMode.srcIn,
                ),
              ),
              SizedBox(width: 6.w),
              Text(
                isArabic ? 'English' : 'العربية',
                style: TextStyle(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w600,
                  color: BrandColors.darkBlue,
                  fontFamily: AppFonts.cairo,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.color,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final Color color;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(14.r),
      elevation: 2,
      shadowColor: color.withValues(alpha: 0.35),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14.r),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 12.h),
          child: Row(
            children: [
              Container(
                width: 34.w,
                height: 34.w,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(8.r),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.35),
                  ),
                ),
                child: Icon(icon, color: Colors.white, size: 20.sp),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        fontFamily: AppFonts.cairo,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 9.5.sp,
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withValues(alpha: 0.92),
                        fontFamily: AppFonts.cairo,
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: BrandColors.bgWhite,
      borderRadius: BorderRadius.circular(14.r),
      elevation: 2,
      shadowColor: Colors.black.withValues(alpha: 0.08),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14.r),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14.r),
            border: Border.all(color: const Color(0xFFE8EEF5)),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 24.sp,
                child: Icon(icon, color: iconColor, size: 24.sp),
              ),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w800,
                        color: BrandColors.darkBlue,
                        fontFamily: AppFonts.cairo,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      subtitle,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF8A94A6),
                        fontFamily: AppFonts.cairo,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: 24.sp,
                child: Icon(
                  Directionality.of(context) == TextDirection.rtl
                      ? Icons.chevron_left_rounded
                      : Icons.chevron_right_rounded,
                  color: BrandColors.primaryBlue.withValues(alpha: 0.75),
                  size: 22.sp,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
