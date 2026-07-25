import 'package:alrasmarket/core/utils/assets.dart';
import 'package:alrasmarket/features/clint/domain/entities/cart_payment_method.dart';
import 'package:alrasmarket/features/clint/presentation/widgets/cart/cart_design.dart';
import 'package:alrasmarket/generated/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';

class CartPaymentMethodSection extends StatelessWidget {
  const CartPaymentMethodSection({
    super.key,
    required this.selectedMethod,
    required this.onChanged,
    this.enabled = true,
  });

  final CartPaymentMethod selectedMethod;
  final ValueChanged<CartPaymentMethod> onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CartSectionTitle(
          title: s.paymentMethods,
          icon: Icons.credit_card_rounded,
        ),
        SizedBox(height: 6.h),
        Text(
          s.retailVisaPaymentHint,
          style: TextStyle(
            fontSize: 12.sp,
            height: 1.4,
            color: CartDesign.muted,
          ),
        ),
        SizedBox(height: 12.h),
        _PaymentOptionCard(
          icon: Icons.credit_card_rounded,
          label: s.payWithVisa,
          isSelected: selectedMethod == CartPaymentMethod.online,
          onTap: enabled ? () => onChanged(CartPaymentMethod.online) : null,
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SvgPicture.asset(
                AppAssets.visaLogo,
                width: 42.w,
                height: 26.h,
                fit: BoxFit.contain,
              ),
              SizedBox(width: 6.w),
              SvgPicture.asset(
                AppAssets.mastercardLogo,
                width: 42.w,
                height: 26.h,
                fit: BoxFit.contain,
              ),
            ],
          ),
        ),
        SizedBox(height: 10.h),
        _PaymentOptionCard(
          icon: Icons.payments_outlined,
          label: s.cashOnDelivery,
          isSelected: selectedMethod == CartPaymentMethod.cash,
          onTap: enabled ? () => onChanged(CartPaymentMethod.cash) : null,
        ),
      ],
    );
  }
}

class _PaymentOptionCard extends StatelessWidget {
  const _PaymentOptionCard({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.trailing,
  });

  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: CartDesign.cardRadius,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
          decoration: BoxDecoration(
            color: CartDesign.cardBg,
            borderRadius: CartDesign.cardRadius,
            border: Border.all(
              color: isSelected ? CartDesign.selectedBorder : CartDesign.border,
              width: isSelected ? 1.6 : 1,
            ),
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
                child: Icon(icon, color: CartDesign.brand, size: 20.sp),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w700,
                    color: CartDesign.text,
                  ),
                ),
              ),
              if (trailing != null) ...[
                trailing!,
                SizedBox(width: 10.w),
              ],
              _SelectionDot(isSelected: isSelected),
            ],
          ),
        ),
      ),
    );
  }
}

class _SelectionDot extends StatelessWidget {
  const _SelectionDot({required this.isSelected});

  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: 22.w,
      height: 22.w,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isSelected ? CartDesign.brand : Colors.transparent,
        border: Border.all(
          color: isSelected ? CartDesign.brand : CartDesign.border,
          width: 1.6,
        ),
      ),
      child: isSelected
          ? Icon(Icons.check_rounded, size: 14.sp, color: Colors.white)
          : null,
    );
  }
}
