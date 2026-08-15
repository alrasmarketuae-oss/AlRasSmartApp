import 'package:alrasmarket/core/theme/app_fonts.dart';
import 'package:alrasmarket/features/company/presentation/widgets/create_ad/create_ad_design.dart';
import 'package:alrasmarket/generated/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class SpecificationsInputWidget extends StatelessWidget {
  const SpecificationsInputWidget({
    super.key,
    this.controller,
    this.labelText,
    this.hintText,
    this.onChanged,
    this.validator,
  });

  final TextEditingController? controller;
  final String? labelText;
  final String? hintText;
  final ValueChanged<String>? onChanged;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    final fontFamily = AppFonts.familyFor(Localizations.localeOf(context));
    final resolvedLabel = labelText ?? S.of(context).specifications;
    final resolvedHint =
        hintText ?? S.of(context).specifyRequiredSpecifications;

    return CreateAdSectionCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CreateAdFieldIcon(Icons.list_alt_rounded),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                CreateAdRequiredLabel(
                  resolvedLabel,
                  fontFamily: fontFamily,
                  required: false,
                ),
                SizedBox(height: 10.h),
                TextFormField(
                  controller: controller,
                  onChanged: onChanged,
                  maxLines: 4,
                  maxLength: 500,
                  validator: validator,
                  style: TextStyle(
                    color: CreateAdDesign.text,
                    fontFamily: fontFamily,
                    fontSize: 14.sp,
                    height: 1.5,
                  ),
                  decoration: InputDecoration(
                    hintText: resolvedHint,
                    hintStyle: TextStyle(
                      color: CreateAdDesign.muted,
                      fontFamily: fontFamily,
                      fontSize: 14.sp,
                      height: 1.5,
                    ),
                    counterStyle: TextStyle(
                      fontFamily: fontFamily,
                      fontSize: 11.sp,
                      color: CreateAdDesign.muted,
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 14.w,
                      vertical: 12.h,
                    ),
                    filled: true,
                    fillColor: CreateAdDesign.cardBg,
                    border: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(CreateAdDesign.fieldRadius),
                      borderSide: BorderSide(
                        color: CreateAdDesign.border,
                        width: 1.5,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(CreateAdDesign.fieldRadius),
                      borderSide: BorderSide(
                        color: CreateAdDesign.border,
                        width: 1.5,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(CreateAdDesign.fieldRadius),
                      borderSide: const BorderSide(
                        color: CreateAdDesign.brand,
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
