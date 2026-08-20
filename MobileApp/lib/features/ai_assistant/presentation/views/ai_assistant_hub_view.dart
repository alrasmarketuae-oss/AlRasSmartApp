import 'package:alrasmarket/core/router/app_router.dart';
import 'package:alrasmarket/core/theme/colors.dart';
import 'package:alrasmarket/core/utils/assets.dart';
import 'package:alrasmarket/features/clint/presentation/widgets/search_header.dart';
import 'package:alrasmarket/generated/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

class AiAssistantHubView extends StatelessWidget {
  const AiAssistantHubView({super.key});

  static const _titleBlue = Color(0xFF163A6B);
  static const _bodyBlue = Color(0xFF3A6AA5);
  static const _purple = Color(0xFF7B61FF);
  static const _green = Color(0xFF2BB673);

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final rtl = Directionality.of(context) == TextDirection.rtl;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          SearchHeader(title: s.aiAssistantTitle, isSearch: false),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(20.w, 8.h, 20.w, 24.h),
              child: Column(
                children: [
                  SizedBox(height: 8.h),
                  Container(
                    width: 108.w,
                    height: 108.w,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF3A7DC5).withValues(alpha: 0.16),
                          blurRadius: 18,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Image.asset(
                      AppAssets.aiAgentIcon,
                      fit: BoxFit.cover,
                    ),
                  ),
                  SizedBox(height: 16.h),
                  Text(
                    s.aiAssistantTitle,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 26.sp,
                      fontWeight: FontWeight.w800,
                      color: _titleBlue,
                      height: 1.15,
                    ),
                  ),
                  SizedBox(height: 6.h),
                  Text(
                    s.aiAssistantHubSubtitle,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF8A97AB),
                    ),
                  ),
                  SizedBox(height: 22.h),
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.fromLTRB(14.w, 14.h, 16.w, 14.h),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEAF3FF),
                      borderRadius: BorderRadius.circular(18.r),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 36.w,
                          height: 36.w,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.auto_awesome_rounded,
                            color: _purple,
                            size: 18.sp,
                          ),
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                s.aiAssistantHubHello,
                                style: TextStyle(
                                  fontSize: 15.sp,
                                  fontWeight: FontWeight.w800,
                                  color: _titleBlue,
                                  height: 1.3,
                                ),
                              ),
                              SizedBox(height: 4.h),
                              Text(
                                s.aiAssistantHubIntro,
                                style: TextStyle(
                                  fontSize: 12.5.sp,
                                  fontWeight: FontWeight.w500,
                                  color: _bodyBlue,
                                  height: 1.45,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 28.h),
                  Text(
                    s.aiAssistantHowToStart,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF334155),
                    ),
                  ),
                  SizedBox(height: 14.h),
                  _HubActionCard(
                    borderColor: const Color(0xFFD9D1FF),
                    iconColor: _purple,
                    icon: Icons.chat_bubble_outline_rounded,
                    title: s.aiAssistantChatWithAi,
                    subtitle: s.aiAssistantChatWithAiSubtitle,
                    rtl: rtl,
                    onTap: () => context.push(AppRoutes.kAiAssistantChatView),
                  ),
                  SizedBox(height: 12.h),
                  _HubActionCard(
                    borderColor: const Color(0xFFC8EEDB),
                    iconColor: _green,
                    icon: Icons.phone_in_talk_outlined,
                    title: s.aiAssistantTalkWithAi,
                    subtitle: s.aiAssistantTalkWithAiSubtitle,
                    rtl: rtl,
                    onTap: () => context.push(
                      AppRoutes.kAiAssistantChatView,
                      extra: {'voice': true},
                    ),
                  ),
                  SizedBox(height: 36.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.verified_user_rounded,
                        size: 16.sp,
                        color: LightColor.defaultColor,
                      ),
                      SizedBox(width: 6.w),
                      Text(
                        s.dataSafeTitle,
                        style: TextStyle(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w600,
                          color: LightColor.defaultColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HubActionCard extends StatelessWidget {
  const _HubActionCard({
    required this.borderColor,
    required this.iconColor,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.rtl,
    required this.onTap,
  });

  final Color borderColor;
  final Color iconColor;
  final IconData icon;
  final String title;
  final String subtitle;
  final bool rtl;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18.r),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18.r),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.fromLTRB(14.w, 14.h, 12.w, 14.h),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18.r),
            border: Border.all(color: borderColor),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(icon, color: iconColor, size: 28.sp),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF163A6B),
                      ),
                    ),
                    SizedBox(height: 3.h),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF8A97AB),
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 8.w),
              Container(
                width: 32.w,
                height: 32.w,
                decoration: BoxDecoration(
                  color: iconColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  rtl ? Icons.chevron_left_rounded : Icons.chevron_right_rounded,
                  color: Colors.white,
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
