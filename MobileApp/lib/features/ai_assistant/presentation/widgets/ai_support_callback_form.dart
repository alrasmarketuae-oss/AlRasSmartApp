import 'package:alrasmarket/core/serveses/auth_service.dart';
import 'package:alrasmarket/core/services/api_constants.dart';
import 'package:alrasmarket/core/services/dio_helper.dart';
import 'package:alrasmarket/core/theme/colors.dart';
import 'package:alrasmarket/core/utils/dio_user_facing_message.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Collects name / phone / email so human tech support can call within 5 minutes.
class AiSupportCallbackForm extends StatefulWidget {
  const AiSupportCallbackForm({
    super.key,
    this.question,
    this.sessionId,
    this.onSubmitted,
  });

  final String? question;
  final String? sessionId;
  final VoidCallback? onSubmitted;

  @override
  State<AiSupportCallbackForm> createState() => _AiSupportCallbackFormState();
}

class _AiSupportCallbackFormState extends State<AiSupportCallbackForm> {
  late final TextEditingController _name;
  late final TextEditingController _phone;
  late final TextEditingController _email;
  bool _submitting = false;
  bool _done = false;
  String? _error;
  String? _success;

  @override
  void initState() {
    super.initState();
    final auth = AuthService.instance;
    _name = TextEditingController(text: auth.currentUserName?.trim() ?? '');
    _phone = TextEditingController(text: auth.currentUserPhone?.trim() ?? '');
    _email = TextEditingController(text: auth.currentUserEmail?.trim() ?? '');
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _email.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_submitting || _done) return;
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final fullName = _name.text.trim();
    final phone = _phone.text.trim();
    final email = _email.text.trim();

    if (fullName.length < 2 || phone.length < 6 || !email.contains('@')) {
      setState(() {
        _error = isAr
            ? 'من فضلك أدخل الاسم ورقم التليفون والبريد الإلكتروني بشكل صحيح.'
            : 'Please enter a valid name, phone number, and email.';
      });
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      final response = await DioHelper.postData(
        url: ApiConstants.supportCallbacksEndPoint,
        data: {
          'fullName': fullName,
          'phone': phone,
          'email': email,
          if ((widget.question ?? '').trim().isNotEmpty)
            'question': widget.question!.trim(),
          'language': isAr ? 'ar' : 'en',
          'source': 'ai_assistant',
          if ((widget.sessionId ?? '').trim().isNotEmpty)
            'aiConversationId': widget.sessionId!.trim(),
        },
      );

      final data = response?.data;
      final message = data is Map
          ? (data['message']?.toString() ?? data['Message']?.toString())
          : null;

      if (!mounted) return;
      setState(() {
        _submitting = false;
        _done = true;
        _success = message?.trim().isNotEmpty == true
            ? message!.trim()
            : (isAr
                ? 'تم استلام بياناتك. فريق الدعم الفني هيتواصل معاك خلال خمس دقايق.'
                : 'Got your details. Technical support will call you within five minutes.');
      });
      widget.onSubmitted?.call();
    } on DioException catch (e) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _error = DioUserFacingMessage.fromDio(e, isAr: isAr);
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _error = DioUserFacingMessage.highDemand(isAr: isAr);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';

    if (_done) {
      return Container(
        width: double.infinity,
        margin: EdgeInsets.only(top: 8.h),
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
          color: const Color(0xFFDCFAE6),
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: const Color(0xFF17B26A)),
        ),
        child: Text(
          _success ?? '',
          style: TextStyle(
            color: const Color(0xFF067647),
            fontSize: 13.sp,
            fontWeight: FontWeight.w600,
            height: 1.4,
          ),
        ),
      );
    }

    InputDecoration deco(String label) => InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: AppColors.subtitle(context)),
          isDense: true,
          filled: true,
          fillColor: AppColors.inputFill(context),
          contentPadding:
              EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.r)),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10.r),
            borderSide: BorderSide(color: AppColors.border(context)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10.r),
            borderSide: const BorderSide(color: LightColor.defaultColor),
          ),
        );

    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(top: 8.h),
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: LightColor.defaultColor.withValues(alpha: 0.35),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            isAr
                ? 'بيانات التواصل مع الدعم الفني'
                : 'Technical support contact details',
            style: TextStyle(
              fontSize: 13.sp,
              fontWeight: FontWeight.w700,
              color: LightColor.defaultColor,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            isAr
                ? 'هيتم الاتصال بيك خلال خمس دقايق بعد الإرسال.'
                : 'You will be called within five minutes after submitting.',
            style: TextStyle(fontSize: 11.sp, color: AppColors.subtitle(context)),
          ),
          SizedBox(height: 10.h),
          TextField(
            controller: _name,
            textInputAction: TextInputAction.next,
            textAlign: isAr ? TextAlign.right : TextAlign.left,
            keyboardAppearance: AppColors.isDark(context)
                ? Brightness.dark
                : Brightness.light,
            style: TextStyle(
              inherit: false,
              fontFamily: Theme.of(context).textTheme.bodyLarge?.fontFamily,
              color: AppColors.title(context),
              fontSize: 14.sp,
              height: 1.35,
            ),
            cursorColor: LightColor.defaultColor,
            decoration: deco(isAr ? 'الاسم' : 'Name'),
          ),
          SizedBox(height: 8.h),
          // Keep phone LTR so digits/+ are not mirrored in Arabic UI.
          Directionality(
            textDirection: TextDirection.ltr,
            child: TextField(
              controller: _phone,
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.next,
              textAlign: TextAlign.left,
              keyboardAppearance: AppColors.isDark(context)
                  ? Brightness.dark
                  : Brightness.light,
              style: TextStyle(
                inherit: false,
                fontFamily: Theme.of(context).textTheme.bodyLarge?.fontFamily,
                color: AppColors.title(context),
                fontSize: 14.sp,
                height: 1.35,
              ),
              cursorColor: LightColor.defaultColor,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[\d+\s\-()]')),
              ],
              decoration: deco(isAr ? 'رقم التليفون' : 'Phone'),
            ),
          ),
          SizedBox(height: 8.h),
          Directionality(
            textDirection: TextDirection.ltr,
            child: TextField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.done,
              textAlign: TextAlign.left,
              keyboardAppearance: AppColors.isDark(context)
                  ? Brightness.dark
                  : Brightness.light,
              style: TextStyle(
                inherit: false,
                fontFamily: Theme.of(context).textTheme.bodyLarge?.fontFamily,
                color: AppColors.title(context),
                fontSize: 14.sp,
                height: 1.35,
              ),
              cursorColor: LightColor.defaultColor,
              onSubmitted: (_) => _submit(),
              decoration: deco(isAr ? 'البريد الإلكتروني' : 'Email'),
            ),
          ),
          if (_error != null) ...[
            SizedBox(height: 8.h),
            Text(
              _error!,
              style: TextStyle(color: Colors.red.shade700, fontSize: 12.sp),
            ),
          ],
          SizedBox(height: 10.h),
          ElevatedButton(
            onPressed: _submitting ? null : _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: LightColor.defaultColor,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(vertical: 12.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.r),
              ),
            ),
            child: _submitting
                ? SizedBox(
                    width: 18.w,
                    height: 18.w,
                    child: const CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    isAr ? 'إرسال وطلب اتصال' : 'Submit & request a call',
                    style: TextStyle(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
