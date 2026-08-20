import 'package:alrasmarket/core/router/app_router.dart';
import 'package:alrasmarket/core/serveses/auth_service.dart';
import 'package:alrasmarket/core/widgets/login_required_sheet.dart';
import 'package:alrasmarket/core/theme/app_fonts.dart';
import 'package:alrasmarket/core/theme/brand_colors.dart';
import 'package:alrasmarket/core/utils/assets.dart';
import 'package:alrasmarket/core/widgets/colored_brand_title.dart';
import 'package:alrasmarket/features/auth/presentation/controller/cubit/auth_cubit.dart';
import 'package:alrasmarket/features/auth/presentation/widgets/biometric_unlock_button.dart';
import 'package:alrasmarket/generated/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

/// Accent used by the shipping entry point; the rest come from [BrandColors].
const Color _shippingOrange = Color(0xFFF97316);

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
                            SizedBox(height: 8.h),
                            Image.asset(
                              AppAssets.logo,
                              width: 132.w,
                              fit: BoxFit.contain,
                              filterQuality: FilterQuality.high,
                            ),
                            SizedBox(height: 10.h),
                            ColoredBrandTitle(
                              fontSize: 26.sp,
                              includeAppWord: false,
                            ),
                            SizedBox(height: 14.h),
                            const BrandDotDivider(),
                            SizedBox(height: 14.h),
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
                            SizedBox(height: 24.h),
                            const BiometricUnlockButton(),
                            _RoleTile(
                              accent: BrandColors.primaryBlue,
                              tint: const Color(0xFFF4F7FB),
                              icon: Icons.person_outline_rounded,
                              title: s.registerClient,
                              subtitle: s.registerClientSubtitle,
                              onTap: () => context.push(
                                AppRoutes.kRegisterView,
                                extra: {'isCompany': false},
                              ),
                            ),
                            SizedBox(height: 12.h),
                            _RoleTile(
                              accent: const Color(0xFF16A34A),
                              tint: const Color(0xFFF1FAF4),
                              icon: Icons.storefront_rounded,
                              title: s.registerSupplier,
                              subtitle: s.registerSupplierSubtitle,
                              onTap: () => context.push(
                                AppRoutes.kRegisterView,
                                extra: {'isCompany': true},
                              ),
                            ),
                            SizedBox(height: 12.h),
                            _RoleTile(
                              accent: _shippingOrange,
                              tint: const Color(0xFFFFF6EE),
                              icon: Icons.directions_boat_rounded,
                              title: s.shippingCompany,
                              subtitle: isAr
                                  ? 'شحن سريع وآمن داخل وخارج الدولة'
                                  : s.shippingCompanySubtitle,
                              onTap: () =>
                                  context.push(AppRoutes.kShippingLoginView),
                            ),
                            SizedBox(height: 18.h),
                            _LoginButton(
                              label: s.login,
                              onTap: () => context.push(AppRoutes.kLoginView),
                            ),
                            SizedBox(height: 16.h),
                            _GuestEntry(
                              label: isAr ? 'دخول زائر' : s.loginAsGuest,
                              onTap: () async {
                                await AuthService.instance.clearAuthData();
                                if (!context.mounted) return;
                                goToGuestHome(context);
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

/// Full-width entry card: tinted surface, solid accent icon, trailing chevron.
class _RoleTile extends StatelessWidget {
  const _RoleTile({
    required this.accent,
    required this.tint,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final Color accent;
  final Color tint;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: tint,
      borderRadius: BorderRadius.circular(16.r),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16.r),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(color: accent.withValues(alpha: 0.12)),
          ),
          // Icon stays leading-left in both locales, matching the design.
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: Row(
              children: [
                Container(
                  width: 50.w,
                  height: 50.w,
                  decoration: BoxDecoration(
                    color: accent,
                    borderRadius: BorderRadius.circular(14.r),
                    boxShadow: [
                      BoxShadow(
                        color: accent.withValues(alpha: 0.30),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(icon, color: Colors.white, size: 26.sp),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        title,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w800,
                          color: accent,
                          fontFamily: AppFonts.cairo,
                        ),
                      ),
                      SizedBox(height: 3.h),
                      Text(
                        subtitle,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 11.5.sp,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF8A94A6),
                          fontFamily: AppFonts.cairo,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 4.w),
                Icon(
                  Icons.chevron_right_rounded,
                  color: accent.withValues(alpha: 0.85),
                  size: 24.sp,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LoginButton extends StatelessWidget {
  const _LoginButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16.r),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16.r),
        child: Ink(
          width: double.infinity,
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16.r),
            gradient: const LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [Color(0xFF0B4FD1), Color(0xFF1E6BE8)],
            ),
            boxShadow: [
              BoxShadow(
                color: BrandColors.primaryBlue.withValues(alpha: 0.32),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: Row(
              children: [
                Container(
                  width: 44.w,
                  height: 44.w,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.35),
                    ),
                  ),
                  child: Icon(
                    Icons.login_rounded,
                    color: Colors.white,
                    size: 22.sp,
                  ),
                ),
                Expanded(
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 17.sp,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      fontFamily: AppFonts.cairo,
                    ),
                  ),
                ),
                SizedBox(width: 44.w),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GuestEntry extends StatelessWidget {
  const _GuestEntry({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final lineColor = BrandColors.primaryBlue.withValues(alpha: 0.20);
    return Row(
      children: [
        Expanded(child: Divider(color: lineColor, thickness: 1)),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20.r),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w700,
                    color: BrandColors.primaryBlue,
                    fontFamily: AppFonts.cairo,
                  ),
                ),
                SizedBox(width: 6.w),
                Icon(
                  Icons.person_outline_rounded,
                  color: BrandColors.primaryBlue,
                  size: 18.sp,
                ),
              ],
            ),
          ),
        ),
        Expanded(child: Divider(color: lineColor, thickness: 1)),
      ],
    );
  }
}
