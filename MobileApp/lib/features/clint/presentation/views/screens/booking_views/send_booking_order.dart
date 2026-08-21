import 'package:alrasmarket/core/router/app_router.dart';
import 'package:alrasmarket/core/theme/app_fonts.dart';
import 'package:alrasmarket/core/theme/colors.dart';
import 'package:alrasmarket/core/ui/widgets/feedback/app_toast.dart';
import 'package:alrasmarket/core/utils/product_price_formatter.dart';
import 'package:alrasmarket/core/widgets/app_country_search_field.dart';
import 'package:alrasmarket/core/widgets/primary_button.dart';
import 'package:alrasmarket/features/clint/presentation/controller/cubit/clint_cubit.dart';
import 'package:alrasmarket/features/clint/presentation/controller/cubit/clint_states.dart';
import 'package:alrasmarket/features/clint/presentation/widgets/booking_widets/send_booking_product_card.dart';
import 'package:alrasmarket/features/clint/presentation/widgets/booking_widets/send_booking_quantity_section.dart';
import 'package:alrasmarket/features/clint/presentation/widgets/booking_widets/send_booking_your_offer_card.dart';
import 'package:alrasmarket/features/clint/presentation/widgets/search_header.dart';
import 'package:alrasmarket/features/company/data/models/my_listing_product_model.dart';
import 'package:alrasmarket/features/company/presentation/widgets/create_ad/specifications_input_widget.dart';
import 'package:alrasmarket/generated/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

class SendBookingOrderView extends StatefulWidget {
  const SendBookingOrderView({super.key, required this.product});

  final MyListingProductModel product;

  @override
  State<SendBookingOrderView> createState() => _SendBookingOrderViewState();
}

class _SendBookingOrderViewState extends State<SendBookingOrderView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<ClintCubit>().initSendBookingOrder(widget.product);
    });
  }

  @override
  Widget build(BuildContext context) {
    return _SendBookingOrderPage(product: widget.product);
  }
}

class _SendBookingOrderPage extends StatelessWidget {
  const _SendBookingOrderPage({required this.product});

  final MyListingProductModel product;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final fontFamily = AppFonts.familyFor(Localizations.localeOf(context));
    final cubit = context.read<ClintCubit>();

    return BlocListener<ClintCubit, ClintStates>(
      listenWhen: (_, current) =>
          current is BookingOrderSuccessState ||
          current is BookingOrderErrorState,
      listener: (context, state) {
        if (state is BookingOrderSuccessState) {
          context.pushReplacement(
            AppRoutes.kBookingSuccessView,
            extra: {'orderNumber': state.orderId},
          );
        } else if (state is BookingOrderErrorState) {
          AppToast.showError(context, state.message);
        }
      },
      child: BlocBuilder<ClintCubit, ClintStates>(
        buildWhen: (previous, current) {
          if (previous is BookingOrderFormState &&
              current is BookingOrderFormState) {
            return previous.selectedUnit != current.selectedUnit ||
                previous.selectedCountry != current.selectedCountry ||
                previous.selectedPort != current.selectedPort ||
                previous.ports != current.ports ||
                previous.isPortsLoading != current.isPortsLoading ||
                previous.isSubmitting != current.isSubmitting ||
                previous.quantityRevision != current.quantityRevision;
          }
          return current is BookingOrderFormState;
        },
        builder: (context, state) {
          final formState = state is BookingOrderFormState
              ? state
              : _bookingFormStateOrDefault(cubit, product);

          return SafeArea(
            child: Scaffold(
              backgroundColor: AppColors.scaffold(context),
              body: Column(
                children: [
                  SearchHeader(title: s.purchaseOrder, isSearch: false),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.fromLTRB(24.w, 16.h, 24.w, 16.h),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _sectionTitle(s.product, fontFamily),
                          SizedBox(height: 8.h),
                          SendBookingProductCard(
                            product: formState.product,
                            fontFamily: fontFamily,
                          ),
                          SizedBox(height: 20.h),
                          _sectionTitle(s.specifyQuantity, fontFamily),
                          SizedBox(height: 8.h),
                          SendBookingQuantitySection(
                            product: formState.product,
                            fontFamily: fontFamily,
                            quantityController:
                                cubit.bookingOrderQuantityController,
                            selectedUnit: formState.selectedUnit,
                            onUnitChanged: cubit.setBookingOrderUnit,
                            onQuantityChanged:
                                cubit.notifyBookingOrderQuantityChanged,
                            yourOffer: cubit.bookingYourOffer,
                            unitPrice: cubit.bookingOrderUnitPrice(
                              formState.product,
                            ),
                          ),
                          SizedBox(height: 20.h),
                          if (!product.isCategoryCatalogProduct) ...[
                            _sectionTitle(s.portOfArrival, fontFamily),
                            SizedBox(height: 8.h),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: AppCountrySearchField(
                                    value: formState.selectedCountry,
                                    fontFamily: fontFamily,
                                    hintText: s.enterCountry,
                                    onChanged: cubit.setBookingOrderCountry,
                                  ),
                                ),
                                SizedBox(width: 8.w),
                                Expanded(
                                  child: _bookingDropdownField(
                                    fontFamily: fontFamily,
                                    hint: formState.isPortsLoading
                                        ? 'Loading...'
                                        : s.enterPort,
                                    value: formState.selectedPort,
                                    items: formState.ports,
                                    isLoading: formState.isPortsLoading,
                                    enabled: formState.selectedCountry != null &&
                                        formState.ports.isNotEmpty,
                                    onChanged: cubit.setBookingOrderPort,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 20.h),
                          ],
                          SpecificationsInputWidget(
                            controller: cubit.bookingOrderNotesController,
                            labelText: s.additionalNotes,
                            hintText: s.addAnySpecialInstructionsHere,
                          ),
                          if (cubit.bookingYourOffer != null &&
                              ProductPriceFormatter.canShowPrices) ...[
                            SizedBox(height: 20.h),
                            _sectionTitle(s.yourOffer, fontFamily),
                            SizedBox(height: 8.h),
                            SendBookingYourOfferCard(
                              offer: cubit.bookingYourOffer!,
                              unit: formState.selectedUnit,
                              currency: ProductPriceFormatter.currencyCode(
                                formState.product,
                              ),
                              fontFamily: fontFamily,
                            ),
                          ],
                          SizedBox(height: 24.h),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(24.w, 0, 24.w, 24.h),
                    child: PrimaryButton(
                      text: s.sendPurchaseOrder,
                      isLoading: formState.isSubmitting,
                      onPressed: formState.isSubmitting
                          ? null
                          : () => cubit.submitBookingOrder(),
                      height: 48.h,
                      borderRadius: 8.r,
                      backgroundColor: const Color(0xFF3A7DC5),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  BookingOrderFormState _bookingFormStateOrDefault(
    ClintCubit cubit,
    MyListingProductModel product,
  ) {
    return BookingOrderFormState(
      product: product,
      selectedUnit: product.unitName.trim().isEmpty
          ? 'Ton'
          : product.unitName.trim(),
    );
  }

  Widget _sectionTitle(String title, String fontFamily) {
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

  Widget _bookingDropdownField({
    required String fontFamily,
    required String hint,
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    bool isLoading = false,
    bool enabled = true,
  }) {
    return DropdownButtonFormField<String>(
      value: items.contains(value) ? value : null,
      isExpanded: true,
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      hint: Text(
        hint,
        style: TextStyle(
          color: const Color(0xFF333333).withValues(alpha: 0.4),
          fontFamily: fontFamily,
          fontSize: 14.sp,
        ),
      ),
      icon: isLoading
          ? SizedBox(
              width: 18.w,
              height: 18.h,
              child: const CircularProgressIndicator(strokeWidth: 2),
            )
          : Icon(
              Icons.keyboard_arrow_down_rounded,
              color: const Color(0xFF6B7280),
              size: 20.sp,
            ),
      dropdownColor: Colors.white,
      menuMaxHeight: 320.h,
      style: TextStyle(
        color: const Color(0xFF333333),
        fontFamily: fontFamily,
        fontSize: 14.sp,
      ),
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white,
        contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 14.h),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.r),
          borderSide: const BorderSide(color: Color(0xFFEAECF0), width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.r),
          borderSide: const BorderSide(color: Color(0xFF3A7DC5), width: 1.5),
        ),
      ),
      items: items
          .map(
            (item) => DropdownMenuItem(
              value: item,
              child: Text(
                item,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          )
          .toList(),
      onChanged: enabled && !isLoading ? onChanged : null,
    );
  }
}
