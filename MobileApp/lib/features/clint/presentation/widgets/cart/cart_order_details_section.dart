import 'package:alrasmarket/core/utils/product_price_formatter.dart';
import 'package:alrasmarket/core/widgets/product_price_text.dart';
import 'package:alrasmarket/features/clint/domain/entities/cart_item_entity.dart';
import 'package:alrasmarket/features/clint/data/models/domestic_emirate_model.dart';
import 'package:alrasmarket/features/clint/data/models/client_address_model.dart';
import 'package:alrasmarket/features/clint/domain/entities/cart_entity.dart';
import 'package:alrasmarket/features/clint/presentation/widgets/cart/cart_design.dart';
import 'package:alrasmarket/generated/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class CartDeliveryMethodSection extends StatelessWidget {
  const CartDeliveryMethodSection({
    super.key,
    required this.isSelfPickup,
    required this.onChanged,
  });

  final bool isSelfPickup;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CartSectionTitle(
          title: s.deliveryMethod,
          icon: Icons.local_shipping_outlined,
        ),
        SizedBox(height: 12.h),
        Row(
          children: [
            Expanded(
              child: _DeliveryOptionCard(
                icon: Icons.local_shipping_outlined,
                label: s.delivery,
                hint: s.deliveryToAddressHint,
                isSelected: !isSelfPickup,
                onTap: () => onChanged(false),
              ),
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: _DeliveryOptionCard(
                icon: Icons.storefront_outlined,
                label: s.selfPickup,
                hint: s.selfPickupHint,
                isSelected: isSelfPickup,
                onTap: () => onChanged(true),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _DeliveryOptionCard extends StatelessWidget {
  const _DeliveryOptionCard({
    required this.icon,
    required this.label,
    required this.hint,
    required this.isSelected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String hint;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: CartDesign.cardRadius,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: EdgeInsets.fromLTRB(12.w, 14.h, 12.w, 14.h),
          decoration: BoxDecoration(
            color: CartDesign.cardBg,
            borderRadius: CartDesign.cardRadius,
            border: Border.all(
              color: isSelected ? CartDesign.selectedBorder : CartDesign.border,
              width: isSelected ? 1.6 : 1,
            ),
            boxShadow: CartDesign.cardShadow,
          ),
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(icon, color: CartDesign.brand, size: 22.sp),
                  SizedBox(height: 10.h),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w800,
                      color: CartDesign.text,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    hint,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11.sp,
                      height: 1.35,
                      color: CartDesign.muted,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              if (isSelected)
                PositionedDirectional(
                  top: 0,
                  end: 0,
                  child: Container(
                    width: 20.w,
                    height: 20.w,
                    decoration: const BoxDecoration(
                      color: CartDesign.brand,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.check_rounded,
                      size: 13.sp,
                      color: Colors.white,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class CartEmirateShippingSection extends StatelessWidget {
  const CartEmirateShippingSection({
    super.key,
    required this.emirates,
    required this.selectedEmirateName,
    required this.isLoading,
    required this.onEmirateSelected,
  });

  final List<DomesticEmirateModel> emirates;
  final String? selectedEmirateName;
  final bool isLoading;
  final ValueChanged<String> onEmirateSelected;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CartSectionTitle(
          title: s.deliveryEmirate,
          icon: Icons.map_outlined,
        ),
        SizedBox(height: 12.h),
        Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
          decoration: BoxDecoration(
            color: CartDesign.cardBg,
            borderRadius: CartDesign.cardRadius,
            border: Border.all(color: CartDesign.border),
            boxShadow: CartDesign.cardShadow,
          ),
          child: isLoading
              ? Padding(
                  padding: EdgeInsets.symmetric(vertical: 12.h),
                  child: const Center(child: CircularProgressIndicator()),
                )
              : DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    value: _resolveSelectedValue(),
                    onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
                    hint: Text(s.selectDeliveryEmirate),
                    items: emirates
                        .map(
                          (emirate) => DropdownMenuItem<String>(
                            value: emirate.nameEn,
                            child: Text(emirate.displayName(isArabic)),
                          ),
                        )
                        .toList(),
                    onChanged: emirates.isEmpty
                        ? null
                        : (value) {
                            if (value != null) onEmirateSelected(value);
                          },
                  ),
                ),
        ),
      ],
    );
  }

  String? _resolveSelectedValue() {
    if (selectedEmirateName == null || emirates.isEmpty) return null;
    final normalized = selectedEmirateName!.trim().toLowerCase();
    for (final emirate in emirates) {
      if (emirate.nameEn.toLowerCase() == normalized ||
          emirate.nameAr.toLowerCase() == normalized) {
        return emirate.nameEn;
      }
    }
    return null;
  }
}

class CartDeliveryAddressSection extends StatelessWidget {
  const CartDeliveryAddressSection({
    super.key,
    required this.selectedAddressId,
    required this.savedAddresses,
    required this.isLoadingAddresses,
    required this.onSavedAddressSelected,
    required this.onAddAddress,
  });

  final String? selectedAddressId;
  final List<ClientAddressModel> savedAddresses;
  final bool isLoadingAddresses;
  final ValueChanged<ClientAddressModel> onSavedAddressSelected;
  final VoidCallback onAddAddress;

  ClientAddressModel? get _selected {
    if (savedAddresses.isEmpty) return null;
    if (selectedAddressId == null) return null;
    for (final address in savedAddresses) {
      if (address.addressId == selectedAddressId) return address;
    }
    return null;
  }

  Future<void> _pickAddress(BuildContext context) async {
    if (savedAddresses.isEmpty) return;
    final selected = await showModalBottomSheet<ClientAddressModel>(
      context: context,
      backgroundColor: CartDesign.cardBg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18.r)),
      ),
      builder: (context) {
        final s = S.of(context);
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 16.h),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40.w,
                    height: 4.h,
                    decoration: BoxDecoration(
                      color: CartDesign.border,
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                ),
                SizedBox(height: 14.h),
                Text(
                  s.selectDeliveryAddress,
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w800,
                    color: CartDesign.text,
                  ),
                ),
                SizedBox(height: 12.h),
                ...savedAddresses.map(
                  (address) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      Icons.location_on_outlined,
                      color: CartDesign.brand,
                      size: 22.sp,
                    ),
                    title: Text(
                      address.label,
                      style: TextStyle(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w600,
                        color: CartDesign.text,
                      ),
                    ),
                    trailing: address.addressId == selectedAddressId
                        ? Icon(
                            Icons.check_circle_rounded,
                            color: CartDesign.brand,
                            size: 20.sp,
                          )
                        : null,
                    onTap: () => Navigator.pop(context, address),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
    if (selected != null) onSavedAddressSelected(selected);
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final selected = _selected;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CartSectionTitle(
          title: s.deliveryAddress,
          icon: Icons.location_on_outlined,
        ),
        SizedBox(height: 12.h),
        if (isLoadingAddresses)
          Padding(
            padding: EdgeInsets.symmetric(vertical: 12.h),
            child: const Center(child: CircularProgressIndicator()),
          )
        else if (savedAddresses.isEmpty)
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: CartDesign.cardBg,
              borderRadius: CartDesign.cardRadius,
              border: Border.all(color: CartDesign.border),
              boxShadow: CartDesign.cardShadow,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  s.noSavedAddresses,
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: CartDesign.muted,
                  ),
                ),
                SizedBox(height: 4.h),
                TextButton.icon(
                  onPressed: onAddAddress,
                  icon: Icon(Icons.add_rounded, size: 18.sp),
                  label: Text(s.addNewAddress),
                  style: TextButton.styleFrom(
                    foregroundColor: CartDesign.brand,
                    padding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
          )
        else ...[
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _pickAddress(context),
              borderRadius: CartDesign.cardRadius,
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.all(14.w),
                decoration: BoxDecoration(
                  color: CartDesign.cardBg,
                  borderRadius: CartDesign.cardRadius,
                  border: Border.all(color: CartDesign.border),
                  boxShadow: CartDesign.cardShadow,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 36.w,
                      height: 36.w,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: CartDesign.brand.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                      child: Icon(
                        Icons.location_on_outlined,
                        color: CartDesign.brand,
                        size: 18.sp,
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Text(
                        selected?.label ?? s.selectDeliveryAddress,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13.sp,
                          height: 1.4,
                          fontWeight: FontWeight.w600,
                          color: selected == null
                              ? CartDesign.muted
                              : CartDesign.text,
                        ),
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: CartDesign.muted,
                      size: 22.sp,
                    ),
                  ],
                ),
              ),
            ),
          ),
          SizedBox(height: 8.h),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: TextButton.icon(
              onPressed: onAddAddress,
              icon: Icon(Icons.add_rounded, size: 18.sp),
              label: Text(s.addNewAddress),
              style: TextButton.styleFrom(
                foregroundColor: CartDesign.brand,
                padding: EdgeInsets.symmetric(horizontal: 4.w),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class CartOrderDetailsSection extends StatelessWidget {
  const CartOrderDetailsSection({
    super.key,
    required this.cart,
    required this.deliveryLabel,
    required this.vatLabel,
    required this.totalLabel,
    this.selfPickupLabel,
    this.freeLabel,
    this.isSelfPickup = false,
    this.shippingDisclaimer,
    this.isLoadingShipping = false,
  });

  final CartEntity cart;
  final String deliveryLabel;
  final String vatLabel;
  final String totalLabel;
  final String? selfPickupLabel;
  final String? freeLabel;
  final bool isSelfPickup;
  final String? shippingDisclaimer;
  final bool isLoadingShipping;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CartSectionTitle(
          title: s.orderSummary,
          icon: Icons.assignment_outlined,
        ),
        SizedBox(height: 12.h),
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: CartDesign.cardBg,
            borderRadius: CartDesign.cardRadius,
            border: Border.all(color: CartDesign.border),
            boxShadow: CartDesign.cardShadow,
          ),
          child: Column(
            children: [
              ...cart.items.map(
                (item) => Padding(
                  padding: EdgeInsets.only(bottom: 10.h),
                  child: _SummaryRow(
                    label: item.productName,
                    valueWidget: ProductPriceFormatter.canShowPrices
                        ? ProductPriceText(
                            amount: item.totalPriceAmount,
                            currency: 'AED',
                            amountStyle: TextStyle(
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w600,
                              color: CartDesign.text,
                            ),
                          )
                        : null,
                    showValue: ProductPriceFormatter.canShowPrices,
                  ),
                ),
              ),
              if (ProductPriceFormatter.canShowPrices)
                _SummaryRow(
                  label: vatLabel,
                  valueWidget: ProductPriceText(
                    amount: CartItemEntity.formatAmountOnly(cart.vatAed),
                    currency: 'AED',
                    amountStyle: TextStyle(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w600,
                      color: CartDesign.text,
                    ),
                  ),
                  showValue: true,
                ),
              if (ProductPriceFormatter.canShowPrices) ...[
                SizedBox(height: 10.h),
                _SummaryRow(
                  label: isSelfPickup
                      ? (selfPickupLabel ?? deliveryLabel)
                      : deliveryLabel,
                  value: isSelfPickup
                      ? (freeLabel ?? '')
                      : (isLoadingShipping ? '...' : ''),
                  valueWidget: !isSelfPickup && !isLoadingShipping
                      ? ProductPriceText(
                          amount: CartItemEntity.formatAmountOnly(
                            cart.deliveryFeeAed,
                          ),
                          currency: 'AED',
                          amountStyle: TextStyle(
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w600,
                            color: CartDesign.text,
                          ),
                        )
                      : null,
                  showValue: ProductPriceFormatter.canShowPrices,
                ),
              ],
              if (ProductPriceFormatter.canShowPrices) ...[
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 12.h),
                  child: const Divider(color: CartDesign.border, height: 1),
                ),
                _SummaryRow(
                  label: totalLabel,
                  valueWidget: ProductPriceText(
                    amount: CartItemEntity.formatAmountOnly(cart.totalAed),
                    currency: 'AED',
                    amountStyle: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w800,
                      color: CartDesign.priceGreen,
                    ),
                    matchCurrencyToAmount: true,
                  ),
                  isBold: true,
                ),
              ],
              if (ProductPriceFormatter.canShowPrices &&
                  !isSelfPickup &&
                  shippingDisclaimer != null) ...[
                SizedBox(height: 12.h),
                Container(
                  width: double.infinity,
                  padding:
                      EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
                  decoration: BoxDecoration(
                    color: CartDesign.infoBg,
                    borderRadius: BorderRadius.circular(10.r),
                    border: Border.all(color: CartDesign.infoBorder),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        size: 16.sp,
                        color: CartDesign.infoText,
                      ),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: Text(
                          shippingDisclaimer!,
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: CartDesign.infoText,
                            height: 1.4,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    this.value = '',
    this.valueWidget,
    this.isBold = false,
    this.showValue = true,
  });

  final String label;
  final String value;
  final Widget? valueWidget;
  final bool isBold;
  final bool showValue;

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      fontSize: isBold ? 15.sp : 13.sp,
      fontWeight: isBold ? FontWeight.w800 : FontWeight.w500,
      color: CartDesign.text,
    );

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: style,
          ),
        ),
        SizedBox(width: 12.w),
        if (showValue && valueWidget != null)
          valueWidget!
        else if (showValue && value.isNotEmpty)
          Text(value, style: style.copyWith(color: CartDesign.muted)),
      ],
    );
  }
}
