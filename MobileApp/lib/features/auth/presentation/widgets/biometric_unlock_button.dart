import 'package:alrasmarket/core/serveses/app_chat_listener_service.dart';
import 'package:alrasmarket/core/services/biometric_auth_service.dart';
import 'package:alrasmarket/core/theme/colors.dart';
import 'package:alrasmarket/core/ui/widgets/feedback/app_toast.dart';
import 'package:alrasmarket/features/auth/presentation/controller/cubit/auth_cubit.dart';
import 'package:alrasmarket/generated/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Shown only when a previous account enabled Face ID / fingerprint unlock.
class BiometricUnlockButton extends StatefulWidget {
  const BiometricUnlockButton({super.key});

  @override
  State<BiometricUnlockButton> createState() => _BiometricUnlockButtonState();
}

class _BiometricUnlockButtonState extends State<BiometricUnlockButton> {
  bool _visible = false;
  bool _busy = false;
  String _label = '';

  @override
  void initState() {
    super.initState();
    _prepare();
  }

  Future<void> _prepare() async {
    final bio = BiometricAuthService.instance;
    final canOffer = await bio.canOfferUnlock;
    if (!mounted) return;
    if (!canOffer) {
      setState(() => _visible = false);
      return;
    }

    final s = S.of(context);
    final label = await bio.preferredLabel(
      faceId: s.unlockWithFaceId,
      fingerprint: s.unlockWithFingerprint,
      generic: s.unlockWithBiometrics,
    );
    if (!mounted) return;
    setState(() {
      _visible = true;
      _label = label;
    });
  }

  Future<void> _unlock() async {
    if (_busy) return;
    setState(() => _busy = true);
    final s = S.of(context);
    final ok = await BiometricAuthService.instance.unlockAndRestoreSession(
      reason: s.biometricAuthReason,
    );
    if (!mounted) return;
    setState(() => _busy = false);

    if (!ok) {
      AppToast.showError(context, s.biometricUnlockFailed);
      return;
    }

    await AppChatListenerService.instance.start();
    if (!mounted) return;
    AuthCubit.navigateAfterBiometricUnlock(context);
  }

  @override
  Widget build(BuildContext context) {
    if (!_visible) return const SizedBox.shrink();

    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 48.h,
          child: OutlinedButton.icon(
            onPressed: _busy ? null : _unlock,
            icon: _busy
                ? SizedBox(
                    width: 18.w,
                    height: 18.w,
                    child: const CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(
                    Icons.fingerprint_rounded,
                    color: LightColor.defaultColor,
                    size: 22.sp,
                  ),
            label: Text(
              _label,
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w700,
                color: LightColor.defaultColor,
              ),
            ),
            style: OutlinedButton.styleFrom(
              side: BorderSide(
                color: LightColor.defaultColor.withValues(alpha: 0.45),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
            ),
          ),
        ),
        SizedBox(height: 12.h),
      ],
    );
  }
}
