import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Design System Text Field Widget
///
/// Usage:
/// ```dart
/// AppTextField(
///   controller: _emailController,
///   hintText: 'البريد الإلكتروني',
///   prefixIcon: Icons.email_outlined,
/// )
/// ```
class AppTextField extends StatefulWidget {
  const AppTextField({
    super.key,
    this.controller,
    this.hintText,
    this.labelText,
    this.textStyle,
    this.hintStyle,
    this.labelStyle,
    this.isPassword = false,
    this.prefixIcon,
    this.suffixIcon,
    this.keyboardType,
    this.validator,
    this.onChanged,
    this.onTap,
    this.onSubmitted,
    this.enabled = true,
    this.readOnly = false,
    this.maxLines = 1,
    this.maxLength,
    this.fillColor,
    this.borderColor,
    this.focusedBorderColor,
    this.errorBorderColor,
    this.borderRadius,
    this.borderWidth,
    this.contentPadding,
    this.textAlign = TextAlign.start,
    this.textDirection,
    this.obscureText,
    this.autofocus = false,
    this.textCapitalization = TextCapitalization.none,
    this.inputFormatters,
  });

  final TextEditingController? controller;
  final String? hintText;
  final String? labelText;
  final TextStyle? textStyle;
  final TextStyle? hintStyle;
  final TextStyle? labelStyle;
  final bool isPassword;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final VoidCallback? onTap;
  final void Function(String)? onSubmitted;
  final bool enabled;
  final bool readOnly;
  final int maxLines;
  final int? maxLength;
  final Color? fillColor;
  final Color? borderColor;
  final Color? focusedBorderColor;
  final Color? errorBorderColor;
  final double? borderRadius;
  final double? borderWidth;
  final EdgeInsetsGeometry? contentPadding;
  final TextAlign textAlign;
  final TextDirection? textDirection;
  final bool? obscureText;
  final bool autofocus;
  final TextCapitalization textCapitalization;
  final List<TextInputFormatter>? inputFormatters;

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  late bool _isPasswordVisible;
  final FocusNode _focusNode = FocusNode();
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _isPasswordVisible = widget.isPassword;
    _focusNode.addListener(() {
      setState(() {
        _isFocused = _focusNode.hasFocus;
      });
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isRTL = Directionality.of(context) == TextDirection.rtl;

    return TextFormField(
      controller: widget.controller,
      focusNode: _focusNode,
      obscureText: widget.isPassword
          ? !_isPasswordVisible
          : (widget.obscureText ?? false),
      keyboardType: widget.keyboardType ?? TextInputType.text,
      validator: widget.validator,
      onChanged: widget.onChanged,
      onTap: widget.onTap,
      onFieldSubmitted: widget.onSubmitted,
      enabled: widget.enabled,
      readOnly: widget.readOnly,
      maxLines: widget.maxLines,
      maxLength: widget.maxLength,
      textAlign: widget.textAlign,
      textDirection:
          widget.textDirection ??
          (isRTL ? TextDirection.rtl : TextDirection.ltr),
      autofocus: widget.autofocus,
      textCapitalization: widget.textCapitalization,
      inputFormatters: widget.inputFormatters,
      cursorColor: theme.primaryColor,
      style:
          widget.textStyle ?? TextStyle(fontSize: 16.sp, color: Colors.black),
      decoration: InputDecoration(
        hintText: widget.hintText,
        labelText: widget.labelText,
        hintStyle:
            widget.hintStyle ??
            TextStyle(fontSize: 14.sp, color: Colors.grey.shade600),
        labelStyle: widget.labelStyle,
        filled: true,
        fillColor: widget.fillColor ?? Colors.white,
        contentPadding:
            widget.contentPadding ??
            EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
        prefixIcon: widget.prefixIcon != null
            ? Icon(
                widget.prefixIcon,
                size: 20.sp,
                color: _isFocused
                    ? (widget.focusedBorderColor ?? theme.primaryColor)
                    : Colors.grey.shade600,
              )
            : null,
        suffixIcon: _buildSuffixIcon(theme),
        border: _buildBorder(theme, isError: false),
        enabledBorder: _buildBorder(theme, isError: false),
        focusedBorder: _buildBorder(theme, isError: false, isFocused: true),
        errorBorder: _buildBorder(theme, isError: true),
        focusedErrorBorder: _buildBorder(theme, isError: true, isFocused: true),
        disabledBorder: _buildBorder(theme, isError: false, isEnabled: false),
        errorStyle: TextStyle(fontSize: 12.sp, color: Colors.red),
        counterText: widget.maxLength != null ? null : '',
      ),
    );
  }

  Widget? _buildSuffixIcon(ThemeData theme) {
    if (widget.isPassword) {
      return IconButton(
        icon: Icon(
          _isPasswordVisible
              ? Icons.visibility_outlined
              : Icons.visibility_off_outlined,
          size: 20.sp,
          color: Colors.grey.shade600,
        ),
        onPressed: () {
          setState(() {
            _isPasswordVisible = !_isPasswordVisible;
          });
        },
      );
    }
    return widget.suffixIcon;
  }

  InputBorder _buildBorder(
    ThemeData theme, {
    required bool isError,
    bool isFocused = false,
    bool isEnabled = true,
  }) {
    final borderRadius = widget.borderRadius ?? 12.r;
    final borderWidth = widget.borderWidth ?? 1.0;
    final defaultBorderColor = Colors.grey.shade300;

    Color borderColor;
    if (!isEnabled) {
      borderColor = Colors.grey.shade200;
    } else if (isError) {
      borderColor = widget.errorBorderColor ?? Colors.red;
    } else if (isFocused) {
      borderColor = widget.focusedBorderColor ?? theme.primaryColor;
    } else {
      borderColor = widget.borderColor ?? defaultBorderColor;
    }

    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(borderRadius),
      borderSide: BorderSide(
        color: borderColor,
        width: isFocused ? borderWidth * 1.5 : borderWidth,
      ),
    );
  }
}
