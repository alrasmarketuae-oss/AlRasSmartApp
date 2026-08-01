import 'dart:io';

import 'package:alrasmarket/core/router/app_router.dart';
import 'package:alrasmarket/core/serveses/auth_service.dart';
import 'package:alrasmarket/core/ui/widgets/feedback/app_toast.dart';
import 'package:alrasmarket/core/utils/assets.dart';
import 'package:alrasmarket/core/widgets/custom_circular_progress_indicator.dart';
import 'package:alrasmarket/features/auth/presentation/controller/cubit/auth_cubit.dart';
import 'package:alrasmarket/features/auth/presentation/controller/cubit/auth_states.dart';
import 'package:alrasmarket/features/auth/presentation/widgets/biometric_enrollment_prompt.dart';
import 'package:alrasmarket/features/auth/presentation/widgets/biometric_unlock_button.dart';
import 'package:alrasmarket/generated/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';

const Color _kTitleColor = Color(0xFF1B3B5F);
const Color _kBodyColor = Color(0xFF6B7A90);
const Color _kLabelColor = Color(0xFF33455C);
const Color _kHintColor = Color(0xFF9AA6B8);
const Color _kBorderColor = Color(0xFFE6ECF5);
const Color _kPrimaryDark = Color(0xFF16499E);
const Color _kPrimaryLight = Color(0xFF2E77CC);

class LoginView extends StatelessWidget {
  const LoginView({super.key});

  @override
  Widget build(BuildContext context) {
    // Scaffold stays outermost so its background also fills the status bar.
    return Scaffold(
      backgroundColor: const Color(0xFFF7FAFF),
      body: Stack(
        children: [
          const Positioned.fill(child: _AuthBackground()),
          SafeArea(
            child: BlocConsumer<AuthCubit, AuthStates>(
              listener: (context, state) async {
                if (state is LoginSuccessState) {
                  AppToast.showSuccess(context, S.of(context).loginSuccess);
                  await promptBiometricEnrollmentIfNeeded(context);
                  if (!context.mounted) return;
                  AuthCubit.navigateAfterAuthSuccess(
                    context,
                    state.loginResponse,
                  );
                } else if (state is LoginErrorState) {
                  if (AuthCubit.isPendingApprovalMessage(state.message)) {
                    AuthService.instance.setCompanyWaiting(true);
                    context.go(AppRoutes.kUnderReviewView);
                    return;
                  }
                  if (AuthCubit.isVerifyEmailMessage(state.message)) {
                    final em = AuthService.instance.currentUserEmail ?? '';
                    context.go(
                      '${AppRoutes.kOtpVerificationView}?email=${Uri.encodeComponent(em)}',
                    );
                    return;
                  }
                  AppToast.showError(
                    context,
                    '${S.of(context).loginError}: ${state.message}',
                  );
                }
              },
              builder: (context, state) {
                final isLoading = state is LoginLoadingState;
                return Stack(
                  children: [
                    _LoginFormBody(isLoading: isLoading),
                    if (isLoading)
                      Positioned.fill(
                        child: AbsorbPointer(
                          child: Container(
                            color: Colors.white.withValues(alpha: 0.55),
                            child: const Center(child: CustomCircleLoader()),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _LoginFormBody extends StatefulWidget {
  const _LoginFormBody({required this.isLoading});

  final bool isLoading;

  @override
  State<_LoginFormBody> createState() => _LoginFormBodyState();
}

class _LoginFormBodyState extends State<_LoginFormBody> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    AuthCubit.get(context).login(
      email: _emailController.text.trim(),
      password: _passwordController.text.trim(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(20.w, 8.h, 20.w, 24.h),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _LoginTopBar(),
            SizedBox(height: 40.h),
            Text(
              s.welcomeBack,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 26.sp,
                fontWeight: FontWeight.w700,
                color: _kTitleColor,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              s.signInToContinue,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13.sp,
                fontWeight: FontWeight.w500,
                color: _kBodyColor,
              ),
            ),
            SizedBox(height: 14.h),
            const _AccentIndicator(),
            SizedBox(height: 22.h),
            _GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _FieldLabel(s.email),
                  SizedBox(height: 8.h),
                  _AuthField(
                    controller: _emailController,
                    hintText: s.enterYourEmail,
                    icon: Icons.mail_outline_rounded,
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return s.thisFieldIsRequired;
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 18.h),
                  _FieldLabel(s.password),
                  SizedBox(height: 8.h),
                  _AuthField(
                    controller: _passwordController,
                    hintText: s.enterYourPassword,
                    icon: Icons.lock_outline_rounded,
                    obscureText: _obscurePassword,
                    trailing: IconButton(
                      onPressed: () => setState(
                        () => _obscurePassword = !_obscurePassword,
                      ),
                      splashRadius: 20.r,
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        size: 20.sp,
                        color: _kHintColor,
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return s.thisFieldIsRequired;
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 10.h),
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: GestureDetector(
                      onTap: () => context.push('/ForgotPasswordView'),
                      behavior: HitTestBehavior.opaque,
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 2.h),
                        child: Text(
                          s.forgotPassword.trim(),
                          style: TextStyle(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w600,
                            color: _kPrimaryLight,
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 18.h),
                  _GradientButton(
                    label: s.login,
                    onPressed: widget.isLoading ? null : _handleLogin,
                  ),
                  SizedBox(height: 20.h),
                  _OrDivider(label: s.or),
                  SizedBox(height: 18.h),
                  _SocialButton(
                    label: s.signInWithGoogle,
                    assetImage: AppAssets.googleIcon,
                    onPressed: widget.isLoading
                        ? null
                        : () => AuthCubit.get(context).loginWithGoogle(),
                  ),
                  if (Platform.isIOS) ...[
                    SizedBox(height: 12.h),
                    _SocialButton(
                      label: s.signInWithApple,
                      assetImage: AppAssets.appleIcon,
                      onPressed: widget.isLoading
                          ? null
                          : () => AuthCubit.get(context).loginWithApple(),
                    ),
                  ],
                ],
              ),
            ),
            SizedBox(height: 22.h),
            const BiometricUnlockButton(circular: true),
            SizedBox(height: 6.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  s.dontHaveAnAccount,
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w500,
                    color: _kBodyColor,
                  ),
                ),
                SizedBox(width: 6.w),
                GestureDetector(
                  onTap: () {
                    try {
                      context.push(AppRoutes.krecording);
                    } catch (_) {}
                  },
                  behavior: HitTestBehavior.opaque,
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 8.h),
                    child: Text(
                      s.createAccount,
                      style: TextStyle(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w700,
                        color: _kPrimaryLight,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Language switch on the left and the brand logo on the right, in both locales.
class _LoginTopBar extends StatelessWidget {
  const _LoginTopBar();

  @override
  Widget build(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    return Directionality(
      textDirection: TextDirection.ltr,
      child: Row(
        children: [
          GestureDetector(
            onTap: () => AuthCubit.get(context).setLocale(),
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 4.w),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SvgPicture.asset(
                    AppAssets.languageIcon,
                    width: 20.w,
                    height: 20.w,
                    colorFilter: const ColorFilter.mode(
                      _kTitleColor,
                      BlendMode.srcIn,
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Text(
                    isArabic ? 'English' : 'اللغة العربية',
                    style: TextStyle(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w600,
                      color: _kTitleColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Spacer(),
          Image.asset(AppAssets.logo, width: 62.w, height: 44.h),
        ],
      ),
    );
  }
}

class _AccentIndicator extends StatelessWidget {
  const _AccentIndicator();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 26.w,
          height: 5.h,
          decoration: BoxDecoration(
            color: _kPrimaryDark,
            borderRadius: BorderRadius.circular(4.r),
          ),
        ),
        SizedBox(width: 6.w),
        Container(
          width: 5.w,
          height: 5.h,
          decoration: const BoxDecoration(
            color: Color(0xFFB9CDE8),
            shape: BoxShape.circle,
          ),
        ),
      ],
    );
  }
}

class _GlassCard extends StatelessWidget {
  const _GlassCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(18.w, 22.h, 18.w, 22.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24.r),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1B3B5F).withValues(alpha: 0.08),
            blurRadius: 28.r,
            offset: Offset(0, 12.h),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 13.sp,
        fontWeight: FontWeight.w700,
        color: _kLabelColor,
      ),
    );
  }
}

/// Icon stays on the left edge while the text follows the current locale,
/// matching the reference design in both Arabic and English.
class _AuthField extends StatelessWidget {
  const _AuthField({
    required this.controller,
    required this.hintText,
    required this.icon,
    this.keyboardType,
    this.obscureText = false,
    this.trailing,
    this.validator,
  });

  final TextEditingController controller;
  final String hintText;
  final IconData icon;
  final TextInputType? keyboardType;
  final bool obscureText;
  final Widget? trailing;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    return Directionality(
      textDirection: TextDirection.ltr,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: _kBorderColor),
        ),
        child: Row(
          children: [
            Padding(
              padding: EdgeInsets.only(left: 14.w, right: 10.w),
              child: Icon(icon, size: 20.sp, color: _kPrimaryLight),
            ),
            Expanded(
              child: TextFormField(
                controller: controller,
                obscureText: obscureText,
                keyboardType: keyboardType,
                validator: validator,
                textAlign: isArabic ? TextAlign.right : TextAlign.left,
                textDirection: isArabic
                    ? TextDirection.rtl
                    : TextDirection.ltr,
                cursorColor: _kPrimaryLight,
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF1F2937),
                ),
                decoration: InputDecoration(
                  hintText: hintText,
                  hintStyle: TextStyle(fontSize: 13.sp, color: _kHintColor),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  errorBorder: InputBorder.none,
                  focusedErrorBorder: InputBorder.none,
                  isDense: true,
                  errorStyle: TextStyle(fontSize: 11.sp, height: 1.2),
                  contentPadding: EdgeInsets.symmetric(vertical: 16.h),
                ),
              ),
            ),
            if (trailing != null)
              Padding(padding: EdgeInsets.only(right: 4.w), child: trailing!)
            else
              SizedBox(width: 14.w),
          ],
        ),
      ),
    );
  }
}

class _GradientButton extends StatelessWidget {
  const _GradientButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: onPressed == null ? 0.6 : 1,
      child: Container(
        height: 54.h,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [_kPrimaryDark, _kPrimaryLight],
          ),
          borderRadius: BorderRadius.circular(12.r),
          boxShadow: [
            BoxShadow(
              color: _kPrimaryDark.withValues(alpha: 0.28),
              blurRadius: 18.r,
              offset: Offset(0, 8.h),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(12.r),
            child: Center(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _OrDivider extends StatelessWidget {
  const _OrDivider({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider(color: _kBorderColor, thickness: 1)),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 12.w),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
              color: _kHintColor,
            ),
          ),
        ),
        const Expanded(child: Divider(color: _kBorderColor, thickness: 1)),
      ],
    );
  }
}

class _SocialButton extends StatelessWidget {
  const _SocialButton({
    required this.label,
    required this.assetImage,
    required this.onPressed,
  });

  final String label;
  final String assetImage;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    return Directionality(
      textDirection: TextDirection.ltr,
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(12.r),
          child: Container(
            height: 52.h,
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: _kBorderColor),
            ),
            child: Row(
              children: [
                SvgPicture.asset(assetImage, width: 22.w, height: 22.w),
                SizedBox(width: 12.w),
                Expanded(
                  child: Text(
                    label,
                    textAlign: isArabic ? TextAlign.right : TextAlign.left,
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      color: _kLabelColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AuthBackground extends StatelessWidget {
  const _AuthBackground();

  @override
  Widget build(BuildContext context) {
    return const RepaintBoundary(
      child: CustomPaint(painter: _AuthBackgroundPainter()),
    );
  }
}

class _AuthBackgroundPainter extends CustomPainter {
  const _AuthBackgroundPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final rect = Offset.zero & size;

    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFDFEFF), Color(0xFFEDF3FC)],
        ).createShader(rect),
    );

    _paintDots(canvas, w, h);
    _paintSwoosh(canvas, w, h);
  }

  void _paintDots(Canvas canvas, double w, double h) {
    const spacing = 13.0;
    final fadeEnd = h * 0.55;
    final paint = Paint();
    for (double y = spacing; y < fadeEnd; y += spacing) {
      final fade = (1 - (y / fadeEnd)).clamp(0.0, 1.0);
      paint.color = const Color(0xFF3A7DC5).withValues(alpha: 0.10 * fade);
      for (double x = spacing; x < w; x += spacing) {
        canvas.drawCircle(Offset(x, y), 1.1, paint);
      }
    }
  }

  void _paintSwoosh(Canvas canvas, double w, double h) {
    final band = Path()
      ..moveTo(w * 0.30, 0)
      ..quadraticBezierTo(w * 0.80, h * 0.02, w, h * 0.19)
      ..lineTo(w, 0)
      ..close();
    canvas.drawPath(
      band,
      Paint()
        ..shader =
            LinearGradient(
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
              colors: [
                const Color(0xFF2E77CC).withValues(alpha: 0.16),
                const Color(0xFF2E77CC).withValues(alpha: 0.03),
              ],
            ).createShader(
              Rect.fromLTWH(w * 0.30, 0, w * 0.70, h * 0.20),
            ),
    );

    final edge = Path()
      ..moveTo(w * 0.36, 0)
      ..quadraticBezierTo(w * 0.82, h * 0.025, w, h * 0.16);
    canvas.drawPath(
      edge,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..color = const Color(0xFF2E77CC).withValues(alpha: 0.28),
    );
  }

  @override
  bool shouldRepaint(covariant _AuthBackgroundPainter oldDelegate) => false;
}
