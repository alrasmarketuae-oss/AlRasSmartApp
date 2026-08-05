import 'package:alrasmarket/core/utils/thousands_separator_input_formatter.dart';
import 'package:alrasmarket/features/clint/presentation/widgets/cart/cart_design.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class CartQuantitySelector extends StatefulWidget {
  const CartQuantitySelector({
    super.key,
    required this.quantity,
    required this.onIncrement,
    this.onDecrement,
    this.onQuantityCommitted,
    this.isEnabled = true,
    this.canIncrement = true,
  });

  final double quantity;
  final VoidCallback onIncrement;
  final VoidCallback? onDecrement;
  final ValueChanged<double>? onQuantityCommitted;
  final bool isEnabled;
  final bool canIncrement;

  @override
  State<CartQuantitySelector> createState() => _CartQuantitySelectorState();
}

class _CartQuantitySelectorState extends State<CartQuantitySelector> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: _formatQuantity(widget.quantity));
    _focusNode = FocusNode();
  }

  @override
  void didUpdateWidget(CartQuantitySelector oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_focusNode.hasFocus && oldWidget.quantity != widget.quantity) {
      _controller.text = _formatQuantity(widget.quantity);
    }
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  String _formatQuantity(double value) {
    return ThousandsNumberInput.format(value, allowDecimal: true);
  }

  void _commitQuantity() {
    final parsed = ThousandsNumberInput.parseDouble(_controller.text);
    if (parsed == null || parsed <= 0) {
      _controller.text = _formatQuantity(widget.quantity);
      return;
    }
    if (parsed == widget.quantity) {
      _controller.text = _formatQuantity(parsed);
      return;
    }
    widget.onQuantityCommitted?.call(parsed);
  }

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
            onTap: widget.isEnabled ? widget.onDecrement : null,
          ),
          SizedBox(
            width: 56.w,
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              enabled: widget.isEnabled,
              textAlign: TextAlign.center,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                ThousandsSeparatorInputFormatter(allowDecimal: true),
              ],
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w700,
                color: CartDesign.text,
              ),
              decoration: const InputDecoration(
                isDense: true,
                contentPadding: EdgeInsets.symmetric(vertical: 4),
                border: InputBorder.none,
              ),
              onSubmitted: (_) => _commitQuantity(),
              onEditingComplete: _commitQuantity,
            ),
          ),
          _StepButton(
            icon: Icons.add_rounded,
            onTap: widget.isEnabled && widget.canIncrement
                ? widget.onIncrement
                : null,
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
