import 'package:alrasmarket/core/services/api_constants.dart';
import 'package:alrasmarket/core/services/dio_helper.dart';
import 'package:alrasmarket/core/theme/colors.dart';
import 'package:alrasmarket/core/ui/widgets/feedback/app_toast.dart';
import 'package:alrasmarket/core/widgets/costomtextform.dart';
import 'package:alrasmarket/core/widgets/primary_button.dart';
import 'package:alrasmarket/features/clint/presentation/widgets/search_header.dart';
import 'package:alrasmarket/generated/l10n.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

class ComplaintsSuggestionsView extends StatefulWidget {
  const ComplaintsSuggestionsView({
    super.key,
    this.initialType = 'Complaint',
    this.initialSubject,
    this.initialMessage,
    this.initialOrderReference,
  });

  final String initialType;
  final String? initialSubject;
  final String? initialMessage;
  final String? initialOrderReference;

  @override
  State<ComplaintsSuggestionsView> createState() =>
      _ComplaintsSuggestionsViewState();
}

class _ComplaintsSuggestionsViewState extends State<ComplaintsSuggestionsView> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _subjectCtrl;
  late final TextEditingController _messageCtrl;
  late final TextEditingController _orderRefCtrl;
  late String _type;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _type = widget.initialType == 'Suggestion' ? 'Suggestion' : 'Complaint';
    _subjectCtrl = TextEditingController(text: widget.initialSubject ?? '');
    _messageCtrl = TextEditingController(text: widget.initialMessage ?? '');
    _orderRefCtrl =
        TextEditingController(text: widget.initialOrderReference ?? '');
  }

  @override
  void dispose() {
    _subjectCtrl.dispose();
    _messageCtrl.dispose();
    _orderRefCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_submitting) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    setState(() => _submitting = true);

    try {
      final response = await DioHelper.postData(
        url: ApiConstants.userFeedbackEndPoint,
        data: {
          'type': _type,
          'subject': _subjectCtrl.text.trim(),
          'message': _messageCtrl.text.trim(),
          if (_orderRefCtrl.text.trim().isNotEmpty)
            'orderReference': _orderRefCtrl.text.trim(),
          'language': isAr ? 'ar' : 'en',
          'source': 'profile',
        },
      );

      final data = response?.data;
      final message = data is Map
          ? (data['message']?.toString() ?? data['Message']?.toString())
          : null;

      if (!mounted) return;
      AppToast.showSuccess(
        context,
        message?.trim().isNotEmpty == true
            ? message!.trim()
            : S.of(context).feedbackSubmittedSuccess,
      );
      context.pop();
    } on DioException catch (e) {
      final raw = e.response?.data;
      String? msg;
      if (raw is Map) {
        msg = raw['message']?.toString() ?? raw['Message']?.toString();
      } else if (raw is String && raw.trim().isNotEmpty) {
        msg = raw.trim();
      }
      if (!mounted) return;
      AppToast.showError(
        context,
        msg?.trim().isNotEmpty == true
            ? msg!.trim()
            : S.of(context).feedbackSubmittedError,
      );
    } catch (_) {
      if (!mounted) return;
      AppToast.showError(context, S.of(context).feedbackSubmittedError);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final isAr = Localizations.localeOf(context).languageCode == 'ar';

    return SafeArea(
      child: Scaffold(
        backgroundColor: const Color(0xFFF4F7FA),
        body: Column(
          children: [
            SearchHeader(
              title: s.complaintsSuggestions,
              isSearch: false,
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(24.w, 8.h, 24.w, 16.h),
                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        s.complaintsSuggestionsHint,
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: const Color(0xFF6B7280),
                          height: 1.5,
                        ),
                      ),
                      SizedBox(height: 20.h),
                      Text(
                        s.feedbackTypeLabel,
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                          color: LightColor.defaultColor,
                        ),
                      ),
                      SizedBox(height: 10.h),
                      Row(
                        children: [
                          Expanded(
                            child: _TypeChip(
                              label: s.feedbackTypeComplaint,
                              selected: _type == 'Complaint',
                              onTap: () => setState(() => _type = 'Complaint'),
                            ),
                          ),
                          SizedBox(width: 10.w),
                          Expanded(
                            child: _TypeChip(
                              label: s.feedbackTypeSuggestion,
                              selected: _type == 'Suggestion',
                              onTap: () => setState(() => _type = 'Suggestion'),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 20.h),
                      CustomTextFormField(
                        controller: _subjectCtrl,
                        hintText: s.feedbackSubjectHint,
                        label: s.feedbackSubjectLabel,
                        validator: (value) {
                          final text = value?.trim() ?? '';
                          if (text.length < 3) {
                            return isAr
                                ? 'الموضوع قصير جداً'
                                : 'Subject is too short';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 16.h),
                      CustomTextFormField(
                        controller: _messageCtrl,
                        hintText: s.feedbackMessageHint,
                        label: s.feedbackMessageLabel,
                        maxLines: 6,
                        height: 140.h,
                        validator: (value) {
                          final text = value?.trim() ?? '';
                          if (text.length < 10) {
                            return isAr
                                ? 'الرسالة قصيرة جداً'
                                : 'Message is too short';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 16.h),
                      CustomTextFormField(
                        controller: _orderRefCtrl,
                        hintText: s.feedbackOrderRefHint,
                        label: s.feedbackOrderRefLabel,
                        addOptionalLabel: true,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        bottomNavigationBar: Padding(
          padding: EdgeInsets.fromLTRB(24.w, 8.h, 24.w, 16.h),
          child: PrimaryButton(
            text: s.submitFeedback,
            isLoading: _submitting,
            onPressed: _submitting ? null : _submit,
          ),
        ),
      ),
    );
  }
}

class _TypeChip extends StatelessWidget {
  const _TypeChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: EdgeInsets.symmetric(vertical: 12.h),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF3B7FC7) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? const Color(0xFF3B7FC7) : const Color(0xFFE5E7EB),
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : const Color(0xFF374151),
            fontWeight: FontWeight.w600,
            fontSize: 14.sp,
          ),
        ),
      ),
    );
  }
}
