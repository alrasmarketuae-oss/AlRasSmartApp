import 'package:alrasmarket/features/company/presentation/controller/cubit/create_ad_cubit.dart';
import 'package:alrasmarket/features/company/presentation/controller/cubit/create_ad_states.dart';
import 'package:alrasmarket/features/company/presentation/models/create_ad_type.dart';
import 'package:alrasmarket/features/company/presentation/widgets/create_ad/create_ad_packing_section.dart';
import 'package:alrasmarket/features/company/presentation/widgets/create_ad/create_ad_product_images_widget.dart';
import 'package:alrasmarket/features/company/presentation/widgets/create_ad/specifications_input_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class CreateAdCommonFieldsWidget extends StatelessWidget {
  const CreateAdCommonFieldsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<CreateAdCubit>();

    return BlocBuilder<CreateAdCubit, CreateAdFormState>(
      buildWhen: (previous, current) =>
          previous.formRevision != current.formRevision ||
          previous.productImages != current.productImages ||
          previous.selectedCategoryId != current.selectedCategoryId ||
          previous.selectedType != current.selectedType ||
          previous.isCompressingMedia != current.isCompressingMedia ||
          previous.mediaCompressionProgress != current.mediaCompressionProgress,
      builder: (context, state) {
        final isCategories =
            state.selectedType == CreateAdType.categories.label;

        // Categories: wholesale specs/packing live in the wholesale block above.
        // Other ad types keep specs + packing here.
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (!isCategories) ...[
              SpecificationsInputWidget(
                controller: cubit.specificationsController,
              ),
              const CreateAdPackingSection(),
            ],
            CreateAdProductImagesWidget(
              productImages: state.productImages,
              onPickTap: () => cubit.pickProductImages(context),
              onRemove: cubit.removeProductImage,
              isCompressingMedia: state.isCompressingMedia,
              mediaCompressionProgress: state.mediaCompressionProgress,
              mediaCompressionLabel: state.mediaCompressionLabel,
            ),
          ],
        );
      },
    );
  }
}
