import 'package:alrasmarket/features/company/presentation/models/create_ad_currency.dart';
import 'package:alrasmarket/features/company/presentation/widgets/create_ad/create_ad_currency_label.dart';
import 'package:alrasmarket/features/company/presentation/widgets/create_ad/create_ad_form_field_styles.dart';
import 'package:alrasmarket/features/company/presentation/widgets/create_ad/create_ad_unit_dropdown.dart';
import 'package:alrasmarket/generated/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class PriceWithCurrencyField extends StatefulWidget {
  const PriceWithCurrencyField({
    super.key,
    required this.controller,
    required this.selectedCurrency,
    required this.onCurrencyChanged,
    this.hintText,
    this.validator,
    this.isCurrencyLocked = false,
    this.selectedUnit,
    this.onUnitChanged,
  });

  final TextEditingController controller;
  final String selectedCurrency;
  final ValueChanged<String> onCurrencyChanged;
  final String? hintText;
  final String? Function(String?)? validator;
  final bool isCurrencyLocked;
  final String? selectedUnit;
  final ValueChanged<String>? onUnitChanged;

  bool get _usesBottomSelectors => onUnitChanged != null && selectedUnit != null;

  @override
  State<PriceWithCurrencyField> createState() => _PriceWithCurrencyFieldState();
}

class _PriceWithCurrencyFieldState extends State<PriceWithCurrencyField> {
  @override
  void initState() {
    super.initState();
    _syncCurrencyWithLock();
  }

  @override
  void didUpdateWidget(covariant PriceWithCurrencyField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isCurrencyLocked != widget.isCurrencyLocked ||
        oldWidget.selectedCurrency != widget.selectedCurrency) {
      _syncCurrencyWithLock();
    }
  }

  void _syncCurrencyWithLock() {
    // Locked currency is owned by the parent (AED retail / USD booking).
  }

  InputDecoration _inputDecoration({
    required String? hintText,
    required String? fontFamily,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      filled: true,
      fillColor: Colors.white,
      hintText: hintText,
      hintStyle: TextStyle(
        color: const Color(0xFF333333).withOpacity(0.5),
        fontFamily: fontFamily,
        fontSize: 14.sp,
      ),
      contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
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
      suffixIcon: suffixIcon,
      suffixIconConstraints: suffixIcon != null
          ? BoxConstraints(minWidth: 96.w, minHeight: 48.h)
          : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final fontFamily = Theme.of(context).textTheme.bodyMedium?.fontFamily;
    final displayCurrency =
        CreateAdCurrency.normalize(widget.selectedCurrency);
    final resolvedHint = widget.hintText ?? S.of(context).enterPrice;

    final priceField = TextFormField(
      controller: widget.controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      validator: widget.validator ??
          (value) {
            if (value == null || value.trim().isEmpty) {
              return S.of(context).thisFieldIsRequired;
            }
            return null;
          },
      style: TextStyle(
        color: const Color(0xFF333333),
        fontFamily: fontFamily,
        fontSize: 14.sp,
      ),
      decoration: _inputDecoration(
        hintText: resolvedHint,
        fontFamily: fontFamily,
        suffixIcon: widget._usesBottomSelectors
            ? null
            : Padding(
                padding: EdgeInsets.only(right: 4.w),
                child: widget.isCurrencyLocked
                    ? _LockedCurrencyLabel(
                        currency: displayCurrency,
                        fontFamily: fontFamily,
                      )
                    : _CurrencySuffixDropdown(
                        selectedCurrency: displayCurrency,
                        onChanged: widget.onCurrencyChanged,
                        fontFamily: fontFamily,
                      ),
              ),
      ),
    );

    if (!widget._usesBottomSelectors) {
      return priceField;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        priceField,
        SizedBox(height: 12.h),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: widget.isCurrencyLocked
                  ? _LockedCurrencyField(
                      currency: displayCurrency,
                      fontFamily: fontFamily,
                    )
                  : _CurrencyDropdownField(
                      selectedCurrency: displayCurrency,
                      onChanged: widget.onCurrencyChanged,
                      fontFamily: fontFamily,
                    ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: CreateAdUnitDropdown(
                selectedUnit: widget.selectedUnit!,
                onChanged: widget.onUnitChanged!,
                matchRowHeight: true,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _LockedCurrencyField extends StatelessWidget {
  const _LockedCurrencyField({
    required this.currency,
    this.fontFamily,
  });

  final String currency;
  final String? fontFamily;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: CreateAdFormFieldStyles.rowFieldHeight,
      child: InputDecorator(
        decoration: CreateAdFormFieldStyles.rowDropdownDecoration(),
        child: CreateAdCurrencyLabel(
          currency: currency,
        ),
      ),
    );
  }
}

class _CurrencyDropdownField extends StatelessWidget {
  const _CurrencyDropdownField({
    required this.selectedCurrency,
    required this.onChanged,
    this.fontFamily,
  });

  final String selectedCurrency;
  final ValueChanged<String> onChanged;
  final String? fontFamily;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: CreateAdFormFieldStyles.rowFieldHeight,
      child: InputDecorator(
        decoration: CreateAdFormFieldStyles.rowDropdownDecoration(),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: CreateAdCurrency.normalize(selectedCurrency),
            isExpanded: true,
            icon: Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 20.sp,
              color: const Color(0xFF6B7280),
            ),
            selectedItemBuilder: (context) => CreateAdCurrency.options
                .map(
                  (_) => SizedBox(
                    width: double.infinity,
                    child: Center(
                      child: CreateAdCurrencyLabel(
                        currency: selectedCurrency,
                      ),
                    ),
                  ),
                )
                .toList(),
            items: CreateAdCurrency.options
                .map(
                  (currency) => DropdownMenuItem<String>(
                    value: currency,
                    child: CreateAdCurrencyLabel(
                      currency: currency,
                    ),
                  ),
                )
                .toList(),
            onChanged: (value) {
              if (value == null) return;
              onChanged(value);
            },
          ),
        ),
      ),
    );
  }
}

class _LockedCurrencyLabel extends StatelessWidget {
  const _LockedCurrencyLabel({
    required this.currency,
    this.fontFamily,
  });

  final String currency;
  final String? fontFamily;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40.w,
      margin: EdgeInsets.symmetric(vertical: 8.h),
      padding: EdgeInsets.symmetric(horizontal: 12.w),
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(color: const Color(0xFFEAECF0), width: 1.5.w),
        ),
      ),
      alignment: Alignment.center,
      child: CreateAdCurrencyLabel(
        currency: currency,
      ),
    );
  }
}

class _CurrencySuffixDropdown extends StatelessWidget {
  const _CurrencySuffixDropdown({
    required this.selectedCurrency,
    required this.onChanged,
    this.fontFamily,
  });

  final String selectedCurrency;
  final ValueChanged<String> onChanged;
  final String? fontFamily;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 8.h),
      padding: EdgeInsets.symmetric(horizontal: 8.w),
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(color: const Color(0xFFEAECF0), width: 1.5.w),
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: CreateAdCurrency.normalize(selectedCurrency),
          isDense: true,
          icon: Icon(
            Icons.keyboard_arrow_down_rounded,
            size: 20.sp,
            color: const Color(0xFF6B7280),
          ),
          style: TextStyle(
            color: const Color(0xFF333333),
            fontFamily: fontFamily,
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
          ),
          selectedItemBuilder: (context) => CreateAdCurrency.options
              .map(
                (currency) => Align(
                  alignment: Alignment.centerRight,
                  child: CreateAdCurrencyLabel(
                    currency: currency,
                  ),
                ),
              )
              .toList(),
          items: CreateAdCurrency.options
              .map(
                (currency) => DropdownMenuItem<String>(
                  value: currency,
                  child: CreateAdCurrencyLabel(
                    currency: currency,
                  ),
                ),
              )
              .toList(),
          onChanged: (value) {
            if (value == null) return;
            onChanged(value);
          },
        ),
      ),
    );
  }
}
