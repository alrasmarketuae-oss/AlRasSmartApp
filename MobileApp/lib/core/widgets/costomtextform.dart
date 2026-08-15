import 'package:alrasmarket/generated/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import '../../../core/theme/colors.dart';

class CustomTextFormField extends StatefulWidget {
  const CustomTextFormField({
    Key? key,
    this.controller,
    this.hintText,
    this.textStyle,
    this.hintStyle,
    this.isPassword = false,
    this.leftIcon,
    this.leftIconColor,
    this.leftIconSize,
    this.onLeftIconTap,
    this.rightIcon,
    this.keyboardType,
    this.validator,
    this.onChanged,
    this.onSubmitted,
    this.onTap,
    this.enabled = true,
    this.maxLines = 1,
    this.fillColor,
    this.borderColor,
    this.borderRadius,
    this.borderWidth,
    this.suffixIcon,
    this.label,
    this.addOptionalLabel = false,
    this.rightIconColor,
    this.height,
    this.expandHeight = false,
    this.focusNode,
    this.showShadow = true,
  }) : super(key: key);

  final FocusNode? focusNode;

  final TextEditingController? controller;
  final String? hintText;
  final TextStyle? textStyle;
  final TextStyle? hintStyle;
  final double? height;
  final bool expandHeight;
  final bool isPassword;
  final String? leftIcon;
  final Color? leftIconColor;
  final double? leftIconSize;
  final VoidCallback? onLeftIconTap;
  final String? rightIcon;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final Function(String)? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onTap;
  final bool enabled;
  final bool addOptionalLabel;
  final int maxLines;
  final Color? fillColor;
  final Color? borderColor;
  final double? borderRadius;
  final double? borderWidth;
  final IconButton? suffixIcon;
  final String? label;
  final Color? rightIconColor;
  final bool showShadow;
  @override
  State<CustomTextFormField> createState() => _CustomTextFormFieldState();
}

class _CustomTextFormFieldState extends State<CustomTextFormField> {
  bool _isPasswordVisible = false;
  FocusNode? _ownedFocusNode;

  FocusNode get _effectiveFocusNode =>
      widget.focusNode ?? (_ownedFocusNode ??= FocusNode());

  bool _hasAssetIcon(String? path) =>
      path != null && path.trim().isNotEmpty;

  @override
  void dispose() {
    _ownedFocusNode?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final fieldRadius = widget.borderRadius ?? 10.r;
    final leftIconSize = widget.leftIconSize ?? 10.h;

    final textField = TextFormField(
      controller: widget.controller,
      focusNode: _effectiveFocusNode,
      obscureText: widget.isPassword && !_isPasswordVisible,
      keyboardType: widget.keyboardType ?? TextInputType.text,
      validator: widget.validator,
      onChanged: widget.onChanged,
      onFieldSubmitted: widget.onSubmitted,
      onTap: widget.onTap,
      enabled: widget.enabled,
      maxLines: widget.maxLines,
      textAlign: isArabic ? TextAlign.right : TextAlign.left,
      cursorColor: LightColor.defaultColor,
      keyboardAppearance:
          AppColors.isDark(context) ? Brightness.dark : Brightness.light,
      style: widget.textStyle ??
          TextStyle(
            inherit: false,
            fontFamily: Theme.of(context).textTheme.bodyLarge?.fontFamily,
            fontWeight: FontWeight.w500,
            fontSize: 14.sp,
            height: 1.35,
            color: AppColors.title(context),
          ),
      decoration: InputDecoration(
        hintText: widget.hintText,
        hintStyle: widget.hintStyle ??
            TextStyle(
              inherit: false,
              fontFamily: Theme.of(context).textTheme.bodyLarge?.fontFamily,
              fontSize: 14.sp,
              color: AppColors.subtitle(context),
            ),
        filled: true,
        fillColor: widget.fillColor ?? AppColors.inputFill(context),
        constraints: widget.expandHeight
            ? const BoxConstraints.expand()
            : widget.height != null
            ? BoxConstraints(
                minHeight: widget.height!,
                maxHeight: widget.height!,
              )
            : BoxConstraints(minHeight: 46.h, maxHeight: 120.h),
        contentPadding: EdgeInsets.symmetric(
          horizontal: 16.w,
          vertical: widget.expandHeight ? 16.h : 12.h,
        ),

        prefixIcon: _hasAssetIcon(widget.leftIcon)
            ? widget.onLeftIconTap != null
                ? IconButton(
                    onPressed: widget.onLeftIconTap,
                    padding: EdgeInsets.symmetric(horizontal: 10.w),
                    constraints: const BoxConstraints(),
                    icon: SvgPicture.asset(
                      widget.leftIcon!,
                      height: leftIconSize,
                      width: leftIconSize,
                      colorFilter: ColorFilter.mode(
                        widget.leftIconColor ?? AppColors.subtitle(context),
                        BlendMode.srcIn,
                      ),
                    ),
                  )
                : Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10.w),
                    child: SvgPicture.asset(
                      widget.leftIcon!,
                      height: leftIconSize,
                      width: leftIconSize,
                      colorFilter: ColorFilter.mode(
                        widget.leftIconColor ?? AppColors.subtitle(context),
                        BlendMode.srcIn,
                      ),
                    ),
                  )
            : null,

        suffixIcon: widget.isPassword
            ? IconButton(
                icon: Icon(
                  _isPasswordVisible
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  size: 20.h,
                  color: widget.rightIconColor ?? AppColors.subtitle(context),
                ),
                onPressed: () {
                  setState(() {
                    _isPasswordVisible = !_isPasswordVisible;
                  });
                },
              )
            : widget.suffixIcon ??
                  (_hasAssetIcon(widget.rightIcon)
                      ? Padding(
                          padding: EdgeInsets.symmetric(horizontal: 10.w),
                          child: SvgPicture.asset(
                            widget.rightIcon!,
                            height: 10.h,
                            width: 10.h,
                            colorFilter: ColorFilter.mode(
                              widget.rightIconColor ?? AppColors.subtitle(context),
                              BlendMode.srcIn,
                            ),
                          ),
                        )
                      : null),

        border: widget.borderRadius == 0
            ? UnderlineInputBorder(
                borderSide: BorderSide(
                  color:
                      widget.borderColor ??
                      LightColor.defaultColor.withOpacity(0.4),
                  width: widget.borderWidth ?? 1.h,
                ),
              )
            : OutlineInputBorder(
                borderRadius: BorderRadius.circular(fieldRadius),
                borderSide: BorderSide(
                  color: widget.borderColor ?? Colors.transparent,
                  width: widget.borderWidth ?? 0,
                ),
              ),
        enabledBorder: widget.borderRadius == 0
            ? UnderlineInputBorder(
                borderSide: BorderSide(
                  color:
                      widget.borderColor ??
                      LightColor.defaultColor.withOpacity(0.4),
                  width: widget.borderWidth ?? 1.h,
                ),
              )
            : OutlineInputBorder(
                borderRadius: BorderRadius.circular(fieldRadius),
                borderSide: BorderSide(
                  color: widget.borderColor ?? Colors.transparent,
                  width: widget.borderWidth ?? 0,
                ),
              ),
        focusedBorder: widget.borderRadius == 0
            ? UnderlineInputBorder(
                borderSide: BorderSide(
                  color: widget.borderColor ?? LightColor.defaultColor,
                  width: (widget.borderWidth ?? 1.h) * 1.5,
                ),
              )
            : OutlineInputBorder(
                borderRadius: BorderRadius.circular(fieldRadius),
                borderSide: BorderSide(
                  color: widget.borderColor ?? LightColor.defaultColor,
                  width: widget.borderWidth ?? 1.w,
                ),
              ),
      ),
    );

    final wrappedField = widget.borderRadius == 0 || !widget.showShadow
        ? textField
        : Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(fieldRadius),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 8.r,
                  offset: Offset(0, 3.h),
                ),
              ],
            ),
            child: textField,
          );

    if (widget.label == null || widget.label!.isEmpty) {
      return wrappedField;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.addOptionalLabel)
          Row(
            children: [
              Expanded(
                child: Text(
                  widget.label!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: AppColors.title(context),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              SizedBox(width: 3.w),
              Text(
                S.of(context).optional,
                style: TextStyle(
                  fontSize: 14.sp,
                  color: AppColors.subtitle(context),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        if (!widget.addOptionalLabel)
          Text(
            widget.label!,
            style: TextStyle(
              fontSize: 14.sp,
              color: AppColors.title(context),
              fontWeight: FontWeight.w600,
            ),
          ),
        SizedBox(height: 8.h),
        wrappedField,
      ],
    );
  }
}
