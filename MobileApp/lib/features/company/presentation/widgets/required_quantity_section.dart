import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:alrasmarket/core/theme/app_fonts.dart';
import 'package:alrasmarket/generated/l10n.dart';

class RequiredQuantitySection extends StatelessWidget {
  const RequiredQuantitySection({
    super.key,
    required this.controller,
    required this.label,
  });

  final TextEditingController controller;
  final String label;

  @override
  Widget build(BuildContext context) {
    final fontFamily = AppFonts.familyFor(Localizations.localeOf(context));
    final fieldTextStyle = TextStyle(
      color: const Color(0xFF333333),
      fontFamily: fontFamily,
      fontSize: 14.sp,
      height: 1.5,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(
            color: const Color(0xFF333333),
            fontFamily: fontFamily,
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
            height: 1.5,
          ),
        ),
        SizedBox(height: 8.h),
        TextFormField(
          controller: controller,
          keyboardType: TextInputType.number,
          style: fieldTextStyle,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            hintText: S.of(context).quantity,
            hintStyle: TextStyle(
              color: const Color(0xFF333333).withOpacity(0.5),
              fontFamily: fontFamily,
              fontSize: 14.sp,
            ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: 16.w,
              vertical: 16.h,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.r),
              borderSide: const BorderSide(color: Color(0xFFEAECF0), width: 1.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.r),
              borderSide: const BorderSide(color: Color(0xFF3A7DC5), width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.r),
              borderSide: BorderSide(color: Colors.red.shade400, width: 1.5),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.r),
              borderSide: BorderSide(color: Colors.red.shade400, width: 1.5),
            ),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return S.of(context).thisFieldIsRequired;
            }
            return null;
          },
        ),
      ],
    );
  }
}
