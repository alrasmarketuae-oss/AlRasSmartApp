import 'package:alrasmarket/core/theme/colors.dart';
import 'package:alrasmarket/features/ai_assistant/data/ai_assistant_voice_prefs.dart';
import 'package:alrasmarket/features/clint/presentation/widgets/search_header.dart';
import 'package:alrasmarket/generated/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class AiAssistantVoiceSettingsView extends StatefulWidget {
  const AiAssistantVoiceSettingsView({super.key});

  @override
  State<AiAssistantVoiceSettingsView> createState() =>
      _AiAssistantVoiceSettingsViewState();
}

class _AiAssistantVoiceSettingsViewState
    extends State<AiAssistantVoiceSettingsView> {
  bool _male = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final male = await AiAssistantVoicePrefs.isMale();
    if (!mounted) return;
    setState(() {
      _male = male;
      _loading = false;
    });
  }

  Future<void> _select({required bool male}) async {
    setState(() => _male = male);
    await AiAssistantVoicePrefs.setMale(male);
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final isAr = Localizations.localeOf(context).languageCode == 'ar';

    return Scaffold(
      backgroundColor: AppColors.scaffold(context),
      body: Column(
        children: [
          SearchHeader(title: s.aiAssistantVoiceSetting, isSearch: false),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : ListView(
                    padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 24.h),
                    children: [
                      Text(
                        s.aiAssistantVoiceSettingSubtitle,
                        style: TextStyle(
                          fontSize: 13.sp,
                          color: AppColors.subtitle(context),
                          height: 1.4,
                        ),
                      ),
                      SizedBox(height: 16.h),
                      _VoiceOptionCard(
                        selected: !_male,
                        title: isAr ? 'صوت بنت' : 'Female voice',
                        subtitle: isAr
                            ? 'صوت سول — أنثى'
                            : 'Soul voice — female',
                        icon: Icons.record_voice_over_rounded,
                        onTap: () => _select(male: false),
                      ),
                      SizedBox(height: 12.h),
                      _VoiceOptionCard(
                        selected: _male,
                        title: isAr ? 'صوت ولد' : 'Male voice',
                        subtitle: isAr
                            ? 'صوت سول — ذكر'
                            : 'Soul voice — male',
                        icon: Icons.mic_rounded,
                        onTap: () => _select(male: true),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _VoiceOptionCard extends StatelessWidget {
  const _VoiceOptionCard({
    required this.selected,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  final bool selected;
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.card(context),
      borderRadius: BorderRadius.circular(14.r),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14.r),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14.r),
            border: Border.all(
              color: selected
                  ? LightColor.defaultColor
                  : AppColors.border(context),
              width: selected ? 1.6 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: selected
                    ? LightColor.defaultColor
                    : AppColors.subtitle(context),
                size: 26.sp,
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w700,
                        color: AppColors.title(context),
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: AppColors.subtitle(context),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                selected
                    ? Icons.radio_button_checked_rounded
                    : Icons.radio_button_off_rounded,
                color: selected
                    ? LightColor.defaultColor
                    : const Color(0xFFCBD5E1),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
