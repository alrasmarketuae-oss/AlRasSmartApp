import 'package:alrasmarket/generated/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:alrasmarket/core/theme/colors.dart';
import 'package:alrasmarket/core/ui/widgets/feedback/app_loading.dart';
import 'package:alrasmarket/core/utils/assets.dart';
import 'package:alrasmarket/core/widgets/back_buttom.dart';
import 'package:alrasmarket/core/widgets/costomtextform.dart';
import 'package:alrasmarket/core/widgets/message_service.dart';
import 'package:go_router/go_router.dart';
import '../../controller/cubit/auth_cubit.dart';
import '../../controller/cubit/auth_states.dart';

class CheckEmailScreen extends StatefulWidget {
  const CheckEmailScreen({super.key, this.initialEmail = ''});

  final String initialEmail;

  @override
  State<CheckEmailScreen> createState() => _CheckEmailScreenState();
}

class _CheckEmailScreenState extends State<CheckEmailScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController emailCtrl;

  /// Real email used for the API when the field is locked/masked.
  late final String _actualEmail;
  late final bool _emailLocked;

  @override
  void initState() {
    super.initState();
    _actualEmail = widget.initialEmail.trim();
    _emailLocked = _actualEmail.isNotEmpty;
    emailCtrl = TextEditingController(
      text: _emailLocked ? _maskEmailKeepFirstThree(_actualEmail) : '',
    );
  }

  /// Shows first 3 characters; the rest are asterisks.
  static String _maskEmailKeepFirstThree(String email) {
    if (email.length <= 3) return email;
    return '${email.substring(0, 3)}${'*' * (email.length - 3)}';
  }

  String get _emailForSubmit =>
      _emailLocked ? _actualEmail : emailCtrl.text.trim();

  @override
  void dispose() {
    emailCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthCubit, AuthStates>(
      listener: (context, state) {
        if (state is ForgetPasswordSuccessState) {
          MessageService().showSuccessSnackBarAlert(
            message: state.message,
            context: context,
          );
          context.push(
            '/ResetPasswordView',
            extra: _emailForSubmit,
          );
        }
        if (state is ForgetPasswordErrorState) {
          MessageService().snackBarAlert(
            message: state.message,
            context: context,
          );
        }
      },
      builder: (context, state) {
        final s = S.of(context);
        return Scaffold(
          backgroundColor: LightColor.background,
          body: Stack(
            children: [
              SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 25.w),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 250.h),
                      Align(
                        alignment: Alignment.center,
                        child: Padding(
                          padding: EdgeInsets.only(top: 50.0.h),
                          child: GestureDetector(
                            onTap: () {},
                            child: SvgPicture.asset(
                              AppAssets.emailIcon,
                              width: 60.w,
                              height: 60.h,
                              color: LightColor.defaultColor,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 20.h),
                      Align(
                        alignment: Alignment.center,
                        child: RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: 'Check your ',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 24.sp,
                                  color: Colors.black,
                                ),
                              ),
                              TextSpan(
                                text: 'Email',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 24.sp,
                                  color: LightColor.defaultColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: 50.h),
                      BackButtonWidget(),
                      SizedBox(height: 20.h),
                      const Text(
                        'Email',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      SizedBox(height: 8.h),
                      CustomTextFormField(
                        controller: emailCtrl,
                        hintText: s.enterYourEmail,
                        enabled: !_emailLocked,
                        keyboardType: TextInputType.emailAddress,
                        fillColor: _emailLocked
                            ? const Color(0xFFF2F4F7)
                            : null,
                        validator: (v) {
                          if (_emailLocked) return null;
                          if (v == null || v.trim().isEmpty) {
                            return s.emailIsRequired;
                          }
                          return null;
                        },
                        hintStyle: const TextStyle(color: Colors.grey),
                      ),
                      SizedBox(height: 24.h),
                      SizedBox(
                        width: double.infinity,
                        height: 48.h,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: LightColor.defaultColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                          ),
                          onPressed: () {
                            if (_emailLocked ||
                                (_formKey.currentState?.validate() ?? false)) {
                              AuthCubit.get(context).forgotPassword(
                                email: _emailForSubmit,
                              );
                            }
                          },
                          child: (state is ForgetPasswordLoadingState)
                              ? AppLoading()
                              : Text(
                                  'check',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16.sp,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
