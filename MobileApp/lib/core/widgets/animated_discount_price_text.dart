import 'package:alrasmarket/core/utils/thousands_separator_input_formatter.dart';
import 'package:alrasmarket/core/widgets/currency_icon.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Counts the displayed unit price down from [fromAmount] (original)
/// to [toAmount] (sale) when an offer discount is active.
class AnimatedDiscountPriceText extends StatefulWidget {
  const AnimatedDiscountPriceText({
    super.key,
    required this.fromAmount,
    required this.toAmount,
    required this.currency,
    this.suffix,
    this.amountStyle,
    this.matchCurrencyToAmount = true,
    this.duration = const Duration(milliseconds: 1400),
  });

  final double fromAmount;
  final double toAmount;
  final String currency;
  final String? suffix;
  final TextStyle? amountStyle;
  final bool matchCurrencyToAmount;
  final Duration duration;

  @override
  State<AnimatedDiscountPriceText> createState() =>
      _AnimatedDiscountPriceTextState();
}

class _AnimatedDiscountPriceTextState extends State<AnimatedDiscountPriceText>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _animation = _buildAnimation();
    if (widget.fromAmount > widget.toAmount + 0.0001) {
      _controller.forward();
    }
  }

  Animation<double> _buildAnimation() {
    return Tween<double>(
      begin: widget.fromAmount,
      end: widget.toAmount,
    ).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
  }

  @override
  void didUpdateWidget(covariant AnimatedDiscountPriceText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.fromAmount != widget.fromAmount ||
        oldWidget.toAmount != widget.toAmount ||
        oldWidget.duration != widget.duration) {
      _controller.duration = widget.duration;
      _animation = _buildAnimation();
      _controller
        ..reset()
        ..forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _format(double value) {
    final drop = widget.fromAmount - widget.toAmount;
    final shown = drop >= 1 && (value - widget.toAmount).abs() > 0.0001
        ? value.roundToDouble()
        : value;
    return ThousandsNumberInput.format(shown, allowDecimal: true);
  }

  @override
  Widget build(BuildContext context) {
    final style = widget.amountStyle ??
        TextStyle(
          color: CurrencyIcon.green,
          fontSize: 13.sp,
          fontWeight: FontWeight.bold,
          height: 1.2,
        );
    final iconSize =
        widget.matchCurrencyToAmount ? (style.fontSize ?? 14) : 14.0;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, _) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(_format(_animation.value), style: style),
            SizedBox(width: 4.w),
            CurrencyIcon(
              currency: widget.currency,
              size: iconSize,
              matchTextSize: widget.matchCurrencyToAmount,
            ),
            if (widget.suffix != null && widget.suffix!.isNotEmpty)
              Text(widget.suffix!, style: style),
          ],
        );
      },
    );
  }
}
