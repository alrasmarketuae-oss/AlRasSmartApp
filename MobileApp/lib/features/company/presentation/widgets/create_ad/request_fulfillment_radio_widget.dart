import 'package:alrasmarket/core/theme/app_fonts.dart';
import 'package:alrasmarket/features/company/presentation/models/request_fulfillment_type.dart';
import 'package:alrasmarket/features/company/presentation/widgets/create_ad/create_ad_design.dart';
import 'package:alrasmarket/generated/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class RequestFulfillmentRadioWidget extends StatelessWidget {
  const RequestFulfillmentRadioWidget({
    super.key,
    required this.selectedType,
    required this.onChanged,
  });

  final RequestFulfillmentType? selectedType;
  final ValueChanged<RequestFulfillmentType> onChanged;

  @override
  Widget build(BuildContext context) {
    final fontFamily = AppFonts.familyFor(Localizations.localeOf(context));
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final s = S.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const CreateAdFieldIcon(Icons.show_chart_rounded),
            SizedBox(width: 10.w),
            Expanded(
              child: CreateAdRequiredLabel(
                s.requestFulfillment,
                fontFamily: fontFamily,
              ),
            ),
          ],
        ),
        SizedBox(height: 8.h),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                children: [
                  _Option(
                    label: s.requestFulfillmentLocal,
                    value: RequestFulfillmentType.local,
                    groupValue: selectedType,
                    onChanged: onChanged,
                    fontFamily: fontFamily,
                  ),
                  SizedBox(height: 4.h),
                  _Option(
                    label: s.requestFulfillmentReexport,
                    value: RequestFulfillmentType.reexport,
                    groupValue: selectedType,
                    onChanged: onChanged,
                    fontFamily: fontFamily,
                  ),
                ],
              ),
            ),
            SizedBox(width: 10.w),
            Container(
              width: 120.w,
              padding: EdgeInsets.all(10.w),
              decoration: BoxDecoration(
                color: CreateAdDesign.iconBg,
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(
                  color: CreateAdDesign.brand.withValues(alpha: 0.25),
                ),
              ),
              child: Text(
                isAr
                    ? 'اختر الأنسب لعملك'
                    : 'Choose the best option for your business.',
                style: TextStyle(
                  fontFamily: fontFamily,
                  fontSize: 11.sp,
                  color: CreateAdDesign.brandDark,
                  height: 1.35,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _Option extends StatelessWidget {
  const _Option({
    required this.label,
    required this.value,
    required this.groupValue,
    required this.onChanged,
    required this.fontFamily,
  });

  final String label;
  final RequestFulfillmentType value;
  final RequestFulfillmentType? groupValue;
  final ValueChanged<RequestFulfillmentType> onChanged;
  final String fontFamily;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onChanged(value),
      child: Row(
        children: [
          Radio<RequestFulfillmentType>(
            value: value,
            groupValue: groupValue,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            visualDensity: VisualDensity.compact,
            onChanged: (newValue) {
              if (newValue != null) onChanged(newValue);
            },
            activeColor: CreateAdDesign.brand,
          ),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: CreateAdDesign.text,
                fontFamily: fontFamily,
                fontSize: 15.sp,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
