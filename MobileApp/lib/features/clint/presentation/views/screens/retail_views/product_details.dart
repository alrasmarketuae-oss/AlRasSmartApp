import 'dart:async';

import 'package:alrasmarket/core/ui/widgets/feedback/app_toast.dart';
import 'package:alrasmarket/core/utils/product_quantity_validator.dart';
import 'package:alrasmarket/core/utils/product_stock.dart';
import 'package:alrasmarket/core/utils/user_facing_error_localizer.dart';
import 'package:alrasmarket/core/router/app_router.dart';
import 'package:alrasmarket/core/services/product_view_service.dart';
import 'package:alrasmarket/core/services_locator/services_locator.dart';
import 'package:alrasmarket/core/theme/app_fonts.dart';
import 'package:alrasmarket/features/clint/domain/entities/cart_entity.dart';
import 'package:alrasmarket/features/clint/presentation/controller/cubit/clint_cubit.dart';
import 'package:alrasmarket/features/clint/presentation/controller/cubit/clint_states.dart';
import 'package:alrasmarket/features/clint/presentation/helpers/product_navigation_helper.dart';
import 'package:alrasmarket/features/clint/presentation/helpers/product_ownership_helper.dart';
import 'package:alrasmarket/features/clint/presentation/widgets/booking_widets/booking_details_app_bar.dart';
import 'package:alrasmarket/features/clint/presentation/widgets/booking_widets/booking_details_design.dart';
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
  double _total = 0;
  bool _isAddingToCart = false;

  @override
  void initState() {
    super.initState();
    _clintCubit = sl<ClintCubit>();

    if (widget.product.isRequestProduct) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        context.pushReplacement(
          AppRoutes.kRequestDetailsView,
          extra: {'product': widget.product},
        );
      });
      _quantityController = TextEditingController(text: '1');
      _ownsQuantityController = true;
      return;
    }

    // Fire-and-forget: count a buyer opening this product details screen.
    unawaited(
      ProductViewService.trackProductView(
        widget.product.productId,
        product: widget.product,
      ),
    );

    widget.isOffer = widget.isOffer && widget.product.isOfferProduct;

    if (widget.isOffer) {
      _clintCubit.initOfferOrder(widget.product);
      _quantityController = _clintCubit.offerOrderQuantityController;
      _ownsQuantityController = false;
    } else {
      final defaultQty = widget.product.minimumOrderQuantity.trim().isNotEmpty
          ? widget.product.minimumOrderQuantity.trim()
          : '1';
      _quantityController = TextEditingController(text: defaultQty);
      _ownsQuantityController = true;
    }
    _recalculateTotal();
  }

  @override
  void dispose() {
    if (_ownsQuantityController) {
      _quantityController.dispose();
    }
    super.dispose();
  }

  Future<void> _addToCart(String unit) async {
    if (!(_quantityFormKey.currentState?.validate() ?? false)) return;

    final quantity = double.tryParse(_quantityController.text.trim()) ?? 0;
    if (quantity <= 0) return;

    if (await _redirectIfCartAtStockLimit(quantity)) {
      return;
    }

    setState(() => _isAddingToCart = true);
    await _clintCubit.addProductToCart(
      productId: widget.product.productId,
      quantity: quantity,
      unitName: unit,
    );
    if (!mounted) return;

    setState(() => _isAddingToCart = false);
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
  }

  double _availableProductQuantity() {
    return double.tryParse(widget.product.quantity.replaceAll(',', '')) ?? 0;
  }

  double _cartQuantityForProduct(CartEntity cart) {
    return cart.items
        .where((item) => item.productId == widget.product.productId)
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
    final quantity = double.tryParse(_quantityController.text.trim()) ?? 0;
    setState(() {
      _total = RetailDetailsMapper.unitPrice(widget.product) * quantity;
    });
    if (widget.isOffer) {
      _clintCubit.notifyOfferOrderQuantityChanged();
    }
  }

  void _submitOfferOrder() {
    if (!(_quantityFormKey.currentState?.validate() ?? false)) return;
    _clintCubit.submitOfferOrder();
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final fontFamily = AppFonts.familyFor(Localizations.localeOf(context));
    final unit = widget.product
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
            if (!widget.isOffer) return false;
            if (previous is OfferOrderFormState &&
                current is OfferOrderFormState) {
              return previous.isSubmitting != current.isSubmitting;
            }
            return current is OfferOrderFormState;
          },
          builder: (context, state) {
            final isSubmitting =
                widget.isOffer &&
                state is OfferOrderFormState &&
                state.isSubmitting;

            final preferRetail = ProductNavigationHelper
                .resolvePreferRetailChannel(widget.preferRetailChannel);
            final isRetailCart = !widget.isOffer &&
                (preferRetail
                    ? widget.product.isRetailFeedProduct
                    : widget.product.isPureRetailProduct);
            final soldOut = ProductStock.isSoldOut(widget.product);
            final isOwnAd =
                ProductOwnershipHelper.isOwnedByCurrentUser(widget.product);
            final ctaBusy = isRetailCart ? _isAddingToCart : isSubmitting;
            final ctaLabel = widget.isOffer
                ? s.purchaseOrder
                : (isRetailCart ? s.addToCart : s.purchaseOrder);

            return Scaffold(
              backgroundColor: BookingDetailsDesign.pageBg,
              appBar: BookingDetailsAppBar(product: widget.product),
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
                              product: widget.product,
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
                                product: widget.product,
                              ),
                            )
                          else
                            RetailAdDetailsBody(
                              product: widget.product,
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
                                product: widget.product,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  if (!soldOut)
                    SafeArea(
                      top: false,
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 12.h),
                        child: SizedBox(
                          width: double.infinity,
                          height: 48.h,
                          child: ElevatedButton.icon(
                            onPressed: ctaBusy
                                ? null
                                : () {
                                    if (isOwnAd) {
                                      AppToast.showError(
                                        context,
                                        s.cannotOrderOwnProduct,
                                      );
                                      return;
                                    }
                                    if (widget.isOffer) {
                                      _submitOfferOrder();
                                      return;
                                    }
                                    if (isRetailCart) {
                                      _addToCart(
                                        unit == 'Kg' ? 'Kilogram' : unit,
                                      );
                                      return;
                                    }
                                    _submitOfferOrder();
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: BookingDetailsDesign.brand,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              disabledBackgroundColor: BookingDetailsDesign
                                  .brand
                                  .withValues(alpha: 0.55),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12.r),
                              ),
                            ),
                            icon: ctaBusy
                                ? SizedBox(
                                    width: 18.w,
                                    height: 18.w,
                                    child: const CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Icon(
                                    Icons.shopping_cart_outlined,
                                    size: 18.sp,
                                  ),
                            label: Text(
                              ctaLabel,
                              style: TextStyle(
                                fontFamily: fontFamily,
                                fontSize: 15.sp,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
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
