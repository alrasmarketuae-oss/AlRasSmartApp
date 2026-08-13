import 'package:alrasmarket/core/serveses/auth_service.dart';
import 'package:alrasmarket/core/theme/app_fonts.dart';
import 'package:alrasmarket/features/company/presentation/models/create_ad_type.dart';
import 'package:alrasmarket/generated/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class CreateAdTypeSelectionField extends StatelessWidget {
  const CreateAdTypeSelectionField({
    super.key,
    required this.selectedType,
    required this.onChanged,
  });

  final String? selectedType;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final fontFamily = AppFonts.familyFor(Localizations.localeOf(context));
    final fieldTextStyle = TextStyle(
      color: const Color(0xFF333333).withValues(alpha: 0.8),
      fontFamily: fontFamily,
      fontSize: 13.sp,
    );
    final isUae = AuthService.instance.isUaePhoneNumber;
    final typeLabels = CreateAdType.labelsForCompany(isUaePhone: isUae);
    final effectiveSelected =
        selectedType != null && typeLabels.contains(selectedType)
            ? selectedType
            : (typeLabels.length == 1 ? typeLabels.first : null);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          S.of(context).selection,
          style: TextStyle(
            color: const Color(0xFF333333),
            fontFamily: fontFamily,
            fontSize: 12.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 6.h),
        DropdownButtonFormField<String>(
          value: effectiveSelected,
          hint: Text(S.of(context).selectAnOption, style: fieldTextStyle),
          icon: Icon(
            Icons.keyboard_arrow_down_rounded,
            color: const Color(0xFF6B7280),
            size: 20.sp,
          ),
          dropdownColor: Colors.white,
          style: fieldTextStyle,
          isDense: true,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            isDense: true,
            contentPadding: EdgeInsets.symmetric(
              horizontal: 12.w,
              vertical: 10.h,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10.r),
              borderSide: const BorderSide(
                color: Color(0xFFEAECF0),
                width: 1.2,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10.r),
              borderSide: const BorderSide(
                color: Color(0xFF3A7DC5),
                width: 1.2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10.r),
              borderSide: BorderSide(color: Colors.red.shade400, width: 1.2),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10.r),
              borderSide: BorderSide(color: Colors.red.shade400, width: 1.2),
            ),
          ),
          items: typeLabels
              .map(
                (value) => DropdownMenuItem<String>(
                  value: value,
                  child: Text(
                    CreateAdType.localizedDisplayLabel(value, S.of(context)),
                    style: fieldTextStyle,
                  ),
                ),
              )
              .toList(),
          selectedItemBuilder: (context) => typeLabels
              .map(
                (value) => Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Text(
                    CreateAdType.localizedDisplayLabel(value, S.of(context)),
                    style: fieldTextStyle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              )
              .toList(),
          onChanged: typeLabels.length == 1 ? null : onChanged,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return S.of(context).selectAnOption;
            }
            if (!isUae && value != CreateAdType.booking.label) {
              return S.of(context).selectAnOption;
            }
            return null;
          },
        ),
      ],
    );
  }
}
