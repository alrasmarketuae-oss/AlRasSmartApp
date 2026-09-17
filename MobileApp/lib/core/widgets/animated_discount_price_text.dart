import 'dart:async';
import 'dart:math' as math;

import 'package:alrasmarket/core/utils/thousands_separator_input_formatter.dart';
import 'package:alrasmarket/core/widgets/currency_icon.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Counts the displayed unit price down from [fromAmount] to [toAmount]
/// quickly (unit-by-unit) when an offer discount is active.
class AnimatedDiscountPriceText extends StatefulWidget {
  const AnimatedDiscountPriceText({
    super.key,
    required this.fromAmount,
    required this.toAmount,
    required this.currency,
    this.suffix,
    this.amountStyle,
    this.matchCurrencyToAmount = true,
  });

  final double fromAmount;
  final double toAmount;
  final String currency;
  final String? suffix;
  final TextStyle? amountStyle;
  final bool matchCurrencyToAmount;

  @override
  State<AnimatedDiscountPriceText> createState() =>
      _AnimatedDiscountPriceTextState();
}

class _AnimatedDiscountPriceTextState extends State<AnimatedDiscountPriceText> {
  Timer? _timer;
  late double _current;

  @override
  void initState() {
    super.initState();
    _current = widget.fromAmount;
    _startCountdown();
  }

  @override
  void didUpdateWidget(covariant AnimatedDiscountPriceText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.fromAmount != widget.fromAmount ||
        oldWidget.toAmount != widget.toAmount) {
      _timer?.cancel();
      _current = widget.fromAmount;
      _startCountdown();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startCountdown() {
    final from = widget.fromAmount;
    final to = widget.toAmount;
    if (from <= to + 0.0001) {
      _current = to;
      return;
    }

    final drop = from - to;
    // Aim to finish in ~0.7–1.2s with whole-unit steps when possible.
    const tickMs = 16;
    final targetTicks = (900 / tickMs).round();
    final step = math.max(1.0, (drop / targetTicks).ceilToDouble());

    _timer = Timer.periodic(const Duration(milliseconds: tickMs), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      final next = _current - step;
      if (next <= to) {
        setState(() => _current = to);
        timer.cancel();
        return;
      }
      setState(() => _current = next);
    });
  }

  String _format(double value) {
    final useWhole = (widget.fromAmount - widget.toAmount) >= 1;
    final shown = useWhole && value != widget.toAmount
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

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(_format(_current), style: style),
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
  }
}
