import 'package:alrasmarket/core/theme/colors.dart';
import 'package:alrasmarket/core/utils/assets.dart';
import 'package:alrasmarket/features/company/presentation/models/create_ad_currency.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Currency glyph — dirham SVG for AED, dollar sign for USD.
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

  /// Icon glyph color (dirham SVG + dollar sign).
  static const Color glyphColor = Color(0xFF1A1A1A);

  /// Legacy alias used by some price text styles — unchanged (green amounts).
  static const Color green = Color(0xFF619D50);

  @override
  Widget build(BuildContext context) {
    final glyph = AppColors.title(context);
    final normalized = CreateAdCurrency.normalize(currency);
    if (normalized == CreateAdCurrency.aed) {
      final dimension = matchTextSize ? size : size.w;
      final height = matchTextSize ? size : (size * 0.9).h;
      return SizedBox(
        width: dimension,
        height: height,
        child: Center(
          child: SvgPicture.asset(
            AppAssets.dirhamSvg,
            width: dimension,
            height: height,
            colorFilter: ColorFilter.mode(glyph, BlendMode.srcIn),
          ),
        ),
      );
    }

    final dollarSize = matchTextSize ? size : size.sp;
    final boxHeight = matchTextSize ? size : size.sp;
    return SizedBox(
      height: boxHeight,
      child: Center(
        child: Text(
          '\$',
          style: TextStyle(
            color: glyph,
            fontSize: dollarSize,
            fontWeight: FontWeight.w700,
            height: 1,
          ),
        ),
      ),
    );
  }
}
