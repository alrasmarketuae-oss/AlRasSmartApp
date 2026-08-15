import 'package:alrasmarket/core/theme/colors.dart';
import 'package:alrasmarket/core/utils/product_quantity_validator.dart';
import 'package:alrasmarket/features/clint/presentation/controller/cubit/clint_cubit.dart';
import 'package:alrasmarket/features/clint/presentation/controller/cubit/clint_states.dart';
import 'package:alrasmarket/features/company/presentation/helpers/create_ad_price_labels.dart';
import 'package:alrasmarket/features/company/presentation/widgets/create_ad/create_ad_pricing_row_section.dart';
import 'package:alrasmarket/features/company/presentation/widgets/create_ad/specifications_input_widget.dart';
import 'package:alrasmarket/generated/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class OfferDetailsFieldsWidget extends StatelessWidget {
  const OfferDetailsFieldsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<ClintCubit>();
    final s = S.of(context);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: AppColors.border(context), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          BlocBuilder<ClintCubit, ClintStates>(
            buildWhen: (previous, current) {
              if (previous is! SubmitOfferFormState ||
                  current is! SubmitOfferFormState) {
                return true;
              }
              return previous.selectedCurrency != current.selectedCurrency ||
                  previous.selectedUnit != current.selectedUnit;
            },
            builder: (context, state) {
              final selectedCurrency = state is SubmitOfferFormState
                  ? state.selectedCurrency
                  : 'AED';
              final selectedUnit =
                  state is SubmitOfferFormState ? state.selectedUnit : 'Kg';
              final requestProduct = state is SubmitOfferFormState
                  ? state.product
                  : cubit.currentProduct;
              final priceHint = CreateAdPriceLabels.enterPricePerUnitHint(
                s,
                selectedUnit,
              );

              return CreateAdPricingRowSection(
                quantityController: cubit.quantityController,
                priceController: cubit.priceController,
                quantityLabel: s.availableQuantity,
                quantityExtraValidator: requestProduct == null
                    ? null
                    : (value) => ProductQuantityValidator
                        .validateOfferAgainstRequiredQuantity(
                          rawValue: value,
                          s: s,
                          requestProduct: requestProduct,
                          offerUnit: selectedUnit,
                        ),
                priceHint:
                    priceHint.isNotEmpty ? priceHint : s.enterPrice,
                selectedCurrency: selectedCurrency,
                onCurrencyChanged: (value) =>
                    cubit.setSelectedCurrency(value),
                selectedUnit: selectedUnit,
                onUnitChanged: cubit.setSelectedUnit,
                isUnitLocked: false,
              );
            },
          ),
          SizedBox(height: 16.h),
          SpecificationsInputWidget(
            controller: cubit.notesController,
            labelText: s.specifications,
            hintText: s.addAnySpecialInstructionsHere,
          ),
        ],
      ),
    );
  }
}
