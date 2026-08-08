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
    this.isRetail = false,
  });

  final TextEditingController? controller;
  final String? labelText;
  final bool isRetail;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<CreateAdCubit>();
    final fontFamily = AppFonts.familyFor(Localizations.localeOf(context));
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final packingController = controller ??
        (isRetail ? cubit.retailPackingKgController : cubit.packingKgController);
    final otherController = isRetail
        ? cubit.retailOtherPackingController
        : cubit.otherPackingController;
    final label = labelText ??
        (isAr ? 'التعبئة (اختياري)' : 'Packing (optional)');
    final otherLabel = isAr ? 'تعبئة أخرى' : 'Other packing';

    return BlocBuilder<CreateAdCubit, CreateAdFormState>(
      buildWhen: (previous, current) =>
          previous.formRevision != current.formRevision ||
          previous.otherPacking != current.otherPacking ||
          previous.retailOtherPacking != current.retailOtherPacking,
      builder: (context, state) {
        final isOther =
            isRetail ? state.retailOtherPacking : state.otherPacking;
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
                    Row(
                      children: [
                        Expanded(
                          child: CreateAdRequiredLabel(
                            label,
                            fontFamily: fontFamily,
                            required: false,
                          ),
                        ),
                        Text(
                          otherLabel,
                          style: TextStyle(
                            color: CreateAdDesign.text,
                            fontFamily: fontFamily,
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(width: 4.w),
                        Switch.adaptive(
                          value: isOther,
                          activeThumbColor: const Color(0xFF3A7DC5),
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                          onChanged: (value) =>
                              cubit.setOtherPacking(value, isRetail: isRetail),
                        ),
                      ],
                    ),
                    SizedBox(height: 10.h),
                    if (isOther)
                      SizedBox(
                        height: CreateAdFormFieldStyles.rowFieldHeight,
                        child: TextFormField(
                          controller: otherController,
                          keyboardType: TextInputType.text,
                          inputFormatters: [
                            LengthLimitingTextInputFormatter(60),
                          ],
                          textAlignVertical: TextAlignVertical.center,
                          style: fieldTextStyle,
                          decoration: CreateAdFormFieldStyles.rowDecoration(
                            hintText: 'e.g. 1.5 litre',
                            fontFamily: fontFamily,
                          ),
                        ),
                      )
                    else
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
                                decoration:
                                    CreateAdFormFieldStyles.rowDecoration(
                                  hintText: isAr ? 'مثال: 25' : 'e.g. 25',
                                  fontFamily: fontFamily,
                                ),
                                validator: (value) {
                                  final text = value?.trim() ?? '';
                                  if (text.isEmpty) return null;
                                  final parsed = int.tryParse(text);
                                  if (parsed == null ||
                                      parsed < 1 ||
                                      parsed >
                                          CreateAdPackingOptions.maxValue) {
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
