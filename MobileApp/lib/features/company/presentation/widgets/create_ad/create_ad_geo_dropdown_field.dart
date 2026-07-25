import 'package:alrasmarket/core/theme/app_fonts.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class CreateAdGeoDropdownField extends StatelessWidget {
  const CreateAdGeoDropdownField({
    super.key,
    required this.label,
    required this.hint,
    required this.items,
    required this.selectedValue,
    required this.onChanged,
    this.validator,
    this.isLoading = false,
    this.enabled = true,
    this.expandHeight = false,
  });

  final String label;
  final String hint;
  final List<String> items;
  final String? selectedValue;
  final String? Function(String?)? validator;
  final ValueChanged<String?> onChanged;
  final bool isLoading;
  final bool enabled;
  final bool expandHeight;

  @override
  Widget build(BuildContext context) {
    final fontFamily = AppFonts.familyFor(Localizations.localeOf(context));
    final fieldTextStyle = TextStyle(
      color: const Color(0xFF333333).withValues(alpha: 0.8),
      fontFamily: fontFamily,
      fontSize: 13.sp,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          label,
          style: TextStyle(
            color: const Color(0xFF333333),
            fontFamily: fontFamily,
            fontSize: 12.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 6.h),
        expandHeight
            ? Expanded(child: _buildDropdown(context, fieldTextStyle))
            : _buildDropdown(context, fieldTextStyle),
      ],
    );
  }

  Widget _buildDropdown(BuildContext context, TextStyle fieldTextStyle) {
    return DropdownButtonFormField<String>(
      value: items.contains(selectedValue) ? selectedValue : null,
      hint: Text(isLoading ? 'Loading...' : hint, style: fieldTextStyle),
      icon: isLoading
          ? SizedBox(
              width: 16.w,
              height: 16.h,
              child: const CircularProgressIndicator(strokeWidth: 2),
            )
          : Icon(
              Icons.keyboard_arrow_down_rounded,
              color: const Color(0xFF6B7280),
              size: 20.sp,
            ),
      dropdownColor: Colors.white,
      isExpanded: true,
      isDense: true,
      style: fieldTextStyle,
      menuMaxHeight: 320.h,
      validator: validator,
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white,
        isDense: true,
        contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.r),
          borderSide: const BorderSide(color: Color(0xFFEAECF0), width: 1.2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.r),
          borderSide: const BorderSide(color: Color(0xFF3A7DC5), width: 1.2),
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
      items: items
          .map(
            (value) => DropdownMenuItem<String>(
              value: value,
              child: Text(value, style: fieldTextStyle),
            ),
          )
          .toList(),
      onChanged: enabled && !isLoading ? onChanged : null,
    );
  }
}
