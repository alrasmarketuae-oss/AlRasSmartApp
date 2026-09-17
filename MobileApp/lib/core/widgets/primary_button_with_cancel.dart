import 'package:alrasmarket/core/widgets/primary_button.dart';
import 'package:alrasmarket/generated/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Primary submit button. While [isLoading], shows submit (disabled/loading)
/// and a red Cancel button side by side.
class PrimaryButtonWithCancel extends StatelessWidget {
  const PrimaryButtonWithCancel({
    super.key,
    required this.text,
    required this.onPressed,
    this.onCancel,
    this.isLoading = false,
    this.loadingText,
    this.height,
    this.borderRadius = 8,
    this.backgroundColor,
  });

  static const Color cancelRed = Color(0xFFE53935);

  final String text;
  final VoidCallback? onPressed;
  final VoidCallback? onCancel;
  final bool isLoading;
  final String? loadingText;
  final double? height;
  final double borderRadius;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    final buttonHeight = height ?? 48.h;
    final showCancel = isLoading && onCancel != null;

    if (!showCancel) {
      return PrimaryButton(
        text: text,
        loadingText: loadingText,
        isLoading: isLoading,
        onPressed: onPressed,
        height: buttonHeight,
        borderRadius: borderRadius,
        backgroundColor: backgroundColor,
      );
    }

    return Row(
      children: [
        Expanded(
          flex: 3,
          child: PrimaryButton(
            text: text,
            loadingText: loadingText,
            isLoading: true,
            onPressed: null,
            height: buttonHeight,
            borderRadius: borderRadius,
            backgroundColor: backgroundColor,
          ),
        ),
        SizedBox(width: 10.w),
        Expanded(
          flex: 2,
          child: SizedBox(
            height: buttonHeight,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: cancelRed,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(borderRadius.r),
                ),
              ),
              onPressed: onCancel,
              child: Text(
                S.of(context).cancel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  fontFamily:
                      Theme.of(context).textTheme.labelLarge?.fontFamily,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
