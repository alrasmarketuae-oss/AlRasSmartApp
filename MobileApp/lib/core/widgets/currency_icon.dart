import 'package:alrasmarket/core/utils/assets.dart';
import 'package:alrasmarket/features/company/presentation/models/create_ad_currency.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Green currency glyph — dirham SVG for AED, dollar sign for USD.
class CurrencyIcon extends StatelessWidget {
  const CurrencyIcon({
    super.key,
    required this.currency,
    this.size = 16,
    this.matchTextSize = false,
  });

  final String currency;
  final double size;

  /// When true, icon height matches [size] (same as adjacent price [TextStyle.fontSize]).
  final bool matchTextSize;

  static const Color green = Color(0xFF619D50);

  @override
  Widget build(BuildContext context) {
    final normalized = CreateAdCurrency.normalize(currency);
    if (normalized == CreateAdCurrency.aed) {
      final dimension = matchTextSize ? size : size.w;
      final height = matchTextSize ? size : (size * 0.9).h;
      return SvgPicture.asset(
        AppAssets.dirhamSvg,
        width: dimension,
        height: height,
        colorFilter: const ColorFilter.mode(green, BlendMode.srcIn),
      );
    }

    final dollarSize = matchTextSize ? size : size.sp;
    return Text(
      '\$',
      style: TextStyle(
        color: green,
        fontSize: dollarSize,
        fontWeight: FontWeight.w700,
        height: 1,
      ),
    );
  }
}
