import 'package:alrasmarket/features/clint/presentation/widgets/cart/cart_design.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class CartQuantitySelector extends StatelessWidget {
  const CartQuantitySelector({
    super.key,
    required this.quantity,
    required this.onIncrement,
    this.onDecrement,
    this.isEnabled = true,
    this.canIncrement = true,
  });

  final int quantity;
  final VoidCallback onIncrement;
  final VoidCallback? onDecrement;
  final bool isEnabled;
  final bool canIncrement;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: CartDesign.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _StepButton(
            icon: Icons.remove_rounded,
            onTap: isEnabled ? onDecrement : null,
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 10.w),
            child: Text(
              quantity.toString(),
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w700,
                color: CartDesign.text,
              ),
            ),
          ),
          _StepButton(
            icon: Icons.add_rounded,
            onTap: isEnabled && canIncrement ? onIncrement : null,
            emphasize: true,
          ),
        ],
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  const _StepButton({
    required this.icon,
    this.onTap,
    this.emphasize = false,
  });

  final IconData icon;
  final VoidCallback? onTap;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16.r),
        child: SizedBox(
          width: 28.w,
          height: 28.w,
          child: Icon(
            icon,
            size: 16.sp,
            color: !enabled
                ? CartDesign.muted.withValues(alpha: 0.45)
                : emphasize
                    ? CartDesign.brand
                    : CartDesign.text,
          ),
        ),
      ),
    );
  }
}
