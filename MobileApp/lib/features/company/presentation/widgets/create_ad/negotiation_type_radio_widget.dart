import 'package:alrasmarket/core/theme/app_fonts.dart';
import 'package:alrasmarket/features/company/presentation/models/negotiation_type.dart';
import 'package:alrasmarket/features/company/presentation/widgets/create_ad/create_ad_design.dart';
import 'package:alrasmarket/generated/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class NegotiationTypeRadioWidget extends StatelessWidget {
  const NegotiationTypeRadioWidget({
    super.key,
    required this.selectedType,
    required this.onChanged,
    this.fromBuyer = false,
  });

  final NegotiationType selectedType;
  final ValueChanged<NegotiationType> onChanged;
  final bool fromBuyer;

  @override
  Widget build(BuildContext context) {
    final fontFamily = AppFonts.familyFor(Localizations.localeOf(context));
    final isAr = Localizations.localeOf(context).languageCode == 'ar';

    if (fromBuyer) {
      return _legacyBuyerRow(
        context: context,
        fontFamily: fontFamily,
      );
    }

    return Row(
      children: [
        Expanded(
          child: _NegotiationCard(
            title: S.of(context).negotiable,
            subtitle: isAr
                ? 'يمكن التفاوض على السعر'
                : 'Price can be negotiated',
            icon: Icons.handshake_outlined,
            selected: selectedType == NegotiationType.negotiable,
            onTap: () => onChanged(NegotiationType.negotiable),
            fontFamily: fontFamily,
          ),
        ),
        SizedBox(width: 10.w),
        Expanded(
          child: _NegotiationCard(
            title: S.of(context).nonNegotiable,
            subtitle: isAr ? 'سعر ثابت فقط' : 'Fixed price only',
            icon: Icons.lock_outline_rounded,
            selected: selectedType == NegotiationType.nonNegotiable,
            onTap: () => onChanged(NegotiationType.nonNegotiable),
            fontFamily: fontFamily,
          ),
        ),
      ],
    );
  }

  Widget _legacyBuyerRow({
    required BuildContext context,
    required String fontFamily,
  }) {
    final optionTextStyle = TextStyle(
      color: const Color(0xCC333333),
      fontFamily: fontFamily,
      fontSize: 14.sp,
      height: 1.5,
    );
    return Row(
      children: [
        Expanded(
          child: Row(
            children: [
              Radio<NegotiationType>(
                value: NegotiationType.negotiable,
                groupValue: selectedType,
                onChanged: (v) {
                  if (v != null) onChanged(v);
                },
                activeColor: CreateAdDesign.brand,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              ),
              Expanded(
                child: Text(S.of(context).negotiable, style: optionTextStyle),
              ),
            ],
          ),
        ),
        SizedBox(width: 8.w),
        Expanded(
          child: Row(
            children: [
              Radio<NegotiationType>(
                value: NegotiationType.nonNegotiable,
                groupValue: selectedType,
                onChanged: (v) {
                  if (v != null) onChanged(v);
                },
                activeColor: CreateAdDesign.brand,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              ),
              Expanded(
                child: Text(
                  S.of(context).nonNegotiable,
                  style: optionTextStyle.copyWith(fontSize: 11.sp),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _NegotiationCard extends StatelessWidget {
  const _NegotiationCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.selected,
    required this.onTap,
    required this.fontFamily,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  final String fontFamily;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12.r),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 10.h),
          decoration: BoxDecoration(
            color: selected
                ? CreateAdDesign.brand.withValues(alpha: 0.08)
                : Colors.white,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(
              color: selected ? CreateAdDesign.brand : CreateAdDesign.border,
              width: selected ? 1.6 : 1.1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    icon,
                    size: 17.sp,
                    color: selected
                        ? CreateAdDesign.brand
                        : CreateAdDesign.muted,
                  ),
                  const Spacer(),
                  if (selected)
                    Icon(
                      Icons.check_circle_rounded,
                      size: 16.sp,
                      color: CreateAdDesign.brand,
                    ),
                ],
              ),
              SizedBox(height: 6.h),
              Text(
                title,
                style: TextStyle(
                  fontFamily: fontFamily,
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w700,
                  color: CreateAdDesign.text,
                ),
              ),
              SizedBox(height: 2.h),
              Text(
                subtitle,
                style: TextStyle(
                  fontFamily: fontFamily,
                  fontSize: 10.sp,
                  color: CreateAdDesign.muted,
                  height: 1.25,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
