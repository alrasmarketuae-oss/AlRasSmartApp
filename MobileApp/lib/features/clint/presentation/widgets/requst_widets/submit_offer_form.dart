import 'package:alrasmarket/core/theme/app_fonts.dart';
import 'package:alrasmarket/features/clint/presentation/controller/cubit/clint_cubit.dart';
import 'package:alrasmarket/features/clint/presentation/controller/cubit/clint_states.dart';
import 'package:alrasmarket/features/clint/presentation/widgets/requst_widets/submit_ditels_card.dart';
import 'package:alrasmarket/features/clint/presentation/widgets/requst_widets/submit_offer_button.dart';
import 'package:alrasmarket/features/clint/presentation/widgets/requst_widets/submit_offer_detils_filds.dart';
import 'package:alrasmarket/features/company/presentation/widgets/create_ad/create_ad_product_images_widget.dart';
import 'package:alrasmarket/generated/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class SubmitOfferFormWidget extends StatelessWidget {
  const SubmitOfferFormWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<ClintCubit>();
    final fontFamily = AppFonts.familyFor(Localizations.localeOf(context));

    return Form(
      key: cubit.formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildSectionTitle(S.of(context).orderDetails, fontFamily),
          SizedBox(height: 8.h),
          const OrderDetailsCardWidget(),
          SizedBox(height: 20.h),

          _buildSectionTitle(S.of(context).offerDetails, fontFamily),
          SizedBox(height: 8.h),
          const OfferDetailsFieldsWidget(),
          SizedBox(height: 20.h),

          BlocBuilder<ClintCubit, ClintStates>(
            buildWhen: (previous, current) {
              if (previous is! SubmitOfferFormState ||
                  current is! SubmitOfferFormState) {
                return true;
              }
              return previous.productImages != current.productImages;
            },
            builder: (context, state) {
              final images = state is SubmitOfferFormState
                  ? state.productImages
                  : const <String>[];
              return CreateAdProductImagesWidget(
                productImages: images,
                onPickTap: () => cubit.pickProductImages(context),
                onRemove: cubit.removeProductImage,
              );
            },
          ),
          SizedBox(height: 20.h),

          Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            decoration: BoxDecoration(
              color: const Color(0xFFE6F2FF),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Row(
              children: [
                const Icon(Icons.info, color: Color(0xFF3A7DC5), size: 20),
                SizedBox(width: 12.w),
                Expanded(
                  child: Text(
                    S
                        .of(context)
                        .yourOfferWillBeSentToTheRequesterWhoCanReviewAndRespond,
                    style: TextStyle(
                      color: const Color(0xFF1E40AF),
                      fontFamily: fontFamily,
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 24.h),

          SubmitOfferButtonWidget(
            onPressed: () => context.read<ClintCubit>().submitOfferForm(),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, String fontFamily) {
    return Text(
      title,
      style: TextStyle(
        color: const Color(0xFF333333),
        fontFamily: fontFamily,
        fontSize: 15.sp,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}
