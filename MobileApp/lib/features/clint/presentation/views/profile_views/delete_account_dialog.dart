import 'package:alrasmarket/core/theme/app_fonts.dart';
import 'package:alrasmarket/core/theme/colors.dart';
import 'package:alrasmarket/core/widgets/costomtextform.dart';
import 'package:alrasmarket/generated/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class DeleteAccountDialog extends StatefulWidget {
  const DeleteAccountDialog({super.key});

  static Future<String?> show(BuildContext context) {
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const DeleteAccountDialog(),
    );
  }

  @override
  State<DeleteAccountDialog> createState() => _DeleteAccountDialogState();
}

class _DeleteAccountDialogState extends State<DeleteAccountDialog> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState?.validate() != true) return;
    Navigator.of(context).pop(_passwordController.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);
    final fontFamily = AppFonts.familyFor(Localizations.localeOf(context));

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
      title: Text(
        l10n.deleteAccount,
        style: TextStyle(
          fontFamily: fontFamily,
          fontWeight: FontWeight.bold,
          fontSize: 18.sp,
          color: LightColor.defultRed,
        ),
      ),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.deleteAccountConfirmMessage,
              style: TextStyle(
                fontFamily: fontFamily,
                fontSize: 14.sp,
                height: 1.5,
                color: const Color(0xFF333333),
              ),
            ),
            SizedBox(height: 16.h),
            CustomTextFormField(
              controller: _passwordController,
              label: l10n.password,
              hintText: l10n.enterPasswordToConfirm,
              isPassword: true,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            l10n.cancel,
            style: TextStyle(fontFamily: fontFamily),
          ),
        ),
        TextButton(
          onPressed: _submit,
          child: Text(
            l10n.deleteAccount,
            style: TextStyle(
              fontFamily: fontFamily,
              color: LightColor.defultRed,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
