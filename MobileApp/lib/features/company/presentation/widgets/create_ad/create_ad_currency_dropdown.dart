import 'package:alrasmarket/core/widgets/currency_icon.dart';
import 'package:alrasmarket/features/company/presentation/models/create_ad_currency.dart';
import 'package:alrasmarket/features/company/presentation/widgets/create_ad/create_ad_form_field_styles.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class CreateAdCurrencyDropdown extends StatelessWidget {
  const CreateAdCurrencyDropdown({
    super.key,
    required this.selectedCurrency,
    required this.onChanged,
    this.isLocked = false,
    this.matchRowHeight = false,
  });

  final String selectedCurrency;
  final ValueChanged<String> onChanged;
  final bool isLocked;
  final bool matchRowHeight;

  @override
  Widget build(BuildContext context) {
    // Locked = fixed currency only (AED retail/requests, USD booking).
    final displayCurrency = CreateAdCurrency.normalize(selectedCurrency);

    if (isLocked) {
      final locked = Container(
        width: double.infinity,
        alignment: Alignment.center,
        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 10.h),
        decoration: BoxDecoration(
          color: const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(10.r),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: CurrencyIcon(
          currency: displayCurrency,
          size: 22,
          matchTextSize: true,
        ),
      );
      if (matchRowHeight) {
        return CreateAdFormFieldStyles.buildRowDropdown(
          InputDecorator(
            decoration: CreateAdFormFieldStyles.dropdownDecorator(),
            child: Center(
              child: CurrencyIcon(
                currency: displayCurrency,
                size: 22,
                matchTextSize: true,
              ),
            ),
          ),
        );
      }
      return locked;
    }

    final dropdown = DropdownButtonFormField<String>(
      initialValue: displayCurrency,
      isExpanded: true,
      icon: Icon(
        Icons.keyboard_arrow_down_rounded,
        size: 22.sp,
        color: const Color(0xFF6B7280),
      ),
      decoration: CreateAdFormFieldStyles.dropdownDecorator(),
      selectedItemBuilder: (context) => CreateAdCurrency.options
          .map(
            (_) => SizedBox(
              width: double.infinity,
              child: Center(
                child: CurrencyIcon(
                  currency: displayCurrency,
                  size: 22,
                  matchTextSize: true,
                ),
              ),
            ),
          )
          .toList(),
      items: CreateAdCurrency.options
          .map(
            (currency) => DropdownMenuItem<String>(
              value: currency,
              child: Center(
                child: CurrencyIcon(currency: currency, size: 24),
              ),
            ),
          )
          .toList(),
      onChanged: (value) {
        if (value == null) return;
        onChanged(value);
      },
    );

    if (matchRowHeight) {
      return CreateAdFormFieldStyles.buildRowDropdown(dropdown);
    }

    return dropdown;
  }
}
