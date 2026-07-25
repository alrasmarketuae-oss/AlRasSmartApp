import 'package:alrasmarket/core/theme/app_fonts.dart';
import 'package:alrasmarket/features/company/presentation/controller/cubit/create_ad_cubit.dart';
import 'package:alrasmarket/features/company/presentation/controller/cubit/create_ad_states.dart';
import 'package:alrasmarket/features/company/presentation/models/create_ad_packing_options.dart';
import 'package:alrasmarket/features/company/presentation/widgets/create_ad/create_ad_design.dart';
import 'package:alrasmarket/features/company/presentation/widgets/create_ad/create_ad_form_field_styles.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class CreateAdPackingSection extends StatelessWidget {
  const CreateAdPackingSection({
    super.key,
    this.controller,
    this.labelText,
  });

  final TextEditingController? controller;
  final String? labelText;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<CreateAdCubit>();
    final fontFamily = AppFonts.familyFor(Localizations.localeOf(context));
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final packingController = controller ?? cubit.packingKgController;
    final label = labelText ??
        (isAr ? 'التعبئة (اختياري)' : 'Packing (optional)');

    return BlocBuilder<CreateAdCubit, CreateAdFormState>(
      buildWhen: (previous, current) =>
          previous.formRevision != current.formRevision,
      builder: (context, state) {
        final fieldTextStyle = TextStyle(
          color: CreateAdDesign.text,
          fontFamily: fontFamily,
          fontSize: 14.sp,
          fontWeight: FontWeight.w600,
          height: 1.2,
        );

        return CreateAdSectionCard(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const CreateAdFieldIcon(Icons.inventory_2_outlined),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    CreateAdRequiredLabel(
                      label,
                      fontFamily: fontFamily,
                      required: false,
                    ),
                    SizedBox(height: 10.h),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: CreateAdFormFieldStyles.rowFieldHeight,
                            child: TextFormField(
                              controller: packingController,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                LengthLimitingTextInputFormatter(3),
                              ],
                              textAlignVertical: TextAlignVertical.center,
                              style: fieldTextStyle,
                              decoration: CreateAdFormFieldStyles.rowDecoration(
                                hintText: isAr ? 'مثال: 25' : 'e.g. 25',
                                fontFamily: fontFamily,
                              ),
                              validator: (value) {
                                final text = value?.trim() ?? '';
                                if (text.isEmpty) return null;
                                final parsed = int.tryParse(text);
                                if (parsed == null ||
                                    parsed < 1 ||
                                    parsed > CreateAdPackingOptions.maxValue) {
                                  return isAr
                                      ? 'أدخل رقم من 1 إلى 255'
                                      : 'Enter a number from 1 to 255';
                                }
                                return null;
                              },
                            ),
                          ),
                        ),
                        SizedBox(width: 10.w),
                        Text(
                          'kg',
                          style: TextStyle(
                            color: CreateAdDesign.text,
                            fontFamily: fontFamily,
                            fontSize: 15.sp,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
