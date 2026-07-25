import 'package:alrasmarket/core/router/app_router.dart';
import 'package:alrasmarket/core/serveses/auth_service.dart';
import 'package:alrasmarket/core/theme/colors.dart';
import 'package:alrasmarket/core/ui/widgets/feedback/app_toast.dart';
import 'package:alrasmarket/core/utils/assets.dart';
import 'package:alrasmarket/core/widgets/app_header.dart';
import 'package:alrasmarket/core/widgets/costomtextform.dart';
import 'package:alrasmarket/core/widgets/primary_button.dart';
import 'package:alrasmarket/features/auth/presentation/controller/cubit/auth_cubit.dart';
import 'package:alrasmarket/features/auth/presentation/controller/cubit/auth_states.dart';
import 'package:alrasmarket/generated/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';

class ChangePasswordView extends StatefulWidget {
  const ChangePasswordView({super.key});

  @override
  State<ChangePasswordView> createState() => _ChangePasswordViewState();
}

class _ChangePasswordViewState extends State<ChangePasswordView> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordCtrl = TextEditingController();
  final _newPasswordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();

  @override
  void dispose() {
    _currentPasswordCtrl.dispose();
    _newPasswordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final current = _currentPasswordCtrl.text.trim();
    final newPassword = _newPasswordCtrl.text.trim();
    final confirm = _confirmPasswordCtrl.text.trim();

    if (newPassword != confirm) {
      AppToast.showError(context, S.of(context).confirmPasswordMustBeSame);
      return;
    }

    context.read<AuthCubit>().changePassword(
          currentPassword: current,
          newPassword: newPassword,
        );
  }

  @override
  Widget build(BuildContext context) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final isLoading = context.watch<AuthCubit>().state is ChangePasswordLoadingState;

    return BlocListener<AuthCubit, AuthStates>(
      listener: (context, state) {
        if (state is ChangePasswordSuccessState) {
          AppToast.showSuccess(context, state.message);
          Navigator.pop(context);
        } else if (state is ChangePasswordErrorState) {
          AppToast.showError(context, state.message);
        }
      },
      child: SafeArea(
        child: Scaffold(
          body: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              children: [
                SizedBox(height: 20.h),
                AppHeader(),
                SizedBox(height: 20.h),
                Stack(
                  children: [
                    Center(
                      child: Text(
                        S.of(context).changePassword,
                        style: TextStyle(
                          fontSize: 18.sp,
                          color: LightColor.defaultColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: SvgPicture.asset(
                            isAr ? AppAssets.backIconAR : AppAssets.backIconEN,
                            width: 24.w,
                            height: 24.h,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                SizedBox(height: 12.h),
                Expanded(
                  child: SingleChildScrollView(
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          Container(
                            width: 80.w,
                            height: 80.h,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(999.r),
                              color: const Color.fromRGBO(224, 241, 255, 1),
                            ),
                            padding: EdgeInsets.all(20.w),
                            child: SvgPicture.asset(
                              AppAssets.profileLockFillIcon,
                              width: 20.w,
                              height: 20.h,
                            ),
                          ),
                          SizedBox(height: 20.h),
                          CustomTextFormField(
                            controller: _currentPasswordCtrl,
                            label: S.of(context).currentPassword,
                            hintText: S.of(context).enterCurrentPassword,
                            isPassword: true,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return S.of(context).thisFieldIsRequired;
                              }
                              return null;
                            },
                            rightIconColor: LightColor.defaultColor,
                          ),
                          SizedBox(height: 20.h),
                          CustomTextFormField(
                            controller: _newPasswordCtrl,
                            label: S.of(context).newPassword,
                            hintText: S.of(context).enterNewPassword,
                            isPassword: true,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return S.of(context).thisFieldIsRequired;
                              }
                              if (value.trim().length < 6) {
                                return S.of(context).passwordMustBeAtLeast6Characters;
                              }
                              return null;
                            },
                            rightIconColor: LightColor.defaultColor,
                          ),
                          SizedBox(height: 20.h),
                          CustomTextFormField(
                            controller: _confirmPasswordCtrl,
                            height: 56.h,
                            label: S.of(context).confirmNewPassword,
                            hintText: S.of(context).reEnterNewPassword,
                            isPassword: true,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return S.of(context).thisFieldIsRequired;
                              }
                              if (value.trim() != _newPasswordCtrl.text.trim()) {
                                return S.of(context).confirmPasswordMustBeSame;
                              }
                              return null;
                            },
                            rightIconColor: LightColor.defaultColor,
                          ),
                          SizedBox(height: 20.h),
                          PrimaryButton(
                            text: S.of(context).savePassword,
                            onPressed: isLoading ? null : _submit,
                          ),
                          SizedBox(height: 20.h),
                          TextButton(
                            onPressed: () {
                              final email =
                                  AuthService.instance.currentUserEmail ?? '';
                              context.push(
                                AppRoutes.kForgotPasswordView,
                                extra: email,
                              );
                            },
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: Text(
                              S.of(context).forgotPassword,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: LightColor.defaultColor,
                                decoration: TextDecoration.underline,
                                decorationColor: LightColor.defaultColor,
                                fontSize: 15.sp,
                                fontWeight: FontWeight.bold,
                                height: 1.5,
                              ),
                            ),
                          ),
                        ],
                      ),
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
