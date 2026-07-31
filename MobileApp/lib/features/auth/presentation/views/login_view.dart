import 'dart:io';

import 'package:alrasmarket/core/router/app_router.dart';
import 'package:alrasmarket/core/serveses/auth_service.dart';
import 'package:alrasmarket/core/theme/colors.dart';
import 'package:alrasmarket/core/ui/widgets/feedback/app_toast.dart';
import 'package:alrasmarket/core/utils/assets.dart';
import 'package:alrasmarket/core/widgets/auth_header.dart';
import 'package:alrasmarket/core/widgets/costomtextform.dart';
import 'package:alrasmarket/core/widgets/custom_circular_progress_indicator.dart';
import 'package:alrasmarket/core/widgets/custom_social_button.dart';
import 'package:alrasmarket/core/widgets/primary_button.dart';
import 'package:alrasmarket/features/auth/presentation/controller/cubit/auth_cubit.dart';
import 'package:alrasmarket/features/auth/presentation/controller/cubit/auth_states.dart';
import 'package:alrasmarket/generated/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

class LoginView extends StatelessWidget {
  const LoginView({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        //backgroundColor: const Color(0xffF2F7FF),
        body: BlocConsumer<AuthCubit, AuthStates>(
          listener: (context, state) {
            if (state is LoginSuccessState) {
              AppToast.showSuccess(context, S.of(context).loginSuccess);
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
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AuthHeader(),
            SizedBox(height: 24.h),
            Text(
              S.of(context).login,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20.sp,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF333333),
              ),
            ),
            SizedBox(height: 32.h),
            CustomTextFormField(
              controller: _emailController,
              label: S.of(context).email,
              hintText: S.of(context).enterYourEmail,
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return S.of(context).thisFieldIsRequired;
                }
                return null;
              },
            ),
            SizedBox(height: 18.h),
            CustomTextFormField(
              controller: _passwordController,
              label: S.of(context).password,
              hintText: S.of(context).enterYourPassword,
              isPassword: true,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return S.of(context).thisFieldIsRequired;
                }
                return null;
              },
            ),
            SizedBox(height: 8.h),
            Align(
              alignment: isArabic
                  ? Alignment.centerLeft
                  : Alignment.centerRight,
              child: TextButton(
                onPressed: () => context.push('/ForgotPasswordView'),
                style: TextButton.styleFrom(padding: EdgeInsets.zero),
                child: Text(
                  S.of(context).forgotPassword,
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: const Color(0xCC333333),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
            SizedBox(height: 16.h),
            SizedBox(
              height: 48.h,
              child: widget.isLoading
                  ? const Center(child: CustomCircleLoader())
                  : PrimaryButton(
                      text: S.of(context).login,
                      onPressed: _handleLogin,
                      backgroundColor: LightColor.defaultColor,
                    ),
            ),
            SizedBox(height: 28.h),
            Row(
              children: [
                const Expanded(child: Divider(color: Color(0xFFD0D5D5))),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10.w),
                  child: Text(
                    S.of(context).or,
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: const Color(0xFFD0D5D5),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const Expanded(child: Divider(color: Color(0xFFD0D5D5))),
              ],
            ),
            SizedBox(height: 18.h),
            CustomSocialButton(
              label: S.of(context).continueWithGoogle,
              assetImage: AppAssets.googleIcon,
              onPressed: widget.isLoading
                  ? () {}
                  : () => AuthCubit.get(context).loginWithGoogle(),
            ),
            if (Platform.isIOS) ...[
              SizedBox(height: 12.h),
              CustomSocialButton(
                label: S.of(context).continueWithApple,
                assetImage: AppAssets.appleIcon,
                onPressed: widget.isLoading
                    ? () {}
                    : () => AuthCubit.get(context).loginWithApple(),
              ),
            ],
            SizedBox(height: 28.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  S.of(context).dontHaveAnAccount,
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: const Color(0xCC333333),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    try {
                      context.push(
                        AppRoutes.kRegisterView,
                        extra: {'isCompany': false},
                      );
                    } catch (_) {}
                  },
                  child: Text(
                    S.of(context).signUp,
                    style: TextStyle(
                      fontSize: 16.sp,
                      color: LightColor.defaultColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16.h),
          ],
        ),
      ),
    );
  }
}
