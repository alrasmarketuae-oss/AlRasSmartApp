import 'dart:async';

import 'package:alrasmarket/core/widgets/animated_ellipsis_text.dart';
import 'package:alrasmarket/core/widgets/primary_button_with_cancel.dart';
import 'package:alrasmarket/core/ui/widgets/feedback/app_toast.dart';
import 'package:alrasmarket/core/utils/product_price_formatter.dart';
import 'package:alrasmarket/core/utils/product_quantity_validator.dart';
import 'package:alrasmarket/core/utils/product_stock.dart';
import 'package:alrasmarket/core/utils/thousands_separator_input_formatter.dart';
import 'package:alrasmarket/core/utils/user_facing_error_localizer.dart';
import 'package:alrasmarket/core/router/app_router.dart';
import 'package:alrasmarket/core/services/product_view_service.dart';
import 'package:alrasmarket/core/services_locator/services_locator.dart';
import 'package:alrasmarket/core/theme/app_fonts.dart';
import 'package:alrasmarket/features/clint/domain/entities/cart_entity.dart';
import 'package:alrasmarket/features/clint/presentation/controller/cubit/clint_cubit.dart';
import 'package:alrasmarket/features/clint/presentation/controller/cubit/clint_states.dart';
import 'package:alrasmarket/features/clint/presentation/helpers/ask_for_price_helper.dart';
import 'package:alrasmarket/features/clint/presentation/helpers/product_details_opener.dart';
import 'package:alrasmarket/features/clint/presentation/helpers/product_navigation_helper.dart';
import 'package:alrasmarket/features/clint/presentation/helpers/product_ownership_helper.dart';
import 'package:alrasmarket/features/clint/presentation/widgets/booking_widets/booking_details_app_bar.dart';
import 'package:alrasmarket/features/clint/presentation/widgets/booking_widets/booking_details_design.dart';
import 'package:alrasmarket/features/clint/presentation/widgets/cannot_order_own_product_banner.dart';
import 'package:alrasmarket/features/clint/presentation/widgets/product_sold_out_label.dart';
import 'package:alrasmarket/features/clint/presentation/widgets/retail_widets/offer_ad_details_body.dart';
import 'package:alrasmarket/features/clint/presentation/widgets/retail_widets/retail_ad_details_body.dart';
import 'package:alrasmarket/features/clint/presentation/widgets/retail_widets/retail_details_mapper.dart';
import 'package:alrasmarket/features/company/data/models/my_listing_product_model.dart';
import 'package:alrasmarket/generated/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

class RetailProductDetailsView extends StatefulWidget {
  RetailProductDetailsView({
    super.key,
    required this.product,
    required this.isOffer,
    this.preferRetailChannel = false,
  });

  final MyListingProductModel product;
  bool isOffer;

  /// Opened from retail feed — hybrid uses Add to Cart (not Purchase Order).
  final bool preferRetailChannel;

  @override
  State<RetailProductDetailsView> createState() =>
      _RetailProductDetailsViewState();
}

class _RetailProductDetailsViewState extends State<RetailProductDetailsView> {
  final _quantityFormKey = GlobalKey<FormState>();
  late final TextEditingController _quantityController;
  late final ClintCubit _clintCubit;
  late final bool _ownsQuantityController;
  late MyListingProductModel _product;
  double _total = 0;
  bool _isAddingToCart = false;

  @override
  void initState() {
    super.initState();
    _clintCubit = sl<ClintCubit>();
    _product = widget.product;

    if (_product.isRequestProduct) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        context.pushReplacement(
          AppRoutes.kRequestDetailsView,
          extra: {'product': _product},
        );
      });
      _quantityController = TextEditingController(text: '0');
      _ownsQuantityController = true;
      return;
    }

    // Fire-and-forget: count a buyer opening this product details screen.
    unawaited(
      ProductViewService.trackProductView(
        _product.productId,
        product: _product,
      ),
    );

    widget.isOffer = widget.isOffer && _product.isOfferProduct;

    if (widget.isOffer) {
      _clintCubit.initOfferOrder(_product);
      _quantityController = _clintCubit.offerOrderQuantityController;
      _ownsQuantityController = false;
    } else {
      _quantityController = TextEditingController(text: '0');
      _ownsQuantityController = true;
    }
    _recalculateTotal();
    unawaited(_refreshFromApi());
  }

  Future<void> _refreshFromApi() async {
    final id = widget.product.productId.trim();
    if (id.isEmpty) return;

    final fresh = await ProductDetailsOpener.fetchPublicProductById(
      id,
      asRetail: widget.preferRetailChannel,
    );
    if (!mounted || fresh == null) return;

    setState(() {
      _product = fresh;
      widget.isOffer = widget.isOffer && fresh.isOfferProduct;
      if (widget.isOffer) {
        _clintCubit.initOfferOrder(fresh);
      }
      _recalculateTotal();
    });
  }

  @override
  void dispose() {
    if (_ownsQuantityController) {
      _quantityController.dispose();
    }
    super.dispose();
  }

  Future<void> _addToCart(String unit) async {
    if (_isAddingToCart) return;
    if (!(_quantityFormKey.currentState?.validate() ?? false)) return;

    final quantity =
        ThousandsNumberInput.parseDouble(_quantityController.text) ?? 0;
    if (quantity <= 0) return;

    setState(() => _isAddingToCart = true);
    try {
      if (await _redirectIfCartAtStockLimit(quantity)) {
        return;
      }

      await _clintCubit.addProductToCart(
        productId: _product.productId,
        quantity: quantity,
        unitName: unit,
      );
      if (!mounted) return;

      final state = _clintCubit.state;
      if (state is CartLoadedState && state.errorMessage == null) {
        context.push(AppRoutes.kCartView);
        return;
      }

      final rawMessage = state is CartErrorState
          ? state.message
          : state is CartLoadedState
          ? state.errorMessage
          : null;
      final message = UserFacingErrorLocalizer.localizeCartError(
        rawMessage,
        availableQuantity: _availableProductQuantity(),
      );

      if (rawMessage != null &&
          UserFacingErrorLocalizer.isCartStockLimitMessage(rawMessage)) {
        AppToast.showInfo(context, message);
        context.push(AppRoutes.kCartView);
        return;
      }

      AppToast.showError(context, message);
    } finally {
      if (mounted) {
        setState(() => _isAddingToCart = false);
      } else {
        _isAddingToCart = false;
      }
    }
  }

  double _availableProductQuantity() {
    return ProductStock.parseQuantity(_product.quantity) ?? 0;
  }

  double _cartQuantityForProduct(CartEntity cart) {
    return cart.items
        .where((item) => item.productId == _product.productId)
        .fold(0.0, (sum, item) => sum + item.quantity);
  }

  String _formatQuantity(double quantity) {
    if (quantity == quantity.roundToDouble()) {
      return quantity.toInt().toString();
    }
    return quantity.toString();
  }

  Future<bool> _redirectIfCartAtStockLimit(double requestedQuantity) async {
    final available = _availableProductQuantity();
    if (available <= 0) return false;

    await _clintCubit.loadCart();
    if (!mounted) return true;

    final state = _clintCubit.state;
    if (state is! CartLoadedState) return false;

    final inCart = _cartQuantityForProduct(state.cart);
    if (inCart + 0.0001 < available &&
        inCart + requestedQuantity <= available + 0.0001) {
      return false;
    }

    AppToast.showInfo(
      context,
      S.of(context).cartMaxAvailableInStock(_formatQuantity(available)),
    );
    context.push(AppRoutes.kCartView);
    return true;
  }

  void _recalculateTotal() {
    final quantity =
        ThousandsNumberInput.parseDouble(_quantityController.text) ?? 0;
    final preferRetail = ProductNavigationHelper.resolvePreferRetailChannel(
      widget.preferRetailChannel,
    );
    setState(() {
      _total = RetailDetailsMapper.unitPrice(
            _product,
            preferRetail: preferRetail && !widget.isOffer,
          ) *
          quantity;
    });
    if (widget.isOffer) {
      _clintCubit.notifyOfferOrderQuantityChanged();
    }
  }

  void _submitOfferOrder() {
    if (_isAddingToCart) return;
    if (!(_quantityFormKey.currentState?.validate() ?? false)) return;
    final state = _clintCubit.state;
    if (state is OfferOrderFormState && state.isSubmitting) return;
    _clintCubit.submitOfferOrder();
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final fontFamily = AppFonts.familyFor(Localizations.localeOf(context));
    final unit = _product
        .unitNameForChannel(preferRetail: !widget.isOffer)
        .trim();

    return BlocProvider.value(
      value: _clintCubit,
      child: BlocListener<ClintCubit, ClintStates>(
        listenWhen: (_, current) =>
            current is OfferOrderSuccessState ||
            current is OfferOrderErrorState,
        listener: (context, state) {
          if (state is OfferOrderSuccessState) {
            context.pushReplacement(
              AppRoutes.kBookingSuccessView,
              extra: {'orderNumber': state.orderId},
            );
          } else if (state is OfferOrderErrorState) {
            AppToast.showError(context, state.message);
          }
        },
        child: BlocBuilder<ClintCubit, ClintStates>(
          buildWhen: (previous, current) {
            if (previous is OfferOrderFormState &&
                current is OfferOrderFormState) {
              return previous.isSubmitting != current.isSubmitting;
            }
            return current is OfferOrderFormState;
          },
          builder: (context, state) {
            final isSubmitting =
                state is OfferOrderFormState && state.isSubmitting;

            final preferRetail = ProductNavigationHelper
                .resolvePreferRetailChannel(widget.preferRetailChannel);
            final isRetailCart = !widget.isOffer &&
                (preferRetail
                    ? _product.isRetailFeedProduct
                    : _product.isPureRetailProduct);
            final soldOut = ProductStock.isSoldOut(_product);
            final isOwnAd =
                ProductOwnershipHelper.isOwnedByCurrentUser(_product);
            final ctaBusy = isRetailCart ? _isAddingToCart : isSubmitting;
            final idleLabel = widget.isOffer
                ? s.purchaseOrder
                : (isRetailCart ? s.addToCart : s.purchaseOrder);
            final busyLabel =
                isRetailCart ? s.addingToCart : s.sending;

            return Scaffold(
              backgroundColor: BookingDetailsDesign.pageBg,
              appBar: BookingDetailsAppBar(product: _product),
              body: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 16.h),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (soldOut) ...[
                            ProductSoldOutLabel(fontFamily: fontFamily),
                            SizedBox(height: 12.h),
                          ],
                          if (widget.isOffer)
                            OfferAdDetailsBody(
                              product: _product,
                              fontFamily: fontFamily,
                              quantityController: _quantityController,
                              quantityFormKey: _quantityFormKey,
                              total: _total,
                              onQuantityChanged: _recalculateTotal,
                              quantityValidator: (value) =>
                                  ProductQuantityValidator
                                      .validateRetailOrderQuantity(
                                rawValue: value,
                                s: s,
                                product: _product,
                              ),
                            )
                          else
                            RetailAdDetailsBody(
                              product: _product,
                              fontFamily: fontFamily,
                              quantityController: _quantityController,
                              quantityFormKey: _quantityFormKey,
                              total: _total,
                              onQuantityChanged: _recalculateTotal,
                              quantityValidator: (value) =>
                                  ProductQuantityValidator
                                      .validateRetailOrderQuantity(
                                rawValue: value,
                                s: s,
                                product: _product,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  if (!soldOut && isOwnAd)
                    CannotOrderOwnProductBanner(fontFamily: fontFamily)
                  else if (!soldOut)
                    SafeArea(
                      top: false,
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 12.h),
                        child: Builder(
                          builder: (context) {
                            final buyButton = isRetailCart
                                ? SizedBox(
                                    width: double.infinity,
                                    height: 48.h,
                                    child: ElevatedButton(
                                      onPressed: ctaBusy
                                          ? null
                                          : () => _addToCart(
                                                unit == 'Kg' ? 'Kilogram' : unit,
                                              ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            BookingDetailsDesign.brand,
                                        foregroundColor: Colors.white,
                                        elevation: 0,
                                        disabledBackgroundColor:
                                            BookingDetailsDesign.brand
                                                .withValues(alpha: 0.55),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12.r),
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          if (!ctaBusy) ...[
                                            Icon(
                                              Icons.shopping_cart_outlined,
                                              size: 18.sp,
                                            ),
                                            SizedBox(width: 8.w),
                                          ],
                                          if (ctaBusy)
                                            AnimatedEllipsisText(
                                              label: busyLabel,
                                              style: TextStyle(
                                                fontFamily: fontFamily,
                                                fontSize: 15.sp,
                                                fontWeight: FontWeight.w700,
                                                color: Colors.white,
                                              ),
                                            )
                                          else
                                            Text(
                                              idleLabel,
                                              style: TextStyle(
                                                fontFamily: fontFamily,
                                                fontSize: 15.sp,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  )
                                : PrimaryButtonWithCancel(
                                    text: idleLabel,
                                    loadingText: busyLabel,
                                    isLoading: isSubmitting,
                                    height: 48.h,
                                    borderRadius: 12,
                                    backgroundColor: BookingDetailsDesign.brand,
                                    onCancel: isSubmitting
                                        ? () => _clintCubit
                                            .cancelInFlightOrderAction()
                                        : null,
                                    onPressed: isSubmitting
                                        ? null
                                        : _submitOfferOrder,
                                  );

                            final showRetailPrice =
                                ProductPriceFormatter.canShowProductPrice(
                              _product,
                              preferRetail: preferRetail && !widget.isOffer,
                            );
                            if (showRetailPrice) {
                              return buyButton;
                            }

                            return Row(
                              children: [
                                Expanded(
                                  child: SizedBox(
                                    height: 48.h,
                                    child: OutlinedButton(
                                      onPressed: () {
                                        AskForPriceHelper
                                            .openSupportChatWithProduct(
                                          context: context,
                                          product: _product,
                                        );
                                      },
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor:
                                            BookingDetailsDesign.brand,
                                        side: BorderSide(
                                          color: BookingDetailsDesign.brand,
                                          width: 1.5,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12.r),
                                        ),
                                      ),
                                      child: Text(
                                        s.askForPrice,
                                        style: TextStyle(
                                          fontFamily: fontFamily,
                                          fontSize: 14.sp,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(width: 10.w),
                                Expanded(child: buyButton),
                              ],
                            );
                          },
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
