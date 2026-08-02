import 'package:alrasmarket/core/services/biometric_auth_service.dart';
import 'package:alrasmarket/core/theme/colors.dart';
import 'package:alrasmarket/core/ui/widgets/feedback/app_toast.dart';
import 'package:alrasmarket/features/auth/presentation/controller/cubit/auth_cubit.dart';
import 'package:alrasmarket/generated/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Shown only when a previous account enabled Face ID / fingerprint unlock.
class BiometricUnlockButton extends StatefulWidget {
  /// [circular] renders the round fingerprint badge used on the login screen,
  /// otherwise the full-width outlined button is used.
  const BiometricUnlockButton({super.key, this.circular = false});

  final bool circular;

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

    if (!mounted) return;
    AuthCubit.navigateAfterBiometricUnlock(context);
  }

  @override
  Widget build(BuildContext context) {
    if (!_visible) return const SizedBox.shrink();

    if (widget.circular) return _buildCircular(context);

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

  Widget _buildCircular(BuildContext context) {
    return Column(
      children: [
        InkWell(
          onTap: _busy ? null : _unlock,
          customBorder: const CircleBorder(),
          child: Container(
            width: 54.w,
            height: 54.w,
            decoration: const BoxDecoration(
              color: Color(0xFFE7F0FB),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: _busy
                  ? SizedBox(
                      width: 20.w,
                      height: 20.w,
                      child: const CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(
                      Icons.fingerprint_rounded,
                      size: 28.sp,
                      color: const Color(0xFF2E77CC),
                    ),
            ),
          ),
        ),
        SizedBox(height: 10.h),
        Text(
          S.of(context).signInWithBiometrics,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13.sp,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF2E77CC),
          ),
        ),
        SizedBox(height: 14.h),
      ],
    );
  }
}
