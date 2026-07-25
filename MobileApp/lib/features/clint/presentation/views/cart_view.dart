import 'package:alrasmarket/core/router/app_router.dart';
import 'package:alrasmarket/core/theme/colors.dart';
import 'package:alrasmarket/core/widgets/primary_button.dart';
import 'package:alrasmarket/core/widgets/product_price_text.dart';
import 'package:alrasmarket/features/clint/domain/entities/cart_item_entity.dart';
import 'package:alrasmarket/features/clint/domain/entities/cart_payment_method.dart';
import 'package:alrasmarket/features/clint/presentation/controller/cubit/clint_cubit.dart';
import 'package:alrasmarket/features/clint/presentation/controller/cubit/clint_states.dart';
import 'package:alrasmarket/features/clint/presentation/widgets/cart/cart_design.dart';
import 'package:alrasmarket/features/clint/presentation/widgets/cart/cart_item_card.dart';
import 'package:alrasmarket/features/clint/presentation/widgets/cart/cart_order_details_section.dart';
import 'package:alrasmarket/features/clint/presentation/widgets/cart/cart_payment_method_section.dart';
import 'package:alrasmarket/features/clint/presentation/widgets/add_address_dialog.dart';
import 'package:alrasmarket/features/clint/presentation/widgets/search_header.dart';
import 'package:alrasmarket/core/utils/user_facing_error_localizer.dart';
import 'package:alrasmarket/generated/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

class CartView extends StatefulWidget {
  const CartView({super.key});

  @override
  State<CartView> createState() => _CartViewState();
}

class _CartViewState extends State<CartView> {
  bool _isEditing = true;

  @override
  void initState() {
    super.initState();
    context.read<ClintCubit>().loadCart();
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);

    return SafeArea(
      child: Scaffold(
        backgroundColor: CartDesign.pageBg,
        body: BlocConsumer<ClintCubit, ClintStates>(
          listenWhen: (previous, current) {
            if (current is NavigateToTrackOrderState) return true;
            if (current is CartLoadedState) {
              return current.errorMessage != null ||
                  current.successMessage != null ||
                  current.infoMessage != null;
            }
            return current is CartErrorState;
          },
          listener: (context, state) {
            if (state is NavigateToTrackOrderState) {
              context.pushReplacement(
                AppRoutes.kTrackOrderView,
                extra: {'order': state.order},
              );
              return;
            }
            if (state is CartLoadedState) {
              final cubit = context.read<ClintCubit>();
              if (state.errorMessage != null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      UserFacingErrorLocalizer.localizeCartError(
                        state.errorMessage,
                        cart: state.cart,
                      ),
                    ),
                  ),
                );
              } else if (state.successMessage != null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.successMessage!),
                    backgroundColor: const Color(0xFF22C55E),
                  ),
                );
              } else if (state.infoMessage != null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.infoMessage!),
                    backgroundColor: const Color(0xFF3B82F6),
                    duration: const Duration(seconds: 5),
                  ),
                );
              }
              cubit.clearCartFeedback();
            } else if (state is CartErrorState) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    UserFacingErrorLocalizer.localizeCartError(state.message),
                  ),
                ),
              );
            }
          },
          builder: (context, state) {
            return Column(
              children: [
                const SearchHeader(
                  isSearch: false,
                  isBackButton: true,
                ),
                Expanded(child: _buildBody(context, state, s)),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, ClintStates state, S s) {
    if (state is CartInitialState ||
        (state is CartLoadedState && state.isLoading)) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state is CartErrorState) {
      return _MessageState(
        message: UserFacingErrorLocalizer.localizeCartError(state.message),
        actionLabel: s.retry,
        onAction: () => context.read<ClintCubit>().loadCart(),
      );
    }

    if (state is CartLoadedState) {
      if (state.cart.isEmpty && !state.isAwaitingOnlinePayment) {
        return _MessageState(
          message: s.yourCartIsEmpty,
          actionLabel: s.refresh,
          onAction: () => context.read<ClintCubit>().loadCart(),
        );
      }

      final cubit = context.read<ClintCubit>();
      final isOnline = state.selectedPaymentMethod == CartPaymentMethod.online;
      final itemCount = state.cart.items.length;

      return Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(20.w, 4.h, 20.w, 16.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _CartTitleRow(
                    title: s.yourCart,
                    itemsLabel: s.cartItemsCount(itemCount),
                    editLabel: s.editCart,
                    isEditing: _isEditing,
                    onEditTap: () => setState(() => _isEditing = !_isEditing),
                  ),
                  SizedBox(height: 14.h),
                  if (state.isAwaitingOnlinePayment) ...[
                    Container(
                      padding: EdgeInsets.all(14.w),
                      decoration: BoxDecoration(
                        color: CartDesign.infoBg,
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(color: CartDesign.infoBorder),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              if (state.isCheckingPayment)
                                Padding(
                                  padding: EdgeInsets.only(right: 10.w),
                                  child: SizedBox(
                                    width: 18.w,
                                    height: 18.w,
                                    child: const CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  ),
                                ),
                              Expanded(
                                child: Text(
                                  state.isCheckingPayment
                                      ? 'Waiting for Stripe to confirm payment...'
                                      : 'Payment session started.',
                                  style: TextStyle(
                                    fontSize: 14.sp,
                                    fontWeight: FontWeight.w600,
                                    color: CartDesign.infoText,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 8.h),
                          Text(
                            'No split orders are created yet. They will appear only after the Stripe webhook confirms payment on the server.',
                            style: TextStyle(
                              fontSize: 13.sp,
                              color: const Color(0xFF1E40AF),
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 16.h),
                  ],
                  ...state.cart.items.map(
                    (item) => Padding(
                      padding: EdgeInsets.only(bottom: 12.h),
                      child: CartItemCard(
                        item: item,
                        showDelete: _isEditing,
                        isUpdating: state.isUpdatingItem &&
                            state.updatingCartItemId == item.id,
                        onIncrement: () => cubit.incrementItem(
                          cartItemId: item.id,
                          productId: item.productId,
                          unitName: item.unitName,
                        ),
                        onDecrement: () => cubit.decrementItem(
                          cartItemId: item.id,
                        ),
                        onDelete: () => cubit.removeCartItem(
                          cartItemId: item.id,
                        ),
                      ),
                    ),
                  ),
                  if (state.cart.items.isNotEmpty) ...[
                    SizedBox(height: 8.h),
                    CartDeliveryMethodSection(
                      isSelfPickup: state.isSelfPickup,
                      onChanged: cubit.setCartSelfPickup,
                    ),
                    if (!state.isSelfPickup) ...[
                      SizedBox(height: 16.h),
                      CartDeliveryAddressSection(
                        selectedAddressId: state.selectedAddressId,
                        savedAddresses: cubit.cartSavedAddresses,
                        isLoadingAddresses: cubit.isLoadingCartAddresses,
                        onSavedAddressSelected: cubit.selectCartSavedAddress,
                        onAddAddress: () async {
                          final added = await AddAddressDialog.show(
                            context,
                            retailMode: true,
                          );
                          if (added == true && context.mounted) {
                            await cubit.reloadCartSavedAddresses();
                            if (cubit.cartSavedAddresses.isNotEmpty) {
                              await cubit.selectCartSavedAddress(
                                cubit.cartSavedAddresses.first,
                              );
                            }
                          }
                        },
                      ),
                    ],
                    SizedBox(height: 16.h),
                    CartOrderDetailsSection(
                      cart: state.cart,
                      deliveryLabel: s.deliveryFee,
                      vatLabel: s.vatFivePercent,
                      totalLabel: s.total,
                      selfPickupLabel: s.selfPickup,
                      freeLabel: s.free,
                      isSelfPickup: state.isSelfPickup,
                      isLoadingShipping: state.isLoadingShipping,
                    ),
                    SizedBox(height: 20.h),
                  ],
                  CartPaymentMethodSection(
                    selectedMethod: state.selectedPaymentMethod,
                    onChanged: cubit.selectPaymentMethod,
                    enabled: !state.isAwaitingOnlinePayment,
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(20.w, 0, 20.w, 20.h),
            child: state.isAwaitingOnlinePayment
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      PrimaryButton(
                        text: 'Open Stripe',
                        onPressed: cubit.openPaymentCheckout,
                        backgroundColor: LightColor.defaultColor,
                        borderRadius: 14,
                      ),
                      SizedBox(height: 12.h),
                      PrimaryButton(
                        text: 'I completed payment',
                        isLoading: state.isCheckingPayment,
                        onPressed: state.isCheckingPayment
                            ? null
                            : () => cubit.checkPaymentStatus(),
                        backgroundColor: const Color(0xFF22C55E),
                        borderRadius: 14,
                      ),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _CheckoutBar(
                        label: isOnline ? s.payWithVisaButton : s.confirmOrder,
                        totalAmount: CartItemEntity.formatAmountOnly(
                          state.cart.totalAed,
                        ),
                        isLoading: state.isConfirming,
                        onPressed:
                            state.isConfirming ? null : cubit.confirmOrder,
                      ),
                      SizedBox(height: 10.h),
                      OutlinedButton(
                        onPressed: state.isConfirming
                            ? null
                            : () => context.go(AppRoutes.kRetailServiceView),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: CartDesign.brand,
                          side: BorderSide(
                            color: CartDesign.brand.withValues(alpha: 0.55),
                          ),
                          minimumSize: Size(double.infinity, 48.h),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14.r),
                          ),
                        ),
                        child: Text(
                          s.continueShopping,
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      );
    }

    return const SizedBox.shrink();
  }
}

class _CartTitleRow extends StatelessWidget {
  const _CartTitleRow({
    required this.title,
    required this.itemsLabel,
    required this.editLabel,
    required this.isEditing,
    required this.onEditTap,
  });

  final String title;
  final String itemsLabel;
  final String editLabel;
  final bool isEditing;
  final VoidCallback onEditTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Flexible(
          child: Text(
            title,
            style: TextStyle(
              fontSize: 22.sp,
              fontWeight: FontWeight.w800,
              color: CartDesign.text,
            ),
          ),
        ),
        SizedBox(width: 8.w),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
          decoration: BoxDecoration(
            color: CartDesign.brand.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(20.r),
          ),
          child: Text(
            itemsLabel,
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.w700,
              color: CartDesign.brand,
            ),
          ),
        ),
        const Spacer(),
        TextButton.icon(
          onPressed: onEditTap,
          icon: Icon(
            Icons.edit_outlined,
            size: 16.sp,
            color: isEditing ? CartDesign.brand : CartDesign.muted,
          ),
          label: Text(
            editLabel,
            style: TextStyle(
              fontSize: 13.sp,
              fontWeight: FontWeight.w700,
              color: isEditing ? CartDesign.brand : CartDesign.muted,
            ),
          ),
          style: TextButton.styleFrom(
            padding: EdgeInsets.symmetric(horizontal: 8.w),
            visualDensity: VisualDensity.compact,
          ),
        ),
      ],
    );
  }
}

class _CheckoutBar extends StatelessWidget {
  const _CheckoutBar({
    required this.label,
    required this.totalAmount,
    required this.isLoading,
    required this.onPressed,
  });

  final String label;
  final String totalAmount;
  final bool isLoading;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isLoading ? null : onPressed,
        borderRadius: BorderRadius.circular(14.r),
        child: Ink(
          height: 56.h,
          decoration: BoxDecoration(
            color: onPressed == null && !isLoading
                ? CartDesign.brand.withValues(alpha: 0.55)
                : CartDesign.brand,
            borderRadius: BorderRadius.circular(14.r),
            boxShadow: [
              BoxShadow(
                color: CartDesign.brand.withValues(alpha: 0.28),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: Row(
              children: [
                if (isLoading)
                  SizedBox(
                    width: 20.w,
                    height: 20.w,
                    child: const CircularProgressIndicator(
                      strokeWidth: 2.2,
                      color: Colors.white,
                    ),
                  )
                else
                  Icon(Icons.lock_rounded, color: Colors.white, size: 18.sp),
                SizedBox(width: 10.w),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                ProductPriceText(
                  amount: totalAmount,
                  currency: 'AED',
                  amountStyle: TextStyle(
                    color: Colors.white,
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w800,
                  ),
                  matchCurrencyToAmount: true,
                ),
                SizedBox(width: 4.w),
                Icon(
                  Icons.chevron_right_rounded,
                  color: Colors.white,
                  size: 22.sp,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MessageState extends StatelessWidget {
  const _MessageState({
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  final String message;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 24.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15.sp,
                color: CartDesign.text,
              ),
            ),
            SizedBox(height: 16.h),
            PrimaryButton(
              text: actionLabel,
              onPressed: onAction,
              width: 180.w,
            ),
          ],
        ),
      ),
    );
  }
}
