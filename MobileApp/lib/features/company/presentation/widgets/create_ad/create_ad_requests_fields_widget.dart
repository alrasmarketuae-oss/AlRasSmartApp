import 'package:alrasmarket/features/company/presentation/controller/cubit/create_ad_cubit.dart';
import 'package:alrasmarket/features/company/presentation/controller/cubit/create_ad_states.dart';
import 'package:alrasmarket/features/company/presentation/models/negotiation_type.dart';
import 'package:alrasmarket/features/company/presentation/widgets/create_ad/create_ad_price_negotiation_section.dart';
import 'package:alrasmarket/features/company/presentation/widgets/create_ad/request_fulfillment_radio_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:alrasmarket/generated/l10n.dart';

class CreateAdRequestsFieldsWidget extends StatelessWidget {
  const CreateAdRequestsFieldsWidget({
    super.key,
    required this.quantityController,
    required this.priceController,
    required this.selectedNegotiationType,
    required this.onNegotiationChanged,
    this.fromBuyer = false,
  });

  final TextEditingController quantityController;
  final TextEditingController priceController;
  final NegotiationType selectedNegotiationType;
  final ValueChanged<NegotiationType> onNegotiationChanged;
  final bool fromBuyer;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<CreateAdCubit>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CreateAdPriceNegotiationSection(
          quantityController: quantityController,
          priceController: priceController,
          selectedNegotiationType: selectedNegotiationType,
          onNegotiationChanged: onNegotiationChanged,
          quantityLabel: S.of(context).requiredQuantity,
          hintText: S.of(context).enterYourTargetPrice,
          fromBuyer: fromBuyer,
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
