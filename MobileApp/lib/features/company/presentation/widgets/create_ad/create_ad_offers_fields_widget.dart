import 'package:alrasmarket/features/company/presentation/controller/cubit/create_ad_cubit.dart';
import 'package:alrasmarket/features/company/presentation/controller/cubit/create_ad_states.dart';
import 'package:alrasmarket/features/company/presentation/helpers/create_ad_price_labels.dart';
import 'package:alrasmarket/features/company/presentation/models/negotiation_type.dart';
import 'package:alrasmarket/features/company/presentation/widgets/create_ad/create_ad_offers_pricing_row_section.dart';
import 'package:alrasmarket/features/company/presentation/widgets/create_ad/negotiation_type_radio_widget.dart';
import 'package:alrasmarket/features/company/presentation/widgets/create_ad/request_fulfillment_radio_widget.dart';
import 'package:alrasmarket/generated/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class CreateAdOffersFieldsWidget extends StatelessWidget {
  const CreateAdOffersFieldsWidget({
    super.key,
    required this.quantityController,
    required this.beforeDiscountController,
    required this.afterDiscountController,
    required this.selectedNegotiationType,
    required this.onNegotiationChanged,
  });

  final TextEditingController quantityController;
  final TextEditingController beforeDiscountController;
  final TextEditingController afterDiscountController;
  final NegotiationType selectedNegotiationType;
  final ValueChanged<NegotiationType> onNegotiationChanged;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<CreateAdCubit>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        BlocBuilder<CreateAdCubit, CreateAdFormState>(
          buildWhen: (previous, current) =>
              previous.formRevision != current.formRevision ||
              previous.selectedCurrency != current.selectedCurrency ||
              previous.selectedUnit != current.selectedUnit,
          builder: (context, state) {
            final perUnitHint = CreateAdPriceLabels.enterPricePerUnitHint(
              S.of(context),
              state.selectedUnit,
            );

            return CreateAdOffersPricingRowSection(
              quantityController: quantityController,
              beforeDiscountController: beforeDiscountController,
              afterDiscountController: afterDiscountController,
              selectedCurrency: state.selectedCurrency,
              onCurrencyChanged: cubit.setSelectedCurrency,
              selectedUnit: state.selectedUnit,
              onUnitChanged: cubit.setSelectedUnit,
              priceHint: perUnitHint,
            );
          },
        ),
        SizedBox(height: 10.h),
        NegotiationTypeRadioWidget(
          selectedType: selectedNegotiationType,
          onChanged: onNegotiationChanged,
        ),
        SizedBox(height: 10.h),
        BlocBuilder<CreateAdCubit, CreateAdFormState>(
          buildWhen: (previous, current) =>
              previous.requestFulfillmentType != current.requestFulfillmentType,
          builder: (context, state) {
            return RequestFulfillmentRadioWidget(
              selectedType: state.requestFulfillmentType,
              onChanged: cubit.setRequestFulfillmentType,
            );
          },
        ),
      ],
    );
  }
}
