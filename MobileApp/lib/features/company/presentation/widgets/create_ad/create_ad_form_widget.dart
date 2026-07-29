import 'package:alrasmarket/core/theme/app_fonts.dart';
import 'package:alrasmarket/core/widgets/costomtextform.dart';
import 'package:alrasmarket/features/company/presentation/controller/cubit/create_ad_cubit.dart';
import 'package:alrasmarket/features/company/presentation/controller/cubit/create_ad_states.dart';
import 'package:alrasmarket/features/company/presentation/widgets/create_ad/create_ad_category_selection_field.dart';
import 'package:alrasmarket/features/company/presentation/widgets/create_ad/create_ad_common_fields_widget.dart';
import 'package:alrasmarket/features/company/presentation/widgets/create_ad/create_ad_design.dart';
import 'package:alrasmarket/features/company/presentation/widgets/create_ad/create_ad_publish_button_widget.dart';
import 'package:alrasmarket/features/company/presentation/widgets/create_ad/create_ad_type_extra_fields_widget.dart';
import 'package:alrasmarket/features/company/presentation/widgets/create_ad/create_ad_type_fields_widget.dart';
import 'package:alrasmarket/features/company/presentation/widgets/create_ad/create_ad_type_selection_field.dart';
import 'package:alrasmarket/generated/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class CreateAdFormWidget extends StatelessWidget {
  const CreateAdFormWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<CreateAdCubit>();
    final fontFamily = AppFonts.familyFor(Localizations.localeOf(context));

    return BlocBuilder<CreateAdCubit, CreateAdFormState>(
      buildWhen: (previous, current) =>
          previous.formRevision != current.formRevision,
      builder: (context, state) {
        return Form(
          key: cubit.formKey,
          child: Column(
            key: ValueKey('create-ad-form-${state.formRevision}'),
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Media first: pick photos/videos before the name so R2 upload
              // can run while the user fills the rest of the form.
              CreateAdCommonFieldsWidget(
                key: ValueKey('common-fields-${state.formRevision}'),
                mediaFirst: true,
                showSpecs: false,
              ),
              CreateAdSectionCard(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const CreateAdFieldIcon(Icons.architecture_rounded),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          CreateAdRequiredLabel(
                            S.of(context).productName,
                            fontFamily: fontFamily,
                          ),
                          SizedBox(height: 6.h),
                          CustomTextFormField(
                            controller: cubit.productNameController,
                            label: '',
                            hintText:
                                S.of(context).examplePremiumIranianSaffron,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return S.of(context).thisFieldIsRequired;
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              BlocBuilder<CreateAdCubit, CreateAdFormState>(
                buildWhen: (previous, current) =>
                    previous.formRevision != current.formRevision ||
                    previous.selectedType != current.selectedType ||
                    previous.selectedCategoryId != current.selectedCategoryId,
                builder: (context, state) {
                  final cubit = context.read<CreateAdCubit>();
                  return CreateAdSectionCard(
                    child: Column(
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const CreateAdFieldIcon(Icons.category_outlined),
                            SizedBox(width: 12.w),
                            Expanded(
                              child: CreateAdTypeSelectionField(
                                selectedType: state.selectedType,
                                onChanged: cubit.setSelectedType,
                              ),
                            ),
                          ],
                        ),
                        if (state.selectedType == 'Categories') ...[
                          SizedBox(height: 8.h),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const CreateAdFieldIcon(Icons.grid_view_rounded),
                              SizedBox(width: 12.w),
                              Expanded(
                                child: CreateAdCategorySelectionField(
                                  categories: cubit.categories,
                                  isLoading: cubit.isLoadingCategories,
                                  selectedCategoryId: state.selectedCategoryId,
                                  onCategoryChanged: cubit.setSelectedCategory,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),
              BlocBuilder<CreateAdCubit, CreateAdFormState>(
                buildWhen: (previous, current) =>
                    previous.formRevision != current.formRevision ||
                    previous.selectedType != current.selectedType ||
                    previous.negotiationType != current.negotiationType ||
                    previous.requestFulfillmentType !=
                        current.requestFulfillmentType ||
                    previous.selectedCurrency != current.selectedCurrency ||
                    previous.selectedUnit != current.selectedUnit ||
                    previous.selectedRetailUnit != current.selectedRetailUnit ||
                    previous.enableRetailPricing != current.enableRetailPricing,
                builder: (context, state) {
                  return CreateAdSectionCard(
                    child: CreateAdTypeFieldsWidget(
                      selectedType: state.selectedType,
                      quantityController: cubit.quantityController,
                      beforeDiscountController: cubit.beforeDiscountController,
                      afterDiscountController: cubit.afterDiscountController,
                      priceController: cubit.priceController,
                      selectedNegotiationType: state.negotiationType,
                      onNegotiationChanged: cubit.setNegotiationType,
                    ),
                  );
                },
              ),
              BlocBuilder<CreateAdCubit, CreateAdFormState>(
                buildWhen: (previous, current) =>
                    previous.formRevision != current.formRevision ||
                    previous.selectedType != current.selectedType ||
                    previous.requiredDeliveryDate !=
                        current.requiredDeliveryDate ||
                    previous.originCountry != current.originCountry ||
                    previous.originPort != current.originPort ||
                    previous.destinationCountry != current.destinationCountry ||
                    previous.destinationPort != current.destinationPort ||
                    previous.requestFulfillmentType !=
                        current.requestFulfillmentType,
                builder: (context, state) {
                  return CreateAdTypeExtraFieldsWidget(
                    selectedType: state.selectedType,
                    shippingDurationController: cubit.shippingDurationController,
                    onDeliveryDateSelected: cubit.setRequiredDeliveryDate,
                  );
                },
              ),
              // Specs / packing after name & type (media already shown at top).
              CreateAdCommonFieldsWidget(
                key: ValueKey('common-fields-specs-${state.formRevision}'),
                mediaFirst: false,
                showMedia: false,
              ),
              SizedBox(height: 8.h),
              const CreateAdPublishButtonWidget(),
            ],
          ),
        );
      },
    );
  }
}
