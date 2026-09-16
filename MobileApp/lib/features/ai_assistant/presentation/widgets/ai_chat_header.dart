import 'package:alrasmarket/core/theme/colors.dart';
import 'package:alrasmarket/features/ai_assistant/presentation/models/ai_voice_gender.dart';
import 'package:alrasmarket/features/ai_assistant/presentation/theme/ai_chat_colors.dart';
import 'package:alrasmarket/features/ai_assistant/presentation/widgets/ai_ad_plan_form.dart';
import 'package:alrasmarket/features/ai_assistant/presentation/widgets/ai_message_bubble.dart';
import 'package:alrasmarket/generated/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

class AiChatHeader extends StatelessWidget {
  const AiChatHeader({
    super.key,
    this.planMode = false,
    this.onCancelPlan,
    this.onOpenHistory,
    this.historyLoading = false,
    this.onOpenVoiceSettings,
    this.voiceGender = AiVoiceGender.female,
    this.voiceConversationMode = false,
  });

  final bool planMode;
  final VoidCallback? onCancelPlan;
  final VoidCallback? onOpenHistory;
  final bool historyLoading;
  final VoidCallback? onOpenVoiceSettings;
  final AiVoiceGender voiceGender;
  final bool voiceConversationMode;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final topInset = MediaQuery.paddingOf(context).top;
    final gradient = planMode
        ? const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFE6A817), Color(0xFFF0D48A)],
          )
        : aiGradient;

    return Container(
      padding: EdgeInsets.fromLTRB(12.w, topInset + 10.h, 16.w, 16.h),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(24.r)),
        boxShadow: [
          BoxShadow(
            color: (planMode ? AiAdPlanColors.accent : LightColor.defaultColor)
                .withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (context.canPop())
                IconButton(
                  onPressed: () => context.pop(),
                  padding: EdgeInsets.zero,
                  constraints: BoxConstraints.tightFor(
                    width: 36.w,
                    height: 36.w,
                  ),
                  icon: Icon(
                    Icons.arrow_back_ios_new_rounded,
                    size: 18.sp,
                    color: Colors.white,
                  ),
                ),
              SizedBox(width: 4.w),
              const AiAvatar(size: 40, onDark: true),
              SizedBox(width: 10.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: AlignmentDirectional.centerStart,
                      child: Text(
                        planMode
                            ? (isAr ? 'وضع الخطة' : 'Plan mode')
                            : s.aiAssistantTitle,
                        maxLines: 1,
                        softWrap: false,
                        style: TextStyle(
                          fontSize: 15.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    SizedBox(height: 3.h),
                    Row(
                      children: [
                        Container(
                          width: 7.w,
                          height: 7.w,
                          decoration: BoxDecoration(
                            color: planMode
                                ? const Color(0xFFFFF8E7)
                                : const Color(0xFF6EE7A8),
                            shape: BoxShape.circle,
                          ),
                        ),
                        SizedBox(width: 6.w),
                        Text(
                          planMode
                              ? (isAr ? 'إنشاء إعلان' : 'Create ad')
                              : s.aiAssistantFabLabel,
                          style: TextStyle(
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w600,
                            color: Colors.white.withValues(alpha: 0.9),
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (onOpenHistory != null)
                historyLoading
                    ? Padding(
                        padding: EdgeInsetsDirectional.only(end: 8.w),
                        child: SizedBox(
                          width: 22.w,
                          height: 22.w,
                          child: const CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        ),
                      )
                    : IconButton(
                        onPressed: onOpenHistory,
                        icon: Icon(
                          Icons.history_rounded,
                          color: Colors.white,
                          size: 22.sp,
                        ),
                      ),
              if (onOpenVoiceSettings != null)
                IconButton(
                  onPressed: onOpenVoiceSettings,
                  tooltip: voiceConversationMode
                      ? (isAr ? 'محادثة صوتية شغّالة' : 'Voice conversation on')
                      : (isAr ? 'المحادثة الصوتية' : 'Voice conversation'),
                  icon: Icon(
                    voiceConversationMode
                        ? Icons.headset_mic_rounded
                        : (voiceGender == AiVoiceGender.female
                            ? Icons.record_voice_over_rounded
                            : Icons.mic_rounded),
                    color: voiceConversationMode
                        ? const Color(0xFFFFF176)
                        : Colors.white,
                    size: 21.sp,
                  ),
                ),
              if (onCancelPlan != null)
                TextButton(
                  onPressed: onCancelPlan,
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: 8.w),
                    minimumSize: Size(0, 32.h),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    isAr ? 'إلغاء' : 'Cancel',
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: 12.h),
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 9.h),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Row(
              children: [
                Icon(
                  planMode ? Icons.route_rounded : Icons.auto_awesome_rounded,
                  size: 14.sp,
                  color: Colors.white,
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: Text(
                    planMode
                        ? (isAr
                            ? 'قولّي البيانات اللي عندك — ولو نسيت حاجة هذكّرك بيها.'
                            : 'Tell me what you have — if something is missing, I will list it.')
                        : s.aiAssistantSubtitle,
                    style: TextStyle(
                      fontSize: 10.sp,
                      height: 1.35,
                      fontWeight: FontWeight.w500,
                      color: Colors.white.withValues(alpha: 0.92),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
