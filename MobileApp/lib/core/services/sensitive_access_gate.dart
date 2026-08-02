import 'package:alrasmarket/core/router/app_router.dart';
import 'package:alrasmarket/core/serveses/auth_service.dart';
import 'package:alrasmarket/core/services/api_constants.dart';
import 'package:alrasmarket/core/services/biometric_auth_service.dart';
import 'package:alrasmarket/core/services/dio_helper.dart';
import 'package:alrasmarket/core/theme/app_fonts.dart';
import 'package:alrasmarket/core/ui/widgets/feedback/app_toast.dart';
import 'package:alrasmarket/core/widgets/costomtextform.dart';
import 'package:alrasmarket/generated/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

/// In-memory unlock for sensitive pages (Alras Smart + Balance).
/// Session lasts ~15 minutes per route after a successful check.
class SensitiveAccessGate {
  SensitiveAccessGate._();

  static const Duration _sessionTtl = Duration(minutes: 15);
  static final Map<String, DateTime> _unlockedUntil = {};

  static bool _isUnlocked(String route) {
    final until = _unlockedUntil[route];
    if (until == null) return false;
    if (DateTime.now().isAfter(until)) {
      _unlockedUntil.remove(route);
      return false;
    }
    return true;
  }

  static void _markUnlocked(String route) {
    _unlockedUntil[route] = DateTime.now().add(_sessionTtl);
  }

  /// Shows warning → biometric and/or password, then pushes [route] on success.
  static Future<void> openProtectedRoute(
    BuildContext context, {
    required String route,
  }) async {
    if (AppRoutes.shouldSkipPush(context, route)) return;

    if (_isUnlocked(route)) {
      if (context.mounted) context.push(route);
      return;
    }

    final l10n = S.of(context);
    final isBalance = route == AppRoutes.kSupplierBalanceView;
    final warningTitle = isBalance
        ? l10n.sensitiveAccessBalanceWarningTitle
        : l10n.sensitiveAccessWarningTitle;
    final warningBody = isBalance
        ? l10n.sensitiveAccessBalanceWarningBody
        : l10n.sensitiveAccessWarningBody;

    final proceed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        final fontFamily = AppFonts.familyFor(Localizations.localeOf(ctx));
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
          ),
          title: Text(
            warningTitle,
            style: TextStyle(
              fontFamily: fontFamily,
              fontWeight: FontWeight.bold,
              fontSize: 18.sp,
            ),
          ),
          content: Text(
            warningBody,
            style: TextStyle(
              fontFamily: fontFamily,
              fontSize: 14.sp,
              height: 1.5,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(
                l10n.cancel,
                style: TextStyle(fontFamily: fontFamily),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text(
                l10n.sensitiveAccessContinue,
                style: TextStyle(
                  fontFamily: fontFamily,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (proceed != true || !context.mounted) return;

    final ok = await _verify(context);
    if (!ok || !context.mounted) return;

    _markUnlocked(route);
    context.push(route);
  }

  static Future<bool> _verify(BuildContext context) async {
    final l10n = S.of(context);
    final bio = BiometricAuthService.instance;
    final hasPassword = AuthService.instance.hasPassword == true;

    final bioReady = bio.isEnabled &&
        await bio.isDeviceSupported &&
        await bio.hasEnrolledBiometrics;

    if (bioReady) {
      final bioOk = await bio.authenticate(
        localizedReason: l10n.sensitiveAccessBiometricReason,
      );
      if (bioOk) return true;
    }

    if (!hasPassword) {
      if (context.mounted) {
        AppToast.showError(context, l10n.sensitiveAccessPasswordRequired);
      }
      return false;
    }

    if (!context.mounted) return false;
    final password = await _SensitivePasswordDialog.show(context);
    if (password == null || password.isEmpty) return false;

    if (!context.mounted) return false;
    return _verifyPasswordApi(context, password);
  }

  static Future<bool> _verifyPasswordApi(
    BuildContext context,
    String password,
  ) async {
    final l10n = S.of(context);
    final token = AuthService.instance.currentToken;
    if (token == null || token.isEmpty) {
      if (context.mounted) {
        AppToast.showError(context, l10n.sensitiveAccessVerifyFailed);
      }
      return false;
    }

    try {
      final response = await DioHelper.postData(
        url: ApiConstants.verifyPasswordEndPoint,
        token: token,
        data: {
          'password': password,
          'Password': password,
        },
      );

      if (response?.statusCode == 200 || response?.statusCode == 201) {
        final data = response?.data;
        if (data is Map && data['ok'] == true) return true;
        return true;
      }

      final msg = _extractMessage(response?.data) ??
          l10n.sensitiveAccessVerifyFailed;
      if (context.mounted) AppToast.showError(context, msg);
      return false;
    } catch (_) {
      if (context.mounted) {
        AppToast.showError(context, l10n.sensitiveAccessVerifyFailed);
      }
      return false;
    }
  }

  static String? _extractMessage(dynamic data) {
    if (data is Map) {
      return data['message']?.toString() ?? data['Message']?.toString();
    }
    return null;
  }
}

class _SensitivePasswordDialog extends StatefulWidget {
  const _SensitivePasswordDialog();

  static Future<String?> show(BuildContext context) {
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _SensitivePasswordDialog(),
    );
  }

  @override
  State<_SensitivePasswordDialog> createState() =>
      _SensitivePasswordDialogState();
}

class _SensitivePasswordDialogState extends State<_SensitivePasswordDialog> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState?.validate() != true) return;
    Navigator.of(context).pop(_passwordController.text);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);
    final fontFamily = AppFonts.familyFor(Localizations.localeOf(context));

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
      title: Text(
        l10n.sensitiveAccessVerifyTitle,
        style: TextStyle(
          fontFamily: fontFamily,
          fontWeight: FontWeight.bold,
          fontSize: 18.sp,
        ),
      ),
      content: Form(
        key: _formKey,
        child: CustomTextFormField(
          controller: _passwordController,
          label: l10n.password,
          hintText: l10n.sensitiveAccessPasswordHint,
          isPassword: true,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel, style: TextStyle(fontFamily: fontFamily)),
        ),
        TextButton(
          onPressed: _submit,
          child: Text(
            l10n.sensitiveAccessContinue,
            style: TextStyle(
              fontFamily: fontFamily,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
