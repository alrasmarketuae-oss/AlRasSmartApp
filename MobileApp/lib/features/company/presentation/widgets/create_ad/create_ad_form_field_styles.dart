import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class CreateAdFormFieldStyles {
  CreateAdFormFieldStyles._();

  /// Shared height for price / currency / unit row fields.
  static double get rowFieldHeight => 44.h;

  static EdgeInsets get fieldContentPadding =>
      EdgeInsets.symmetric(horizontal: 10.w);

  static EdgeInsets get rowFieldContentPadding =>
      EdgeInsets.symmetric(horizontal: 10.w, vertical: 10.h);

  static Widget buildRowDropdown(Widget child) {
    return SizedBox(
      height: rowFieldHeight,
      width: double.infinity,
      child: child,
    );
  }

  static Widget buildRowTextFormField({
    required TextEditingController controller,
    required TextStyle style,
    required String? hintText,
    required String fontFamily,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return SizedBox(
      height: rowFieldHeight,
      width: double.infinity,
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        // Single-line only: expands + maxLines:null draws typed text above the
        // border (especially in RTL / ScreenUtil layouts).
        maxLines: 1,
        textAlignVertical: TextAlignVertical.center,
        style: style,
        decoration: rowDecoration(
          hintText: hintText,
          fontFamily: fontFamily,
        ),
        validator: validator,
      ),
    );
  }

  static InputDecoration decoration({
    required String? hintText,
    required String fontFamily,
  }) {
    return InputDecoration(
      filled: true,
      fillColor: Colors.white,
      hintText: hintText,
      hintStyle: TextStyle(
        color: const Color(0xFF333333).withOpacity(0.5),
        fontFamily: fontFamily,
        fontSize: 13.sp,
      ),
      contentPadding: rowFieldContentPadding,
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
    );
  }

  static InputDecoration rowDecoration({
    required String? hintText,
    required String fontFamily,
  }) {
    return InputDecoration(
      filled: true,
      fillColor: Colors.white,
      isDense: true,
      hintText: hintText,
      hintStyle: TextStyle(
        color: const Color(0xFF333333).withOpacity(0.5),
        fontFamily: fontFamily,
        fontSize: 13.sp,
      ),
      // Vertical padding centers the single-line text inside the fixed-height field.
      contentPadding: rowFieldContentPadding,
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
    );
  }

  static InputDecoration dropdownDecorator() {
    return rowDropdownDecoration();
  }

  /// Matches [rowDecoration] height/padding so currency/unit align with price.
  static InputDecoration rowDropdownDecoration() {
    return InputDecoration(
      filled: true,
      fillColor: Colors.white,
      isDense: true,
      contentPadding: rowFieldContentPadding,
      constraints: BoxConstraints(
        minHeight: rowFieldHeight,
        maxHeight: rowFieldHeight,
      ),
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
    );
  }

  static InputDecoration decorator({EdgeInsetsGeometry? contentPadding}) {
    return InputDecoration(
      filled: true,
      fillColor: Colors.white,
      isDense: true,
      contentPadding:
          contentPadding ?? EdgeInsets.symmetric(horizontal: 10.w, vertical: 10.h),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10.r),
        borderSide: const BorderSide(color: Color(0xFFEAECF0), width: 1.2),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10.r),
        borderSide: const BorderSide(color: Color(0xFF3A7DC5), width: 1.2),
      ),
    );
  }
}
