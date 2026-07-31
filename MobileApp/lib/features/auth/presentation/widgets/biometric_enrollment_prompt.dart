import 'package:alrasmarket/core/services/biometric_auth_service.dart';
import 'package:alrasmarket/core/serveses/auth_service.dart';
import 'package:alrasmarket/core/theme/colors.dart';
import 'package:alrasmarket/core/ui/widgets/feedback/app_toast.dart';
import 'package:alrasmarket/generated/l10n.dart';
import 'package:flutter/material.dart';

/// Offers biometric unlock once after the account's first successful sign-in
/// on this installation. Returns after the user enables it or dismisses it.
Future<void> promptBiometricEnrollmentIfNeeded(BuildContext context) async {
  final bio = BiometricAuthService.instance;
  if (!AuthService.instance.isAuthenticated) return;
  if (bio.isEnabled || bio.wasPromptedForCurrentAccount) return;
  if (!await bio.isDeviceSupported || !await bio.hasEnrolledBiometrics) return;
  if (!context.mounted) return;

  final s = S.of(context);
  final shouldEnable = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) => AlertDialog(
      icon: const Icon(
        Icons.fingerprint_rounded,
        color: LightColor.defaultColor,
        size: 42,
      ),
      title: Text(
        s.enableBiometricUnlock,
        textAlign: TextAlign.center,
      ),
      content: Text(
        s.biometricUnlockSubtitle,
        textAlign: TextAlign.center,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: Text(s.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: Text(s.confirm),
        ),
      ],
    ),
  );

  if (shouldEnable != true) {
    await bio.markCurrentAccountPrompted();
    return;
  }

  if (!context.mounted) return;
  final enabled = await bio.enableForCurrentSession(
    reason: s.biometricEnableReason,
  );
  if (!context.mounted) return;
  if (enabled) {
    await bio.markCurrentAccountPrompted();
    if (!context.mounted) return;
    AppToast.showSuccess(context, s.biometricEnabledSuccess);
  } else {
    AppToast.showError(context, s.biometricUnlockFailed);
  }
}
