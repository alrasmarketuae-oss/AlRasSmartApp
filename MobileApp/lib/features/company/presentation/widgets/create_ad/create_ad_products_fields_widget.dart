import 'package:alrasmarket/core/theme/app_fonts.dart';
import 'package:alrasmarket/features/company/presentation/controller/cubit/create_ad_cubit.dart';
import 'package:alrasmarket/features/company/presentation/controller/cubit/create_ad_states.dart';
import 'package:alrasmarket/features/company/presentation/helpers/create_ad_price_labels.dart';
import 'package:alrasmarket/features/company/presentation/models/create_ad_currency.dart';
import 'package:alrasmarket/features/company/presentation/models/negotiation_type.dart';
import 'package:alrasmarket/features/company/presentation/widgets/create_ad/create_ad_design.dart';
import 'package:alrasmarket/features/company/presentation/widgets/create_ad/create_ad_packing_section.dart';
import 'package:alrasmarket/features/company/presentation/widgets/create_ad/create_ad_price_negotiation_section.dart';
import 'package:alrasmarket/features/company/presentation/widgets/create_ad/create_ad_pricing_row_section.dart';
import 'package:alrasmarket/features/company/presentation/widgets/create_ad/negotiation_type_radio_widget.dart';
import 'package:alrasmarket/features/company/presentation/widgets/create_ad/request_fulfillment_radio_widget.dart';
import 'package:alrasmarket/features/company/presentation/widgets/create_ad/specifications_input_widget.dart';
import 'package:alrasmarket/generated/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class CreateAdProductsFieldsWidget extends StatelessWidget {
  const CreateAdProductsFieldsWidget({
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

  static const _retailTint = Color(0xFFECFDF5);
  static const _retailBorder = Color(0xFFA7F3D0);
  static const _wholesaleTint = Color(0xFFF8FAFC);
  static const _wholesaleBorder = Color(0xFFE2E8F0);

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<CreateAdCubit>();
    final s = S.of(context);
    final fontFamily = AppFonts.familyFor(Localizations.localeOf(context));
    final isAr = Localizations.localeOf(context).languageCode == 'ar';

    return BlocBuilder<CreateAdCubit, CreateAdFormState>(
      buildWhen: (previous, current) =>
          previous.enableRetailPricing != current.enableRetailPricing ||
          previous.selectedRetailUnit != current.selectedRetailUnit ||
          previous.formRevision != current.formRevision ||
          previous.selectedUnit != current.selectedUnit ||
          previous.selectedCurrency != current.selectedCurrency,
      builder: (context, state) {
        final hybrid = state.enableRetailPricing;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _ChannelSection(
              tint: _wholesaleTint,
              border: _wholesaleBorder,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    isAr ? 'معلومات الجملة' : 'Wholesale details',
                    style: TextStyle(
                      color: CreateAdDesign.text,
                      fontFamily: fontFamily,
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w700,
                      height: 1.4,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  CreateAdPriceNegotiationSection(
                    quantityController: quantityController,
                    priceController: priceController,
                    selectedNegotiationType: selectedNegotiationType,
                    onNegotiationChanged: onNegotiationChanged,
                    hintText: s.enterProductPrice,
                    isProductPrice: true,
                  ),
                  SizedBox(height: 8.h),
                  NegotiationTypeRadioWidget(
                    selectedType: selectedNegotiationType,
                    onChanged: onNegotiationChanged,
                  ),
                  SizedBox(height: 10.h),
                  BlocBuilder<CreateAdCubit, CreateAdFormState>(
                    buildWhen: (previous, current) =>
                        previous.requestFulfillmentType !=
                        current.requestFulfillmentType,
                    builder: (context, priceTypeState) {
                      return RequestFulfillmentRadioWidget(
                        selectedType: priceTypeState.requestFulfillmentType,
                        onChanged: cubit.setRequestFulfillmentType,
                      );
                    },
                  ),
                  SizedBox(height: 10.h),
                  CreateAdPackingSection(
                    labelText: hybrid
                        ? (isAr
                            ? 'تعبئة الجملة (اختياري)'
                            : 'Wholesale packing (optional)')
                        : null,
                  ),
                  SpecificationsInputWidget(
                    controller: cubit.specificationsController,
                    labelText: hybrid
                        ? (isAr
                            ? 'مواصفات الجملة'
                            : 'Wholesale specifications')
                        : null,
                  ),
                ],
              ),
            ),
            SizedBox(height: 12.h),
            _RetailPricingSwitchRow(
              enabled: state.enableRetailPricing,
              onChanged: (enabled) => _onRetailPricingToggled(
                context,
                cubit: cubit,
                enabled: enabled,
              ),
              fontFamily: fontFamily,
              isAr: isAr,
            ),
            if (state.enableRetailPricing) ...[
              SizedBox(height: 12.h),
              _ChannelSection(
                tint: _retailTint,
                border: _retailBorder,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      isAr ? 'معلومات التجزئة' : 'Retail details',
                      style: TextStyle(
                        color: const Color(0xFF065F46),
                        fontFamily: fontFamily,
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w700,
                        height: 1.4,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    _CopyWholesaleSuggestionChip(
                      fontFamily: fontFamily,
                      onTap: () => _promptCopyWholesaleToRetail(
                        context,
                        cubit: cubit,
                      ),
                    ),
                    SizedBox(height: 10.h),
                    CreateAdPricingRowSection(
                      quantityController: cubit.retailQuantityController,
                      priceController: cubit.retailPriceController,
                      quantityLabel: CreateAdPriceLabels.quantityPerUnitLabel(
                        s,
                        state.selectedRetailUnit,
                      ),
                      priceLabel: s.retailPriceLabel,
                      priceHint: CreateAdPriceLabels.enterPricePerUnitHint(
                        s,
                        state.selectedRetailUnit,
                      ),
                      selectedCurrency: CreateAdCurrency.aed,
                      onCurrencyChanged: (_) {},
                      selectedUnit: state.selectedRetailUnit,
                      onUnitChanged: cubit.setSelectedRetailUnit,
                      isCurrencyLocked: true,
                    ),
                    SizedBox(height: 10.h),
                    CreateAdPackingSection(
                      controller: cubit.retailPackingKgController,
                      isRetail: true,
                      labelText: isAr
                          ? 'تعبئة التجزئة (اختياري)'
                          : 'Retail packing (optional)',
                    ),
                    SpecificationsInputWidget(
                      controller: cubit.retailSpecificationsController,
                      labelText: isAr
                          ? 'مواصفات التجزئة'
                          : 'Retail specifications',
                      hintText: isAr
                          ? 'اكتب مواصفات قناة التجزئة'
                          : 'Enter retail channel specifications',
                      validator: (value) {
                        if (!state.enableRetailPricing) return null;
                        if ((value?.trim() ?? '').isEmpty) {
                          return isAr
                              ? 'مواصفات التجزئة مطلوبة'
                              : 'Retail specifications are required';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _ChannelSection extends StatelessWidget {
  const _ChannelSection({
    required this.tint,
    required this.border,
    required this.child,
  });

  final Color tint;
  final Color border;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: tint,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: border),
      ),
      child: child,
    );
  }
}

Future<void> _onRetailPricingToggled(
  BuildContext context, {
  required CreateAdCubit cubit,
  required bool enabled,
}) async {
  if (!enabled) {
    cubit.setEnableRetailPricing(false);
    return;
  }

  cubit.setEnableRetailPricing(true);
  if (!context.mounted) return;
  await _promptCopyWholesaleToRetail(
    context,
    cubit: cubit,
  );
}

Future<void> _promptCopyWholesaleToRetail(
  BuildContext context, {
  required CreateAdCubit cubit,
}) async {
  final s = S.of(context);
  final fontFamily = AppFonts.familyFor(Localizations.localeOf(context));

  final accepted = await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.r),
        ),
        title: Text(
          s.copyWholesaleToRetailTitle,
          style: TextStyle(
            fontFamily: fontFamily,
            fontSize: 18.sp,
            fontWeight: FontWeight.w700,
            color: CreateAdDesign.text,
          ),
        ),
        content: Text(
          s.copyWholesaleToRetailBody,
          style: TextStyle(
            fontFamily: fontFamily,
            fontSize: 14.sp,
            color: CreateAdDesign.muted,
            height: 1.5,
          ),
        ),
        actionsAlignment: MainAxisAlignment.spaceBetween,
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(
              s.copyWholesaleToRetailDecline,
              style: TextStyle(
                fontFamily: fontFamily,
                fontSize: 13.sp,
                fontWeight: FontWeight.w600,
                color: CreateAdDesign.muted,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(
              s.copyWholesaleToRetailAccept,
              style: TextStyle(
                fontFamily: fontFamily,
                fontSize: 13.sp,
                fontWeight: FontWeight.w700,
                color: CreateAdDesign.brand,
              ),
            ),
          ),
        ],
      );
    },
  );

  if (accepted == true) {
    cubit.copyWholesaleChannelToRetail();
  }
}

class _CopyWholesaleSuggestionChip extends StatelessWidget {
  const _CopyWholesaleSuggestionChip({
    required this.fontFamily,
    required this.onTap,
  });

  final String fontFamily;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20.r),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20.r),
              border: Border.all(color: const Color(0xFFA7F3D0)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.content_copy_rounded,
                  size: 14.sp,
                  color: const Color(0xFF065F46),
                ),
                SizedBox(width: 6.w),
                Flexible(
                  child: Text(
                    s.copyWholesaleToRetailAction,
                    style: TextStyle(
                      fontFamily: fontFamily,
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF065F46),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RetailPricingSwitchRow extends StatelessWidget {
  const _RetailPricingSwitchRow({
    required this.enabled,
    required this.onChanged,
    required this.fontFamily,
    required this.isAr,
  });

  final bool enabled;
  final ValueChanged<bool> onChanged;
  final String fontFamily;
  final bool isAr;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: enabled
            ? const Color(0xFFECFDF5)
            : CreateAdDesign.iconBg.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(
          color: enabled
              ? const Color(0xFFA7F3D0)
              : CreateAdDesign.border,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        s.addRetailPriceQuestion,
                        style: TextStyle(
                          color: CreateAdDesign.text,
                          fontFamily: fontFamily,
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w700,
                          height: 1.3,
                        ),
                      ),
                    ),
                    SizedBox(width: 4.w),
                    GestureDetector(
                      onTap: () => _showRetailPricingInfoDialog(context),
                      child: Icon(
                        Icons.info_outline_rounded,
                        size: 18.sp,
                        color: CreateAdDesign.brand,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 6.h),
                Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                  decoration: BoxDecoration(
                    color: CreateAdDesign.brand,
                    borderRadius: BorderRadius.circular(20.r),
                  ),
                  child: Text(
                    isAr ? 'موصى به' : 'Recommended',
                    style: TextStyle(
                      color: Colors.white,
                      fontFamily: fontFamily,
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: enabled,
            onChanged: onChanged,
            activeTrackColor: const Color(0xFF10B981),
            activeThumbColor: Colors.white,
          ),
        ],
      ),
    );
  }

  Future<void> _showRetailPricingInfoDialog(BuildContext context) async {
    final s = S.of(context);
    final fontFamily = AppFonts.familyFor(Localizations.localeOf(context));

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
          ),
          title: Text(
            s.retailPricingInfoTitle,
            style: TextStyle(
              fontFamily: fontFamily,
              fontSize: 18.sp,
              fontWeight: FontWeight.w700,
              color: CreateAdDesign.text,
            ),
          ),
          content: Text(
            s.retailPricingInfoBody,
            style: TextStyle(
              fontFamily: fontFamily,
              fontSize: 14.sp,
              color: CreateAdDesign.muted,
              height: 1.5,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(
                s.gotIt,
                style: TextStyle(
                  fontFamily: fontFamily,
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  color: CreateAdDesign.brand,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
