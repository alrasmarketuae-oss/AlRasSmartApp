import 'package:alrasmarket/features/company/presentation/controller/cubit/create_ad_states.dart';
import 'package:alrasmarket/features/company/presentation/models/create_ad_publish_step.dart';
import 'package:alrasmarket/features/company/presentation/widgets/create_ad/create_ad_design.dart';
import 'package:alrasmarket/generated/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Blocking overlay that shows real publish stages, then a success state.
class CreateAdPublishProgressOverlay extends StatelessWidget {
  const CreateAdPublishProgressOverlay({
    super.key,
    required this.state,
    required this.onDone,
  });

  final CreateAdFormState state;
  final VoidCallback onDone;

  bool get _isSuccess =>
      !state.isSubmitting &&
      state.submitSuccessMessage != null &&
      state.submitNavigateProductId != null;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final steps = CreateAdPublishStepX.visibleChecklist(
      hasImages: state.publishHasImages,
      hasVideo: state.publishHasVideo,
      hasDocuments: state.publishHasDocuments,
    );

    return Material(
      color: Colors.black.withValues(alpha: 0.45),
      child: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 360.w),
            child: Container(
              margin: EdgeInsets.symmetric(horizontal: 24.w),
              padding: EdgeInsets.fromLTRB(20.w, 22.h, 20.w, 18.h),
              decoration: BoxDecoration(
                color: CreateAdDesign.cardBg,
                borderRadius: BorderRadius.circular(CreateAdDesign.cardRadius),
                border: Border.all(color: CreateAdDesign.border),
                boxShadow: CreateAdDesign.cardShadow,
              ),
              child: _isSuccess
                  ? _SuccessBody(
                      message: state.submitSuccessMessage!,
                      doneLabel: s.publishProgressDone,
                      onDone: onDone,
                    )
                  : _ProgressBody(
                      title: s.publishProgressTitle,
                      pleaseWait: s.publishPleaseWait,
                      steps: steps,
                      current: state.publishStep,
                      videoPercent: state.publishVideoPercent,
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ProgressBody extends StatelessWidget {
  const _ProgressBody({
    required this.title,
    required this.pleaseWait,
    required this.steps,
    required this.current,
    required this.videoPercent,
  });

  final String title;
  final String pleaseWait;
  final List<CreateAdPublishStep> steps;
  final CreateAdPublishStep current;
  final int videoPercent;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final currentIndex = current.isActive ? current.sortIndex : -1;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          title,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 17.sp,
            fontWeight: FontWeight.w700,
            color: CreateAdDesign.text,
          ),
        ),
        SizedBox(height: 16.h),
        ...steps.map((step) {
          final stepIndex = step.sortIndex;
          final done = currentIndex > stepIndex;
          final active = current == step;
          final label = step.label(
            s,
            percent: step == CreateAdPublishStep.preparingVideo
                ? videoPercent
                : null,
          );
          return Padding(
            padding: EdgeInsets.only(bottom: 10.h),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _StepGlyph(done: done, active: active),
                SizedBox(width: 10.w),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 14.sp,
                      height: 1.35,
                      fontWeight: active ? FontWeight.w600 : FontWeight.w500,
                      color: done || active
                          ? CreateAdDesign.text
                          : CreateAdDesign.muted,
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
        SizedBox(height: 8.h),
        Text(
          pleaseWait,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12.sp,
            height: 1.4,
            color: CreateAdDesign.muted,
          ),
        ),
      ],
    );
  }
}

class _SuccessBody extends StatelessWidget {
  const _SuccessBody({
    required this.message,
    required this.doneLabel,
    required this.onDone,
  });

  final String message;
  final String doneLabel;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.check_circle_rounded,
          color: const Color(0xFF16A34A),
          size: 48.sp,
        ),
        SizedBox(height: 12.h),
        Text(
          message,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 15.sp,
            height: 1.45,
            fontWeight: FontWeight.w600,
            color: CreateAdDesign.text,
          ),
        ),
        SizedBox(height: 18.h),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: onDone,
            style: ElevatedButton.styleFrom(
              backgroundColor: CreateAdDesign.brand,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: EdgeInsets.symmetric(vertical: 12.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(CreateAdDesign.fieldRadius),
              ),
            ),
            child: Text(
              doneLabel,
              style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ],
    );
  }
}

class _StepGlyph extends StatelessWidget {
  const _StepGlyph({required this.done, required this.active});

  final bool done;
  final bool active;

  @override
  Widget build(BuildContext context) {
    if (done) {
      return Icon(
        Icons.check_circle,
        size: 20.sp,
        color: const Color(0xFF16A34A),
      );
    }
    if (active) {
      return SizedBox(
        width: 20.w,
        height: 20.w,
        child: Padding(
          padding: EdgeInsets.all(2.w),
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: CreateAdDesign.brand,
          ),
        ),
      );
    }
    return Icon(
      Icons.radio_button_unchecked,
      size: 20.sp,
      color: CreateAdDesign.muted,
    );
  }
}
