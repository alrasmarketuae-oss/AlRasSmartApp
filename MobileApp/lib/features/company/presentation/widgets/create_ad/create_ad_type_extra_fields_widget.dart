import 'package:alrasmarket/core/widgets/costomtextform.dart';
import 'package:alrasmarket/features/company/presentation/controller/cubit/create_ad_cubit.dart';
import 'package:alrasmarket/features/company/presentation/controller/cubit/create_ad_states.dart';
import 'package:alrasmarket/features/company/presentation/models/create_ad_type.dart';
import 'package:alrasmarket/features/company/presentation/widgets/create_ad/date_selector_widget.dart';
import 'package:alrasmarket/generated/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class CreateAdTypeExtraFieldsWidget extends StatelessWidget {
  const CreateAdTypeExtraFieldsWidget({
    super.key,
    required this.selectedType,
    required this.shippingDurationController,
    required this.onDeliveryDateSelected,
  });

  final String? selectedType;
  final TextEditingController shippingDurationController;
  final ValueChanged<DateTime> onDeliveryDateSelected;

  @override
  Widget build(BuildContext context) {
    final type = CreateAdType.fromLabel(selectedType);
    if (type == null) return const SizedBox.shrink();

    return switch (type) {
      CreateAdType.requests => _RequestsExtraFields(
        onDeliveryDateSelected: onDeliveryDateSelected,
      ),
      CreateAdType.offers => _DurationField(
        controller: shippingDurationController,
        label: S.of(context).offerDuration,
        hintText: S.of(context).enterOfferDurationInDays,
      ),
      CreateAdType.booking => _DurationField(
        controller: shippingDurationController,
        label: S.of(context).shippingDurationDays,
        hintText: S.of(context).enterShippingDurationInDays,
      ),
      CreateAdType.retail => _DurationField(
        controller: shippingDurationController,
        label: S.of(context).deliveryTimeDays,
        hintText: S.of(context).enterDeliveryTimeInDays,
      ),
      CreateAdType.categories => Container(),
    };
  }
}

class _DurationField extends StatelessWidget {
  const _DurationField({
    required this.controller,
    required this.label,
    required this.hintText,
  });

  final TextEditingController controller;
  final String label;
  final String hintText;

  @override
  Widget build(BuildContext context) {
    return CustomTextFormField(
      controller: controller,
      label: label,
      hintText: hintText,
      keyboardType: TextInputType.number,
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return S.of(context).thisFieldIsRequired;
        }
        return null;
      },
    );
  }
}

class _RequestsExtraFields extends StatelessWidget {
  const _RequestsExtraFields({required this.onDeliveryDateSelected});

  final ValueChanged<DateTime> onDeliveryDateSelected;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CreateAdCubit, CreateAdFormState>(
      buildWhen: (previous, current) =>
          previous.requiredDeliveryDate != current.requiredDeliveryDate,
      builder: (context, state) {
        return DateSelectorWidget(
          selectedDate: state.requiredDeliveryDate,
          onDateSelected: onDeliveryDateSelected,
        );
      },
    );
  }
}
