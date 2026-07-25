import 'dart:async';

import 'package:alrasmarket/core/router/app_router.dart';
import 'package:alrasmarket/core/router/where_to_go.dart';
import 'package:alrasmarket/core/serveses/auth_service.dart';
import 'package:alrasmarket/core/utils/assets.dart';
import 'package:alrasmarket/core/widgets/auth_header.dart';
import 'package:alrasmarket/core/widgets/primary_button.dart';
import 'package:alrasmarket/features/auth/presentation/controller/cubit/auth_cubit.dart';
import 'package:alrasmarket/features/auth/presentation/controller/cubit/auth_states.dart';
import 'package:alrasmarket/generated/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

class UnderReviewView extends StatefulWidget {
  const UnderReviewView({super.key});

  @override
  State<UnderReviewView> createState() => _UnderReviewViewState();
}

class _UnderReviewViewState extends State<UnderReviewView> {
  static const String _supportPhoneDisplay = '+971 50 123 4567';
  static const String _supportPhoneDial = '+971501234567';

  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _startPolling();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      final email = AuthService.instance.currentUserEmail;
      if (email == null || email.isEmpty || !mounted) return;
      context.read<AuthCubit>().checkAccountApprovalStatus(email: email);
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final email = AuthService.instance.currentUserEmail;
      if (email == null || email.isEmpty || !mounted) return;
      context.read<AuthCubit>().checkAccountApprovalStatus(email: email);
    });
  }

  Future<void> _showContactSupportOptions() async {
    final s = S.of(context);
    await showModalBottomSheet<void>(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 20.h),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  s.contactSupport,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF111827),
                  ),
                ),
                SizedBox(height: 16.h),
                ListTile(
                  leading: const Icon(
                    Icons.chat_bubble_outline,
                    color: Color(0xFF3A7DC5),
                  ),
                  title: Text(s.liveChat),
                  subtitle: Text(s.chatWithTheSupportTeamNow),
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    context.push(AppRoutes.kSupportChatView);
                  },
                ),
                ListTile(
                  leading: const Icon(
                    Icons.phone_outlined,
                    color: Color(0xFF619D50),
                  ),
                  title: Text(s.phoneCall),
                  subtitle: const Text(_supportPhoneDisplay),
                  onTap: () async {
                    Navigator.of(sheetContext).pop();
                    await _callSupport();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _callSupport() async {
    final uri = Uri(scheme: 'tel', path: _supportPhoneDial);
    final opened = await launchUrl(uri);
    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open phone dialer.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        body: SafeArea(
          child: BlocListener<AuthCubit, AuthStates>(
            listener: (context, state) {
              if (state is AccountApprovalApprovedState) {
                context.go(
                  whereToGo(),
                );
              }
            },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    SizedBox(height: 16.h),
                    const AuthHeader(),
                    SizedBox(height: 60.h),
                    Image.asset(
                      AppAssets.underReviewImage,
                      width: 120.w,
                      height: 120.h,
                    ),
                    SizedBox(height: 16.h),
                    Text(
                      S.of(context).underReview,
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    SizedBox(height: 16.h),
                    Text(
                      S
                          .of(context)
                          .yourAccountIsUnderReviewWeWillNotifyYouOnceItIsApproved,
                      style: TextStyle(
                        fontSize: 16.sp,
                        color: const Color(0xCC333333),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 24.h),
                    const NotificationCards(),
                    SizedBox(height: 28.h),
                    SizedBox(
                      width: double.infinity,
                      height: 48.h,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF3A7DC5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                        ),
                        onPressed: _showContactSupportOptions,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SvgPicture.asset(
                              AppAssets.headsetIcon,
                              width: 20.w,
                              height: 20.h,
                              colorFilter: const ColorFilter.mode(
                                Colors.white,
                                BlendMode.srcIn,
                              ),
                            ),
                            SizedBox(width: 8.w),
                            Text(
                              S.of(context).contactSupport,
                              style: TextStyle(
                                fontSize: 16.sp,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 16.h),
                    PrimaryButton(
                      text: S.of(context).logout,
                      onPressed: () async {
                        await AuthCubit.get(context).logout();
                        if (!context.mounted) return;
                        context.go(AppRoutes.krecording);
                      },
                      width: double.infinity,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class NotificationCards extends StatelessWidget {
  const NotificationCards({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildNotificationCard(
          title: 'Email Notification',
          subtitle: 'You will receive an email once approved (24-48 hours)',
          backgroundColor: const Color(0xFFE8F5E9),
          iconColor: const Color(0xFF619D50),
          textColor: const Color(0xFF619D50),
        ),
        const SizedBox(height: 16),
        _buildNotificationCard(
          title: 'Push Notification',
          subtitle: 'We are verifying your company information',
          backgroundColor: const Color(0xFFDBEAFF),
          iconColor: const Color(0xFF3A7DC5),
          textColor: const Color(0xFF3A7DC5),
        ),
      ],
    );
  }

  Widget _buildNotificationCard({
    required String title,
    required String subtitle,
    required Color backgroundColor,
    required Color iconColor,
    required Color textColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF333333),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 13, color: textColor),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: iconColor, shape: BoxShape.circle),
            child: const Icon(
              Icons.email_outlined,
              color: Colors.white,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }
}
