import 'package:alrasmarket/core/theme/app_fonts.dart';
import 'package:alrasmarket/features/company/presentation/controller/cubit/create_ad_cubit.dart';
import 'package:alrasmarket/features/company/presentation/controller/cubit/create_ad_states.dart';
import 'package:alrasmarket/features/company/presentation/widgets/create_ad/create_ad_design.dart';
import 'package:alrasmarket/generated/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class CreateAdPublishButtonWidget extends StatelessWidget {
  const CreateAdPublishButtonWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final fontFamily = AppFonts.familyFor(Localizations.localeOf(context));
    final isAr = Localizations.localeOf(context).languageCode == 'ar';

    return BlocBuilder<CreateAdCubit, CreateAdFormState>(
      buildWhen: (previous, current) =>
          previous.isSubmitting != current.isSubmitting ||
          previous.isCompressingMedia != current.isCompressingMedia,
      builder: (context, state) {
        final busy = state.isSubmitting || state.isCompressingMedia;
        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: busy
                ? null
                : () => context.read<CreateAdCubit>().submitForm(),
            borderRadius: BorderRadius.circular(14.r),
            child: Ink(
              width: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14.r),
                gradient: LinearGradient(
                  colors: busy
                      ? [
                          CreateAdDesign.brand.withValues(alpha: 0.55),
                          CreateAdDesign.brandDark.withValues(alpha: 0.55),
                        ]
                      : const [
                          CreateAdDesign.brand,
                          CreateAdDesign.brandDark,
                        ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: CreateAdDesign.brand.withValues(alpha: 0.28),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                children: [
                  if (!busy)
                    Icon(
                      Icons.send_rounded,
                      color: Colors.white,
                      size: 18.sp,
                    ),
                  if (!busy) SizedBox(width: 10.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (state.isSubmitting)
                          _PublishingLabel(
                            fontFamily: fontFamily,
                            isAr: isAr,
                          )
                        else if (state.isCompressingMedia)
                          Text(
                            isAr
                                ? 'جاري تجهيز الصور والفيديو…'
                                : 'Preparing media…',
                            style: TextStyle(
                              color: Colors.white,
                              fontFamily: fontFamily,
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w800,
                            ),
                          )
                        else
                          Text(
                            S.of(context).publish,
                            style: TextStyle(
                              color: Colors.white,
                              fontFamily: fontFamily,
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        if (!busy) ...[
                          SizedBox(height: 1.h),
                          Text(
                            isAr
                                ? 'راجع التفاصيل ثم انشر إعلانك'
                                : 'Review your details and publish your ad',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontFamily: fontFamily,
                              fontSize: 10.sp,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _PublishingLabel extends StatefulWidget {
  const _PublishingLabel({
    required this.fontFamily,
    required this.isAr,
  });

  final String fontFamily;
  final bool isAr;

  @override
  State<_PublishingLabel> createState() => _PublishingLabelState();
}

class _PublishingLabelState extends State<_PublishingLabel>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final base = widget.isAr ? 'جاري النشر' : 'Publishing';
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final phase = (_controller.value * 3).floor() % 3;
        final dots = '.' * (phase + 1);
        return Text(
          '$base$dots',
          style: TextStyle(
            color: Colors.white,
            fontFamily: widget.fontFamily,
            fontSize: 14.sp,
            fontWeight: FontWeight.w800,
          ),
        );
      },
    );
  }
}
