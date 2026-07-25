import 'package:alrasmarket/features/company/presentation/models/negotiation_type.dart';
import 'package:alrasmarket/features/company/presentation/widgets/create_ad/create_ad_price_negotiation_section.dart';
import 'package:flutter/material.dart';

class CreateAdRetailFieldsWidget extends StatelessWidget {
  const CreateAdRetailFieldsWidget({
    super.key,
    required this.quantityController,
    required this.priceController,
    required this.selectedNegotiationType,
    required this.onNegotiationChanged,
  });

  final TextEditingController quantityController;
  final TextEditingController priceController;
  final NegotiationType selectedNegotiationType;
  final ValueChanged<NegotiationType> onNegotiationChanged;

  @override
  Widget build(BuildContext context) {
    return CreateAdPriceNegotiationSection(
      quantityController: quantityController,
      priceController: priceController,
      selectedNegotiationType: selectedNegotiationType,
      onNegotiationChanged: onNegotiationChanged,
    );
  }
}
