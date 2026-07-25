import 'package:alrasmarket/core/theme/colors.dart';
import 'package:alrasmarket/features/auth/presentation/controller/cubit/auth_cubit.dart';
import 'package:alrasmarket/features/auth/presentation/controller/cubit/auth_states.dart';
import 'package:alrasmarket/features/clint/presentation/widgets/search_header.dart';
import 'package:alrasmarket/generated/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class LanguageScreen extends StatelessWidget {
  const LanguageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthStates>(
      buildWhen: (_, current) => current is ChangeLocaleState,
      builder: (context, state) {
        final authCubit = AuthCubit.get(context);
        final selectedCode = authCubit.locale.languageCode;

        return Scaffold(
          body: Column(
            children: [
              SearchHeader(title: S.of(context).languageTitle),
              SizedBox(height: 12.h),
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(horizontal: 24.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _LanguageOptionCard(
                        label: "عربي",
                        flagEmoji: '🇦🇪',
                        isSelected: selectedCode == 'ar',
                        onTap: () => authCubit.setLocaleTo('ar'),
                      ),
                      SizedBox(height: 20.h),
                      _LanguageOptionCard(
                        label:"English",
                        flagEmoji: '🇬🇧',
                        isSelected: selectedCode == 'en',
                        onTap: () => authCubit.setLocaleTo('en'),
                      ),
                      SizedBox(height: 20.h),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 16.w,
                          vertical: 16.h,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE0F1FF),
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        child: Text(
                          S.of(context).languagePreferenceHint,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                fontSize: 14.sp,
                                color: LightColor.greyTextColor,
                                height: 1.5,
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

class _LanguageOptionCard extends StatelessWidget {
  const _LanguageOptionCard({
    required this.label,
    required this.flagEmoji,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final String flagEmoji;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8.r),
        child: Ink(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8.r),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 2,
                offset: Offset.zero,
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
            child: Row(
              children: [
                Text(flagEmoji, style: TextStyle(fontSize: 24.sp)),
                SizedBox(width: 8.w),
                Expanded(
                  child: Text(
                    label,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontSize: 14.sp,
                          color: const Color(0xFF333333),
                          height: 1.5,
                        ),
                  ),
                ),
                Icon(
                  isSelected
                      ? Icons.radio_button_checked
                      : Icons.radio_button_off,
                  color: isSelected
                      ? LightColor.defaultColor
                      : LightColor.grey,
                  size: 24.sp,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
