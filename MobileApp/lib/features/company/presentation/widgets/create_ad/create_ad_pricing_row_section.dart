import 'package:alrasmarket/core/theme/app_fonts.dart';
import 'package:alrasmarket/core/utils/thousands_separator_input_formatter.dart';
import 'package:alrasmarket/features/company/presentation/helpers/create_ad_price_labels.dart';
import 'package:alrasmarket/features/company/presentation/widgets/create_ad/create_ad_currency_dropdown.dart';
import 'package:alrasmarket/features/company/presentation/widgets/create_ad/create_ad_field_column.dart';
import 'package:alrasmarket/features/company/presentation/widgets/create_ad/create_ad_form_field_styles.dart';
import 'package:alrasmarket/features/company/presentation/widgets/create_ad/create_ad_unit_dropdown.dart';
import 'package:alrasmarket/generated/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class CreateAdPricingRowSection extends StatelessWidget {
  const CreateAdPricingRowSection({
    super.key,
    required this.quantityController,
    required this.priceController,
    required this.quantityLabel,
    required this.priceHint,
    required this.selectedCurrency,
    required this.onCurrencyChanged,
    required this.selectedUnit,
    required this.onUnitChanged,
    this.priceLabel,
    this.isCurrencyLocked = false,
    this.isUnitLocked = false,
    this.showQuantityField = true,
    this.quantityExtraValidator,
    this.fieldsOptional = false,
  });

  static const priceFlex = 1;
  static const currencyFlex = 1;
  static const unitFlex = 1;

  final TextEditingController quantityController;
  final TextEditingController priceController;
  final String quantityLabel;
  final String priceHint;
  /// When set (e.g. Request ads), overrides the default "Price per unit" label.
  final String? priceLabel;
  final String selectedCurrency;
  final ValueChanged<String> onCurrencyChanged;
  final String selectedUnit;
  final ValueChanged<String> onUnitChanged;
  final bool isCurrencyLocked;
  final bool isUnitLocked;
  final bool showQuantityField;
  final String? Function(String?)? quantityExtraValidator;
  final bool fieldsOptional;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final fontFamily = AppFonts.familyFor(Localizations.localeOf(context));
    final fieldTextStyle = TextStyle(
      color: const Color(0xFF333333),
      fontFamily: fontFamily,
      fontSize: 14.sp,
      height: 1.5,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showQuantityField) ...[
          Text(
            quantityLabel,
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
            controller: quantityController,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[\d,\s٬]')),
              ThousandsSeparatorInputFormatter.quantity(),
            ],
            style: fieldTextStyle,
            decoration: CreateAdFormFieldStyles.decoration(
              hintText: s.quantity,
              fontFamily: fontFamily,
            ),
            validator: (value) {
              if (fieldsOptional &&
                  (value == null || value.trim().isEmpty)) {
                return null;
              }
              if (value == null || value.trim().isEmpty) {
                return s.thisFieldIsRequired;
              }
              if (ThousandsNumberInput.parseInt(value) == null) {
                return s.thisFieldIsRequired;
              }
              if (quantityExtraValidator != null) {
                return quantityExtraValidator!(value);
              }
              return null;
            },
          ),
          SizedBox(height: 10.h),
        ],
        _buildPricingFieldsRow(
          context: context,
          s: s,
          fontFamily: fontFamily,
          fieldTextStyle: fieldTextStyle,
        ),
      ],
    );
  }

  Widget _buildPricingFieldsRow({
    required BuildContext context,
    required S s,
    required String fontFamily,
    required TextStyle fieldTextStyle,
  }) {
    final priceField = CreateAdFieldColumn(
      flex: priceFlex,
      label: priceLabel ?? s.price,
      labelInfoMessage:
          CreateAdPriceLabels.priceOverSelectedUnitTip(s, selectedUnit),
      child: CreateAdFormFieldStyles.buildRowTextFormField(
        controller: priceController,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'[\d.,\s٬]')),
          ThousandsSeparatorInputFormatter.price(),
        ],
        style: fieldTextStyle,
        hintText: priceHint,
        fontFamily: fontFamily,
        validator: (value) {
          if (fieldsOptional && (value == null || value.trim().isEmpty)) {
            return null;
          }
          if (value == null || value.trim().isEmpty) {
            return s.thisFieldIsRequired;
          }
          if (ThousandsNumberInput.parseDouble(value) == null) {
            return s.thisFieldIsRequired;
          }
          return null;
        },
      ),
    );

    final currencyField = CreateAdFieldColumn(
      flex: currencyFlex,
      label: s.currency,
      child: CreateAdCurrencyDropdown(
        selectedCurrency: selectedCurrency,
        onChanged: onCurrencyChanged,
        isLocked: isCurrencyLocked,
        matchRowHeight: true,
      ),
    );

    final unitField = CreateAdFieldColumn(
      flex: unitFlex,
      label: s.unitLabel,
      child: CreateAdUnitDropdown(
        selectedUnit: selectedUnit,
        onChanged: onUnitChanged,
        isLocked: isUnitLocked,
        matchRowHeight: true,
      ),
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        priceField,
        SizedBox(width: 8.w),
        currencyField,
        SizedBox(width: 8.w),
        unitField,
      ],
    );
  }
}
