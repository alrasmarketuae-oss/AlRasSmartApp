import 'package:alrasmarket/core/theme/app_fonts.dart';
import 'package:alrasmarket/features/company/presentation/helpers/create_ad_price_labels.dart';
import 'package:alrasmarket/features/company/presentation/widgets/create_ad/create_ad_currency_dropdown.dart';
import 'package:alrasmarket/features/company/presentation/widgets/create_ad/create_ad_field_column.dart';
import 'package:alrasmarket/features/company/presentation/widgets/create_ad/create_ad_form_field_styles.dart';
import 'package:alrasmarket/features/company/presentation/widgets/create_ad/create_ad_pricing_row_section.dart';
import 'package:alrasmarket/features/company/presentation/widgets/create_ad/create_ad_unit_dropdown.dart';
import 'package:alrasmarket/generated/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class CreateAdOffersPricingRowSection extends StatelessWidget {
  const CreateAdOffersPricingRowSection({
    super.key,
    required this.quantityController,
    required this.beforeDiscountController,
    required this.afterDiscountController,
    required this.selectedCurrency,
    required this.onCurrencyChanged,
    required this.selectedUnit,
    required this.onUnitChanged,
    required this.priceHint,
  });

  final TextEditingController quantityController;
  final TextEditingController beforeDiscountController;
  final TextEditingController afterDiscountController;
  final String selectedCurrency;
  final ValueChanged<String> onCurrencyChanged;
  final String selectedUnit;
  final ValueChanged<String> onUnitChanged;
  final String priceHint;

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
        Text(
          s.availableQuantity,
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
          style: fieldTextStyle,
          decoration: CreateAdFormFieldStyles.decoration(
            hintText: s.quantity,
            fontFamily: fontFamily,
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return s.thisFieldIsRequired;
            }
            return null;
          },
        ),
        SizedBox(height: 10.h),
        _buildTabletPricingRows(
          context: context,
          s: s,
          fontFamily: fontFamily,
          fieldTextStyle: fieldTextStyle,
        ),
      ],
    );
  }

  Widget _buildTabletPricingRows({
    required BuildContext context,
    required S s,
    required String fontFamily,
    required TextStyle fieldTextStyle,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _beforeDiscountField(s, fontFamily, fieldTextStyle),
            SizedBox(width: 8.w),
            _afterDiscountField(s, fontFamily, fieldTextStyle),
          ],
        ),
        SizedBox(height: 8.h),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _currencyField(s),
            SizedBox(width: 8.w),
            _unitField(s),
          ],
        ),
      ],
    );
  }

  Widget _beforeDiscountField(
    S s,
    String fontFamily,
    TextStyle fieldTextStyle,
  ) {
    return CreateAdFieldColumn(
      flex: CreateAdPricingRowSection.priceFlex,
      label: s.beforeDiscount,
      child: CreateAdFormFieldStyles.buildRowTextFormField(
        controller: beforeDiscountController,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        style: fieldTextStyle,
        hintText: s.beforeDiscount,
        fontFamily: fontFamily,
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return s.thisFieldIsRequired;
          }
          return null;
        },
      ),
    );
  }

  Widget _afterDiscountField(
    S s,
    String fontFamily,
    TextStyle fieldTextStyle,
  ) {
    return CreateAdFieldColumn(
      flex: CreateAdPricingRowSection.priceFlex,
      label: CreateAdPriceLabels.offerPricePerUnitLabel(s, selectedUnit),
      child: CreateAdFormFieldStyles.buildRowTextFormField(
        controller: afterDiscountController,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        style: fieldTextStyle,
        hintText: priceHint,
        fontFamily: fontFamily,
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return s.thisFieldIsRequired;
          }
          return null;
        },
      ),
    );
  }

  Widget _currencyField(S s) {
    return CreateAdFieldColumn(
      flex: CreateAdPricingRowSection.currencyFlex,
      label: s.currency,
      child: CreateAdCurrencyDropdown(
        selectedCurrency: selectedCurrency,
        onChanged: onCurrencyChanged,
        matchRowHeight: true,
      ),
    );
  }

  Widget _unitField(S s) {
    return CreateAdFieldColumn(
      flex: CreateAdPricingRowSection.unitFlex,
      label: s.unitLabel,
      child: CreateAdUnitDropdown(
        selectedUnit: selectedUnit,
        onChanged: onUnitChanged,
        matchRowHeight: true,
      ),
    );
  }
}
