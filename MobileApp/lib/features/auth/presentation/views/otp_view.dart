import 'dart:async';
import 'dart:io';

import 'package:alrasmarket/core/serveses/auth_service.dart';
import 'package:alrasmarket/core/theme/colors.dart';
import 'package:alrasmarket/core/widgets/auth_header.dart';
import 'package:alrasmarket/core/widgets/primary_button.dart';
import 'package:alrasmarket/core/router/app_router.dart';
import 'package:alrasmarket/core/ui/widgets/feedback/app_toast.dart';
import 'package:alrasmarket/features/auth/presentation/controller/cubit/auth_cubit.dart';
import 'package:alrasmarket/features/auth/presentation/controller/cubit/auth_states.dart';
import 'package:alrasmarket/features/auth/presentation/widgets/biometric_enrollment_prompt.dart';
import 'package:alrasmarket/generated/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:pinput/pinput.dart';
import 'package:url_launcher/url_launcher.dart';

class OtpVerificationView extends StatefulWidget {
  const OtpVerificationView({
    super.key,
    required this.email,
  });

  final String email;

  @override
  State<OtpVerificationView> createState() => _OtpVerificationViewState();
}

class _OtpVerificationViewState extends State<OtpVerificationView> {
  static const int _resendSeconds = 80;
  late final TextEditingController _otpController;
  Timer? _timer;
  int _secondsLeft = _resendSeconds;

  bool get _isArabic =>
      Localizations.localeOf(context).languageCode.startsWith('ar');

  @override
  void initState() {
    super.initState();
    _otpController = TextEditingController();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _otpController.dispose();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() {
      _secondsLeft = _resendSeconds;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_secondsLeft <= 1) {
        timer.cancel();
        setState(() {
          _secondsLeft = 0;
        });
      } else {
        setState(() {
          _secondsLeft--;
        });
      }
    });
  }

  String _formatTime(int totalSeconds) {
    final minutes = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  void _onConfirm() {
    final otp = _otpController.text.trim();
    if (otp.length != 6 || widget.email.isEmpty) return;
    AuthCubit.get(context).verifyEmailOtp(
      email: widget.email,
      otp: otp,
    );
  }

  void _onResend() {
    if (_secondsLeft != 0) return;
    AuthCubit.get(context).resendEmailOtp(email: widget.email);
    _startTimer();
  }

  Future<void> _onLogout(BuildContext context) async {
    await AuthCubit.get(context).logout();
    if (!context.mounted) return;
    context.go(AppRoutes.kLoginView);
  }

  String get _emailDomain {
    final email = widget.email.trim().toLowerCase();
    final at = email.lastIndexOf('@');
    if (at < 0 || at >= email.length - 1) return '';
    return email.substring(at + 1);
  }

  List<Uri> _emailInboxCandidates() {
    final domain = _emailDomain;
    final candidates = <Uri>[];

    final isGmail = domain == 'gmail.com' || domain == 'googlemail.com';
    final isYahoo = domain == 'yahoo.com' ||
        domain == 'yahoo.co.uk' ||
        domain == 'ymail.com' ||
        domain.endsWith('.yahoo.com');
    final isOutlook = domain == 'outlook.com' ||
        domain == 'hotmail.com' ||
        domain == 'live.com' ||
        domain == 'msn.com' ||
        domain == 'office365.com';
    final isIcloud = domain == 'icloud.com' ||
        domain == 'me.com' ||
        domain == 'mac.com';

    if (isGmail) {
      candidates.add(Uri.parse('googlegmail://'));
      if (Platform.isAndroid) {
        candidates.add(
          Uri.parse(
            'intent://mail.google.com/#Intent;scheme=https;package=com.google.android.gm;end',
          ),
        );
      }
      candidates.add(Uri.parse('https://mail.google.com/mail/u/0/#inbox'));
    } else if (isYahoo) {
      if (Platform.isAndroid) {
        candidates.add(
          Uri.parse(
            'intent://mail.yahoo.com/#Intent;scheme=https;package=com.yahoo.mobile.client.android.mail;end',
          ),
        );
      }
      candidates.add(Uri.parse('https://mail.yahoo.com/'));
    } else if (isOutlook) {
      candidates.add(Uri.parse('ms-outlook://'));
      if (Platform.isAndroid) {
        candidates.add(
          Uri.parse(
            'intent://outlook.live.com/mail/#Intent;scheme=https;package=com.microsoft.office.outlook;end',
          ),
        );
      }
      candidates.add(Uri.parse('https://outlook.live.com/mail/0/inbox'));
    } else if (isIcloud) {
      candidates.add(Uri.parse('message://'));
      candidates.add(Uri.parse('https://www.icloud.com/mail'));
    }

    // Default mail app / any custom domain mailbox on the device.
    if (Platform.isAndroid) {
      candidates.add(
        Uri.parse(
          'intent://#Intent;action=android.intent.action.MAIN;category=android.intent.category.APP_EMAIL;end',
        ),
      );
    }
    if (Platform.isIOS) {
      candidates.add(Uri.parse('message://'));
    }
    candidates.add(Uri(scheme: 'mailto', path: widget.email.trim()));

    return candidates;
  }

  Future<void> _openEmailInbox() async {
    for (final uri in _emailInboxCandidates()) {
      try {
        final opened = await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
        if (opened) return;
      } catch (_) {
        // Try next candidate.
      }
    }

    if (!mounted) return;
    AppToast.showError(
      context,
      _isArabic ? 'تعذر فتح تطبيق البريد' : 'Could not open your email app',
    );
  }

  @override
  Widget build(BuildContext context) {
    final defaultPinTheme = PinTheme(
      width: 72.w,
      height: 72.h,
      textStyle: TextStyle(
        fontSize: 22.sp,
        fontWeight: FontWeight.bold,
        color: const Color(0xFF333333),
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: Colors.transparent),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8.r,
            offset: Offset(0, 3.h),
          ),
        ],
      ),
    );

    return PopScope(
      canPop: false,
      child: SafeArea(
        child: Scaffold(
          backgroundColor: LightColor.background,
          body: BlocConsumer<AuthCubit, AuthStates>(
            listener: (context, state) async {
              if (state is VerifyOtpSuccessState) {
                AppToast.showSuccess(
                  context,
                  _isArabic ? 'تم التحقق بنجاح' : 'Verified successfully',
                );
                await promptBiometricEnrollmentIfNeeded(context);
                if (!context.mounted) return;
                AuthCubit.navigateAfterAuthSuccess(context, state.loginResponse);
              } else if (state is VerifyOtpErrorState) {
                if (AuthCubit.isPendingApprovalMessage(state.message)) {
                  AuthService.instance.setCompanyWaiting(true);
                  context.go(AppRoutes.kUnderReviewView);
                  return;
                }
                AppToast.showError(context, state.message);
              } else if (state is ResendOtpSuccessState) {
                AppToast.showSuccess(
                  context,
                  _isArabic
                      ? 'تم إرسال رمز التحقق إلى بريدك الإلكتروني'
                      : 'Verification code sent to your email',
                );
              } else if (state is ResendOtpErrorState) {
                AppToast.showError(context, state.message);
              }
            },
            builder: (context, state) {
              final isLoading = state is VerifyOtpLoadingState;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(height: 16.h),
                      const AuthHeader(),
                      SizedBox(height: 24.h),
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton.icon(
                                onPressed: () => _onLogout(context),
                                style: TextButton.styleFrom(
                                  padding:
                                      EdgeInsets.symmetric(horizontal: 8.w),
                                  foregroundColor: LightColor.defaultColor,
                                ),
                                icon: Icon(Icons.logout, size: 20.sp),
                                label: Text(
                                  S.of(context).logout,
                                  style: TextStyle(
                                    fontSize: 13.sp,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Text(
                            S.of(context).otpCode,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 20.sp,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF333333),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        _isArabic
                            ? 'أدخل الرمز المرسل إلى بريدك الإلكتروني'
                            : 'Enter the code sent to your email',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13.sp,
                          color: LightColor.greyTextColor,
                        ),
                      ),
                      if (widget.email.trim().isNotEmpty) ...[
                        SizedBox(height: 4.h),
                        Text(
                          widget.email.trim(),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w600,
                            color: LightColor.defaultColor,
                          ),
                        ),
                      ],
                      SizedBox(height: 16.h),
                      OutlinedButton.icon(
                        onPressed: _openEmailInbox,
                        icon: Icon(Icons.mail_outline, size: 20.sp),
                        label: Text(
                          _isArabic
                              ? 'فتح البريد لقراءة الرمز'
                              : 'Open email to get the code',
                          style: TextStyle(
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: LightColor.defaultColor,
                          side: BorderSide(
                            color: LightColor.defaultColor.withOpacity(0.45),
                          ),
                          padding: EdgeInsets.symmetric(vertical: 12.h),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10.r),
                          ),
                        ),
                      ),
                      SizedBox(height: 24.h),
                      AutofillGroup(
                        child: Directionality(
                          textDirection: TextDirection.ltr,
                          child: Pinput(
                            controller: _otpController,
                            length: 6,
                            autofillHints: const [AutofillHints.oneTimeCode],
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            defaultPinTheme: defaultPinTheme,
                            separatorBuilder: (_) => SizedBox(width: 16.w),
                            mainAxisAlignment: MainAxisAlignment.center,
                            focusedPinTheme: defaultPinTheme.copyDecorationWith(
                              border: Border.all(
                                color: LightColor.defaultColor,
                                width: 1.2,
                              ),
                            ),
                            submittedPinTheme: defaultPinTheme,
                            onCompleted: (_) => _onConfirm(),
                            cursor: Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Container(
                                  margin: EdgeInsets.only(bottom: 16.h),
                                  width: 28.w,
                                  height: 2.h,
                                  color: const Color(0xFFCFD6DF),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 14.h),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Text(
                                S.of(context).countdown + ':',
                                style: TextStyle(
                                  fontSize: 12.sp,
                                  color: LightColor.greyTextColor,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              SizedBox(width: 4.w),
                              Text(
                                _formatTime(_secondsLeft),
                                style: TextStyle(
                                  fontSize: 12.sp,
                                  color: LightColor.greyTextColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              SizedBox(width: 6.w),
                              Icon(
                                Icons.access_time,
                                size: 22.sp,
                                color: LightColor.greyTextColor,
                              ),
                              SizedBox(width: 6.w),
                            ],
                          ),
                          TextButton(
                            onPressed: _secondsLeft == 0 ? _onResend : null,
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                            ),
                            child: Text(
                              S.of(context).resendCode,
                              style: TextStyle(
                                fontSize: 12.sp,
                                decoration: TextDecoration.underline,
                                decorationColor: _secondsLeft == 0
                                    ? LightColor.defaultColor
                                    : LightColor.greyTextColor,
                                color: _secondsLeft == 0
                                    ? LightColor.defaultColor
                                    : LightColor.greyTextColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 24.h),
                      PrimaryButton(
                        text: S.of(context).confirm,
                        onPressed: isLoading ? null : _onConfirm,
                        isLoading: isLoading,
                        backgroundColor: LightColor.defaultColor,
                        borderRadius: 10,
                      ),
                      SizedBox(height: 36.h),
                      Center(
                        child: Text(
                          S.of(context).codeValidFor10Minutes,
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: LightColor.greyTextColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
