import 'package:alrasmarket/core/router/app_router.dart';
import 'package:alrasmarket/core/theme/colors.dart';
import 'package:alrasmarket/core/utils/assets.dart';
import 'package:alrasmarket/core/widgets/language_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

class AuthHeader extends StatelessWidget {
  final bool isRecording;
  /// Shows a locale-aware back control (← EN, → AR).
  final bool showBack;
  final VoidCallback? onBack;

  const AuthHeader({
    super.key,
    this.isRecording = false,
    this.showBack = false,
    this.onBack,
  });

  void _handleBack(BuildContext context) {
    if (onBack != null) {
      onBack!();
      return;
    }
    if (context.canPop()) {
      context.pop();
      return;
    }
    context.go(AppRoutes.krecording);
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    return Row(
      children: [
        if (showBack) ...[
          IconButton(
            onPressed: () => _handleBack(context),
            padding: EdgeInsets.zero,
            constraints: BoxConstraints.tightFor(width: 36.w, height: 36.w),
            tooltip: MaterialLocalizations.of(context).backButtonTooltip,
            icon: Icon(
              // Keep visual start-side stable; flip arrow with app language.
              isArabic
                  ? Icons.arrow_forward_rounded
                  : Icons.arrow_back_rounded,
              size: 22.sp,
              color: AppColors.title(context),
            ),
          ),
          SizedBox(width: 4.w),
        ],
        const LanguageButton(),
        const Spacer(),
        if (!isRecording)
          Image.asset(AppAssets.logo, width: 52.w, height: 42.h),
      ],
    );
  }
}
