import 'package:alrasmarket/features/company/presentation/models/create_ad_type.dart';
import 'package:alrasmarket/features/company/presentation/models/negotiation_type.dart';
import 'package:alrasmarket/features/company/presentation/widgets/create_ad/create_ad_booking_fields_widget.dart';
import 'package:alrasmarket/features/company/presentation/widgets/create_ad/create_ad_offers_fields_widget.dart';
import 'package:alrasmarket/features/company/presentation/widgets/create_ad/create_ad_requests_fields_widget.dart';
import 'package:alrasmarket/features/company/presentation/widgets/create_ad/create_ad_products_fields_widget.dart';
import 'package:alrasmarket/features/company/presentation/widgets/create_ad/create_ad_retail_fields_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class CreateAdTypeFieldsWidget extends StatelessWidget {
  const CreateAdTypeFieldsWidget({
    super.key,
    required this.selectedType,
    required this.quantityController,
    required this.beforeDiscountController,
    required this.afterDiscountController,
    required this.priceController,
    required this.selectedNegotiationType,
    required this.onNegotiationChanged,
  });

  final String? selectedType;
  final TextEditingController quantityController;
  final TextEditingController beforeDiscountController;
  final TextEditingController afterDiscountController;
  final TextEditingController priceController;
  final NegotiationType selectedNegotiationType;
  final ValueChanged<NegotiationType> onNegotiationChanged;

  @override
  Widget build(BuildContext context) {
    final type = CreateAdType.fromLabel(selectedType);
    if (type == null) return const SizedBox.shrink();

    final Widget typeWidget = switch (type) {
      CreateAdType.requests => CreateAdRequestsFieldsWidget(
          quantityController: quantityController,
          priceController: priceController,
          selectedNegotiationType: selectedNegotiationType,
          onNegotiationChanged: onNegotiationChanged,
        ),
      CreateAdType.offers => CreateAdOffersFieldsWidget(
          quantityController: quantityController,
          beforeDiscountController: beforeDiscountController,
          afterDiscountController: afterDiscountController,
          selectedNegotiationType: selectedNegotiationType,
          onNegotiationChanged: onNegotiationChanged,
        ),
      CreateAdType.booking => CreateAdBookingFieldsWidget(
          quantityController: quantityController,
          priceController: priceController,
          selectedNegotiationType: selectedNegotiationType,
          onNegotiationChanged: onNegotiationChanged,
        ),
      CreateAdType.retail => CreateAdRetailFieldsWidget(
          quantityController: quantityController,
          priceController: priceController,
          selectedNegotiationType: selectedNegotiationType,
          onNegotiationChanged: onNegotiationChanged,
        ),
      CreateAdType.categories => CreateAdProductsFieldsWidget(
          quantityController: quantityController,
          priceController: priceController,
          selectedNegotiationType: selectedNegotiationType,
          onNegotiationChanged: onNegotiationChanged,
        ),
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(height: 10.h),
        typeWidget,
        SizedBox(height: 10.h),
      ],
    );
  }
}
