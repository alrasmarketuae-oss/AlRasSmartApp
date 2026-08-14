import 'package:alrasmarket/core/router/app_router.dart';
import 'package:alrasmarket/core/services/sensitive_access_gate.dart';
import 'package:alrasmarket/core/utils/assets.dart';
import 'package:alrasmarket/features/auth/presentation/controller/cubit/auth_cubit.dart';
import 'package:alrasmarket/features/auth/presentation/controller/cubit/auth_states.dart';
import 'package:alrasmarket/features/clint/presentation/widgets/call.dart';
import 'package:alrasmarket/features/clint/presentation/widgets/search_header.dart';
import 'package:alrasmarket/generated/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

class TechnicalSupportView extends StatelessWidget {
  const TechnicalSupportView({super.key});

  static const String _supportPhoneDisplay = '+971 4 228 5598';
  static const String _supportPhoneTel = '+97142285598';
  static const String _supportEmail = 'support@alrasmarketapp.com';

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthStates>(
      buildWhen: (_, current) => current is ChangeLocaleState,
      builder: (context, state) {
        return Scaffold(
          body: Column(
            children: [
              SearchHeader(title: S.of(context).helpSupport),
              SizedBox(height: 12.h),
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(horizontal: 24.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildTechnicalSupportWidget(context),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFFE5E7EB),
                            width: 0.8,
                          ),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              children: [
                                SvgPicture.asset(
                                  AppAssets.clockIcon,
                                  width: 20,
                                  height: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  S.of(context).workingHours,
                                  style: TextStyle(
                                    color: Color(0xFF333333),
                                    fontFamily: 'Inter',
                                    fontSize: 16,
                                    height: 1.5,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  S.of(context).saturdayThursday,
                                  style: TextStyle(
                                    color: Color(0xFF6B7280),
                                    fontFamily: 'Inter',
                                    fontSize: 14,
                                  ),
                                ),
                                Text(
                                  '8:00 AM - 8:00 PM',
                                  style: TextStyle(
                                    color: Color(0xFF333333),
                                    fontFamily: 'Inter',
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  S.of(context).friday,
                                  style: TextStyle(
                                    color: Color(0xFF6B7280),
                                    fontFamily: 'Inter',
                                    fontSize: 14,
                                  ),
                                ),
                                Text(
                                  S.of(context).closed,
                                  style: TextStyle(
                                    color: Color(0xFF333333),
                                    fontFamily: 'Inter',
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      CallCard(
                        icon: AppAssets.profileHelpSupportIcon,
                        title: S.of(context).complaintsSuggestions,
                        subtitle: S.of(context).complaintsSuggestionsSubtitle,
                        buttonText: S.of(context).submitFeedback,
                        onTap: () =>
                            context.push(AppRoutes.kComplaintsSuggestionsView),
                      ),
                      const SizedBox(height: 12),
                      CallCard(
                        icon: AppAssets.profileMessageIcon,
                        title: S.of(context).liveChat,
                        subtitle: S.of(context).chatWithTheSupportTeamNow,
                        buttonText: S.of(context).startChat,
                        onTap: () => context.push(AppRoutes.kSupportChatView),
                      ),
                      const SizedBox(height: 12),
                      CallCard(
                        icon: AppAssets.profileHelpSupportIcon,
                        title: S.of(context).aiAssistantTitle,
                        subtitle: S.of(context).aiAssistantSubtitle,
                        buttonText: S.of(context).aiAssistantFabLabel,
                        onTap: () => SensitiveAccessGate.openProtectedRoute(
                          context,
                          route: AppRoutes.kAiAssistantView,
                        ),
                      ),
                      const SizedBox(height: 12),
                      CallCard(
                        icon: AppAssets.profilePrivacyPolicyIcon,
                        title: S.of(context).modelTrainingTitle,
                        subtitle: S.of(context).modelTrainingTitle,
                        buttonText: S.of(context).gotIt,
                        onTap: () => context.push(AppRoutes.kModelTrainingView),
                      ),
                      const SizedBox(height: 12),
                      CallCard(
                        icon: AppAssets.profilePhoneIcon,
                        title: S.of(context).phoneCall,
                        subtitle: _supportPhoneDisplay,
                        buttonText: S.of(context).callNow,
                        onTap: () => _launchSupportPhone(context),
                      ),
                      const SizedBox(height: 12),
                      CallCard(
                        icon: AppAssets.profileMail1Icon,
                        title: S.of(context).email,
                        subtitle: _supportEmail,
                        buttonText: S.of(context).sendEmail,
                        onTap: () => _launchSupportEmail(context),
                      ),
                      const SizedBox(height: 12),
                      _buildFrequentlyAskedQuestionsWidget(context),
                      const SizedBox(height: 12),
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

  Future<void> _launchSupportPhone(BuildContext context) async {
    final uri = Uri(scheme: 'tel', path: _supportPhoneTel);
    final opened = await launchUrl(uri);
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open phone dialer.')),
      );
    }
  }

  Future<void> _launchSupportEmail(BuildContext context) async {
    final uri = Uri.parse('mailto:$_supportEmail');
    final opened = await launchUrl(uri);
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open email app.')),
      );
    }
  }
}

Widget _buildTechnicalSupportWidget(BuildContext context) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 62, vertical: 16),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(12),
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFF0066CC),
          Color(0xFFD0091E),
        ],
      ),
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withOpacity(0.2),
          ),
          child: SizedBox(
            width: 32,
            height: 32,
            child: Center(
              child: SvgPicture.asset(
                AppAssets.profileMicIcon,
                semanticsLabel: 'vector',
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          S.of(context).howCanWeHelpYou,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white,
            fontFamily: 'Inter',
            fontSize: 18,
            fontWeight: FontWeight.normal,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          S.of(context).theSupportTeamIsAlwaysHereToAssistYou,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white,
            fontFamily: 'Inter',
            fontSize: 14,
            fontWeight: FontWeight.normal,
            height: 1.5,
          ),
        ),
      ],
    ),
  );
}

Widget _buildFrequentlyAskedQuestionsWidget(BuildContext context) {
  final s = S.of(context);

  return Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(8),
      boxShadow: [
        BoxShadow(
          color: const Color(0xFF323232).withOpacity(0.15),
          offset: Offset.zero,
          blurRadius: 2,
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          s.frequentlyAskedQuestions,
          style: TextStyle(
            color: Color(0xFF333333),
            fontFamily: 'Inter',
            fontSize: 16,
            fontWeight: FontWeight.w600,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 8),
        _FaqItem(
          question: s.howCanIPlaceAnOrder,
          answer: s.howCanIPlaceAnOrderAnswer,
        ),
        const Divider(color: Color(0xFFE5E7EB), thickness: 1),
        _FaqItem(
          question: s.whatPaymentMethodsAreAvailable,
          answer: s.whatPaymentMethodsAreAvailableAnswer,
        ),
        const Divider(color: Color(0xFFE5E7EB), thickness: 1),
        _FaqItem(
          question: s.howDoITrackMyOrder,
          answer: s.howDoITrackMyOrderAnswer,
        ),
      ],
    ),
  );
}

class _FaqItem extends StatelessWidget {
  const _FaqItem({
    required this.question,
    required this.answer,
  });

  final String question;
  final String answer;

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        childrenPadding: const EdgeInsets.only(bottom: 12),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        iconColor: const Color(0xFF6B7280),
        collapsedIconColor: const Color(0xFF6B7280),
        title: Text(
          question,
          style: const TextStyle(
            color: Color(0xFF6B7280),
            fontFamily: 'Inter',
            fontSize: 14,
            height: 1.5,
          ),
        ),
        children: [
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: Text(
              answer,
              style: const TextStyle(
                color: Color(0xFF333333),
                fontFamily: 'Inter',
                fontSize: 14,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
