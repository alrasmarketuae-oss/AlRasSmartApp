import 'package:alrasmarket/core/theme/colors.dart';
import 'package:alrasmarket/core/ui/widgets/feedback/app_loading.dart';
import 'package:alrasmarket/core/widgets/back_buttom.dart';
import 'package:alrasmarket/core/widgets/costomtextform.dart';
import 'package:alrasmarket/core/widgets/message_service.dart';
import 'package:alrasmarket/core/widgets/primary_button.dart';
import 'package:alrasmarket/features/auth/presentation/controller/cubit/auth_cubit.dart';
import 'package:alrasmarket/features/auth/presentation/controller/cubit/auth_states.dart';
import 'package:alrasmarket/generated/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key, required this.email});

  final String email;

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  @override
  void dispose() {
    _codeController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    AuthCubit.get(context).resetPassword(
      email: widget.email.trim(),
      code: _codeController.text.trim(),
      newPassword: _passwordController.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthCubit, AuthStates>(
      listener: (context, state) {
        if (state is ResetPasswordSuccessState) {
          MessageService().showSuccessSnackBarAlert(
            message: state.message,
            context: context,
          );
          context.go('/LoginView');
        }
        if (state is ResetPasswordErrorState) {
          MessageService().snackBarAlert(
            message: state.message,
            context: context,
          );
        }
      },
      builder: (context, state) {
        final isLoading = state is ResetPasswordLoadingState;
        final s = S.of(context);
        return Scaffold(
          backgroundColor: LightColor.background,
          body: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 25.w),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 80.h),
                  BackButtonWidget(),
                  SizedBox(height: 24.h),
                  Text(
                    'Reset password',
                    style: TextStyle(
                      fontSize: 24.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    'Enter the code sent to ${widget.email}',
                    style: TextStyle(fontSize: 14.sp, color: Colors.grey),
                  ),
                  SizedBox(height: 24.h),
                  CustomTextFormField(
                    controller: _codeController,
                    label: s.otpCode,
                    hintText: s.otpCode,
                    keyboardType: TextInputType.number,
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? s.thisFieldIsRequired : null,
                  ),
                  SizedBox(height: 16.h),
                  CustomTextFormField(
                    controller: _passwordController,
                    label: s.newPassword,
                    hintText: s.enterNewPassword,
                    isPassword: true,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return s.thisFieldIsRequired;
                      }
                      if (v.length < 6) {
                        return s.passwordMustBeAtLeast6Characters;
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 16.h),
                  CustomTextFormField(
                    controller: _confirmController,
                    label: s.confirmNewPassword,
                    hintText: s.reEnterNewPassword,
                    isPassword: true,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return s.confirmPasswordIsRequired;
                      }
                      if (v != _passwordController.text) {
                        return s.confirmPasswordMustBeSame;
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 32.h),
                  SizedBox(
                    width: double.infinity,
                    height: 48.h,
                    child: isLoading
                        ? const Center(child: AppLoading())
                        : PrimaryButton(
                            text: 'Reset password',
                            onPressed: _submit,
                            backgroundColor: LightColor.defaultColor,
                          ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
