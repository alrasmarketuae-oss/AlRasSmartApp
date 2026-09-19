import 'package:alrasmarket/features/company/presentation/controller/cubit/create_ad_cubit.dart';
import 'package:alrasmarket/features/company/presentation/controller/cubit/create_ad_states.dart';
import 'package:alrasmarket/features/company/presentation/helpers/create_ad_price_labels.dart';
import 'package:alrasmarket/features/company/presentation/models/create_ad_currency.dart';
import 'package:alrasmarket/features/company/presentation/models/create_ad_type.dart';
import 'package:alrasmarket/features/company/presentation/models/negotiation_type.dart';
import 'package:alrasmarket/features/company/presentation/widgets/create_ad/create_ad_pricing_row_section.dart';
import 'package:alrasmarket/features/company/presentation/widgets/create_ad/negotiation_type_radio_widget.dart';
import 'package:alrasmarket/generated/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class CreateAdPriceNegotiationSection extends StatelessWidget {
  const CreateAdPriceNegotiationSection({
    super.key,
    required this.quantityController,
    required this.priceController,
    required this.selectedNegotiationType,
    required this.onNegotiationChanged,
    this.quantityLabel,
    this.hintText,
    this.isProductPrice = false,
    this.fromBuyer = false,
  });

  final TextEditingController quantityController;
  final TextEditingController priceController;
  final NegotiationType selectedNegotiationType;
  final ValueChanged<NegotiationType> onNegotiationChanged;
  final String? quantityLabel;
  final String? hintText;
  final bool isProductPrice;
  final bool fromBuyer;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<CreateAdCubit>();
    final resolvedHint = hintText ?? S.of(context).enterPrice;

    return BlocBuilder<CreateAdCubit, CreateAdFormState>(
      buildWhen: (previous, current) =>
          previous.formRevision != current.formRevision ||
          previous.selectedCurrency != current.selectedCurrency ||
          previous.selectedType != current.selectedType ||
          previous.selectedUnit != current.selectedUnit ||
          previous.showPrice != current.showPrice,
      builder: (context, state) {
        final s = S.of(context);
        final isRetail = state.selectedType == CreateAdType.retail.label;
        final isBooking = state.selectedType == CreateAdType.booking.label;
        final isRequest = state.selectedType == CreateAdType.requests.label;
        final resolvedQuantityLabel = quantityLabel ??
            (isRequest
                ? CreateAdPriceLabels.requiredQuantityPerUnitLabel(
                    s,
                    state.selectedUnit,
                  )
                : CreateAdPriceLabels.quantityPerUnitLabel(
                    s,
                    state.selectedUnit,
                  ));
        final resolvedPriceLabel = isRequest ? s.targetPrice : null;
        final resolvedPerUnitHint = isRequest
            ? (hintText?.trim().isNotEmpty == true
                ? hintText!.trim()
                : s.enterYourTargetPrice)
            : CreateAdPriceLabels.enterPricePerUnitHint(
                s,
                state.selectedUnit,
              );
        final showNegotiation = !isProductPrice && !isRetail;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CreateAdPricingRowSection(
              quantityController: quantityController,
              priceController: priceController,
              quantityLabel: resolvedQuantityLabel,
              priceLabel: resolvedPriceLabel,
              priceHint: resolvedPerUnitHint.isNotEmpty
                  ? resolvedPerUnitHint
                  : resolvedHint,
              selectedCurrency: isBooking
                  ? CreateAdCurrency.usd
                  : isRetail
                      ? CreateAdCurrency.aed
                      : state.selectedCurrency,
              onCurrencyChanged: cubit.setSelectedCurrency,
              selectedUnit: state.selectedUnit,
              onUnitChanged: cubit.setSelectedUnit,
              isCurrencyLocked: isBooking || isRetail,
              showQuantityField: !fromBuyer,
              fieldsOptional: isRequest,
            ),
            if (showNegotiation) ...[
              SizedBox(height: 10.h),
              NegotiationTypeRadioWidget(
                selectedType: selectedNegotiationType,
                onChanged: onNegotiationChanged,
                fromBuyer: fromBuyer,
              ),
            ],
            if (_shouldShowPriceToggle(state.selectedType)) ...[
              SizedBox(height: 12.h),
              CreateAdShowPriceToggle(
                value: state.showPrice,
                onChanged: cubit.setShowPrice,
              ),
            ],
          ],
        );
      },
    );
  }
}

bool _shouldShowPriceToggle(String? selectedType) {
  final type = (selectedType ?? '').trim().toLowerCase();
  return type.contains('categor') ||
      type.contains('فئة') ||
      type.contains('offer') ||
      type.contains('عرض');
}

class CreateAdShowPriceToggle extends StatelessWidget {
  const CreateAdShowPriceToggle({
    super.key,
    required this.value,
    required this.onChanged,
  });

  /// True when price should be visible (hide-price switch Off).
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final hidePrice = !value;
    return Row(
      children: [
        Expanded(
          child: Text(
            s.showPrice,
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        IconButton(
          tooltip: s.showPriceHint,
          onPressed: () {
            showDialog<void>(
              context: context,
              builder: (ctx) => AlertDialog(
                content: Text(s.showPriceHint),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    child: Text(s.gotIt),
                  ),
                ],
              ),
            );
          },
          icon: Icon(
            Icons.error_outline,
            color: Colors.amber.shade700,
            size: 22.sp,
          ),
        ),
        Switch.adaptive(
          // Off by default = show price. On = hide price / ask for price.
          value: hidePrice,
          onChanged: (hide) => onChanged(!hide),
        ),
      ],
    );
  }
}
