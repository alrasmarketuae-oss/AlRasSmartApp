import 'package:alrasmarket/features/company/presentation/controller/cubit/create_ad_cubit.dart';
import 'package:alrasmarket/features/company/presentation/controller/cubit/create_ad_states.dart';
import 'package:alrasmarket/features/company/presentation/models/booking_price_type.dart';
import 'package:alrasmarket/features/company/presentation/models/negotiation_type.dart';
import 'package:alrasmarket/features/company/presentation/widgets/create_ad/booking_price_type_select_widget.dart';
import 'package:alrasmarket/features/company/presentation/widgets/create_ad/create_ad_location_details_section.dart';
import 'package:alrasmarket/features/company/presentation/widgets/create_ad/create_ad_price_negotiation_section.dart';
import 'package:alrasmarket/generated/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class CreateAdBookingFieldsWidget extends StatelessWidget {
  const CreateAdBookingFieldsWidget({
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
    final cubit = context.read<CreateAdCubit>();

    return BlocBuilder<CreateAdCubit, CreateAdFormState>(
      buildWhen: (previous, current) =>
          previous.originCountry != current.originCountry ||
          previous.originPort != current.originPort ||
          previous.originPorts != current.originPorts ||
          previous.isOriginPortsLoading != current.isOriginPortsLoading ||
          previous.destinationPort != current.destinationPort ||
          previous.destinationCountry != current.destinationCountry ||
          previous.destinationPorts != current.destinationPorts ||
          previous.isDestinationPortsLoading !=
              current.isDestinationPortsLoading ||
          previous.bookingPriceType != current.bookingPriceType,
      builder: (context, state) {
        final showPorts = state.bookingPriceType != BookingPriceType.fob;
        final showDestination = state.bookingPriceType != BookingPriceType.fob;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            BookingPriceTypeSelectWidget(
              selectedType: state.bookingPriceType,
              onChanged: cubit.setBookingPriceType,
            ),
            SizedBox(height: 10.h),
            CreateAdLocationDetailsSection(
              countryLabel: S.of(context).countryOfOrigin,
              portLabel: S.of(context).loadingPort,
              selectedCountry: state.originCountry,
              ports: state.originPorts,
              selectedPort: state.originPort,
              isPortsLoading: state.isOriginPortsLoading,
              onCountryChanged: cubit.setOriginCountry,
              onPortChanged: cubit.setOriginPort,
              showPorts: showPorts,
            ),
            if (showDestination) ...[
              SizedBox(height: 10.h),
              CreateAdLocationDetailsSection(
                countryLabel: S.of(context).destinationCountry,
                portLabel: S.of(context).destinationPort,
                selectedCountry: state.destinationCountry,
                ports: state.destinationPorts,
                selectedPort: state.destinationPort,
                isPortsLoading: state.isDestinationPortsLoading,
                onCountryChanged: cubit.setDestinationCountry,
                onPortChanged: cubit.setDestinationPort,
                showPorts: showPorts,
              ),
            ],
            SizedBox(height: 10.h),
            CreateAdPriceNegotiationSection(
              quantityController: quantityController,
              priceController: priceController,
              selectedNegotiationType: selectedNegotiationType,
              onNegotiationChanged: onNegotiationChanged,
            ),
          ],
        );
      },
    );
  }
}
