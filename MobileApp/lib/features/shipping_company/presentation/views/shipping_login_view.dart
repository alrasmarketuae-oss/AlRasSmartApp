import 'package:alrasmarket/core/router/app_router.dart';
import 'package:alrasmarket/core/serveses/auth_service.dart';
import 'package:alrasmarket/core/theme/colors.dart';
import 'package:alrasmarket/core/ui/widgets/feedback/app_toast.dart';
import 'package:alrasmarket/core/utils/assets.dart';
import 'package:alrasmarket/core/widgets/auth_header.dart';
import 'package:alrasmarket/core/widgets/costomtextform.dart';
import 'package:alrasmarket/core/widgets/custom_circular_progress_indicator.dart';
import 'package:alrasmarket/core/widgets/primary_button.dart';
import 'package:alrasmarket/features/auth/presentation/controller/cubit/auth_cubit.dart';
import 'package:alrasmarket/features/auth/presentation/controller/cubit/auth_states.dart';
import 'package:alrasmarket/features/shipping_company/presentation/controller/cubit/shipping_company_cubit.dart';
import 'package:alrasmarket/generated/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';

class ShippingLoginView extends StatelessWidget {
  const ShippingLoginView({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: const Color(0xffF2F7FF),
        body: BlocConsumer<AuthCubit, AuthStates>(
          listener: (context, state) {
            if (state is LoginSuccessState) {
              AppToast.showSuccess(context, S.of(context).loginSuccess);
              ShippingCompanyCubit.get(context).setTab(0);
              if (state.loginResponse.isShippingCompanyAccount == true) {
                context.go(AppRoutes.kShippingCompanyHomeView);
              } else {
                AuthCubit.navigateAfterAuthSuccess(context, state.loginResponse);
              }
            } else if (state is LoginErrorState) {
              if (AuthCubit.isPendingApprovalMessage(state.message)) {
                AuthService.instance.setCompanyWaiting(true);
                context.go(AppRoutes.kUnderReviewView);
                return;
              }
              AppToast.showError(
                context,
                '${S.of(context).loginError}: ${state.message}',
              );
            }
          },
          builder: (context, state) {
            return _ShippingLoginFormBody(
              isLoading: state is LoginLoadingState,
            );
          },
        ),
      ),
    );
  }
}

class _ShippingLoginFormBody extends StatefulWidget {
  const _ShippingLoginFormBody({required this.isLoading});

  final bool isLoading;

  @override
  State<_ShippingLoginFormBody> createState() => _ShippingLoginFormBodyState();
}

class _ShippingLoginFormBodyState extends State<_ShippingLoginFormBody> {
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
    if (!(_formKey.currentState?.validate() ?? false)) return;

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
            const AuthHeader(),
            SizedBox(height: 24.h),
            Center(
              child: SvgPicture.asset(
                AppAssets.servicesIcon5,
                width: 56.w,
                height: 56.w,
                
              ),
            ),
            SizedBox(height: 16.h),
            Text(
              S.of(context).shippingCompanyLogin,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20.sp,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF333333),
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              S.of(context).shippingCompanyLoginSubtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14.sp,
                color: LightColor.greyTextColor,
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
              alignment:
                  isArabic ? Alignment.centerLeft : Alignment.centerRight,
              child: TextButton(
                onPressed: () => context.push(AppRoutes.kForgotPasswordView),
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
                  onPressed: () =>
                      context.push(AppRoutes.kShippingRegisterView),
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
            SizedBox(height: 20.h),
            Center(
              child: TextButton(
                onPressed: () {
                  ShippingCompanyCubit.get(context).setTab(0);
                  context.go(AppRoutes.kShippingCompanyHomeView);
                },
                style: TextButton.styleFrom(
                  foregroundColor: LightColor.defaultColor,
                ),
                child: Text(
                  S.of(context).loginAsGuest,
                  style: TextStyle(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.bold,
                    decoration: TextDecoration.underline,
                    color: LightColor.defaultColor,
                    decorationColor: LightColor.defaultColor,
                  ),
                ),
              ),
            ),
            SizedBox(height: 16.h),
          ],
        ),
      ),
    );
  }
}
