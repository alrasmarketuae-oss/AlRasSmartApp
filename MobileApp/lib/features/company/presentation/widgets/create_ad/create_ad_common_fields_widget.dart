import 'package:alrasmarket/features/company/presentation/controller/cubit/create_ad_cubit.dart';
import 'package:alrasmarket/features/company/presentation/controller/cubit/create_ad_states.dart';
import 'package:alrasmarket/features/company/presentation/models/create_ad_type.dart';
import 'package:alrasmarket/features/company/presentation/widgets/create_ad/create_ad_packing_section.dart';
import 'package:alrasmarket/features/company/presentation/widgets/create_ad/create_ad_product_images_widget.dart';
import 'package:alrasmarket/features/company/presentation/widgets/create_ad/specifications_input_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class CreateAdCommonFieldsWidget extends StatelessWidget {
  const CreateAdCommonFieldsWidget({
    super.key,
    this.mediaFirst = false,
    this.showMedia = true,
    this.showSpecs = true,
  });

  /// When true, media appears before specs/packing (used at top of the form).
  final bool mediaFirst;

  /// When false, only specs/packing are rendered (media already shown elsewhere).
  final bool showMedia;

  /// When false, only media is rendered.
  final bool showSpecs;

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

        final media = showMedia
            ? CreateAdProductImagesWidget(
                productImages: state.productImages,
                onPickTap: () => cubit.pickProductImages(context),
                onRemove: cubit.removeProductImage,
                isCompressingMedia: state.isCompressingMedia,
                mediaCompressionProgress: state.mediaCompressionProgress,
                mediaCompressionLabel: state.mediaCompressionLabel,
              )
            : null;

        // Categories: wholesale packing/specs live in the wholesale block above.
        final specs = showSpecs && !isCategories
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const CreateAdPackingSection(),
                  SpecificationsInputWidget(
                    controller: cubit.specificationsController,
                  ),
                ],
              )
            : null;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (mediaFirst) ...[
              if (media != null) media,
              if (specs != null) specs,
            ] else ...[
              if (specs != null) specs,
              if (media != null) media,
            ],
          ],
        );
      },
    );
  }
}
