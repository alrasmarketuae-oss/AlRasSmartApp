import 'package:alrasmarket/core/widgets/currency_icon.dart';
import 'package:alrasmarket/features/company/data/models/my_listing_product_model.dart';
import 'package:alrasmarket/core/utils/product_price_formatter.dart';
import 'package:alrasmarket/core/utils/thousands_separator_input_formatter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ProductPriceText extends StatelessWidget {
  const ProductPriceText({
    super.key,
    required this.amount,
    required this.currency,
    this.suffix,
    this.amountStyle,
    this.iconSize = 14,
    this.maxLines = 1,
    this.matchCurrencyToAmount = false,
    this.scaleToFit = false,
  });

  final String amount;
  final String currency;
  final String? suffix;
  final TextStyle? amountStyle;
  final double iconSize;
  final int maxLines;
  final bool matchCurrencyToAmount;

  /// When true, renders a single intrinsic row (no ellipsis) for [FittedBox] parents.
  final bool scaleToFit;

  factory ProductPriceText.fromProduct(
    MyListingProductModel product, {
    TextStyle? amountStyle,
    double iconSize = 14,
    bool withUnit = false,
    int maxLines = 1,
    bool matchCurrencyToAmount = false,
    bool scaleToFit = false,
    bool preferRetail = false,
  }) {
    return ProductPriceText(
      amount: ProductPriceFormatter.amount(
        product,
        preferRetail: preferRetail,
      ),
      currency: ProductPriceFormatter.currencyCode(product),
      suffix: withUnit
          ? ProductPriceFormatter.unitSuffix(
              product,
              preferRetail: preferRetail,
            )
          : null,
      amountStyle: amountStyle,
      iconSize: iconSize,
      maxLines: maxLines,
      matchCurrencyToAmount: matchCurrencyToAmount,
      scaleToFit: scaleToFit,
    );
  }

  factory ProductPriceText.unitPrice(
    MyListingProductModel product, {
    TextStyle? amountStyle,
    double iconSize = 14,
    int maxLines = 1,
    bool matchCurrencyToAmount = false,
    bool scaleToFit = false,
    bool preferRetail = false,
  }) {
    return ProductPriceText.fromProduct(
      product,
      amountStyle: amountStyle,
      iconSize: iconSize,
      withUnit: true,
      maxLines: maxLines,
      matchCurrencyToAmount: matchCurrencyToAmount,
      scaleToFit: scaleToFit,
      preferRetail: preferRetail,
    );
  }

  factory ProductPriceText.total(
    MyListingProductModel product,
    double total, {
    TextStyle? amountStyle,
    double iconSize = 16,
  }) {
    return ProductPriceText(
      amount: ThousandsNumberInput.format(total, allowDecimal: true),
      currency: ProductPriceFormatter.currencyCode(product),
      amountStyle: amountStyle,
      iconSize: iconSize,
    );
  }

  @override
  Widget build(BuildContext context) {
    final resolvedAmountStyle = amountStyle ??
        TextStyle(
          color: CurrencyIcon.green,
          fontSize: 13.sp,
          fontWeight: FontWeight.bold,
          height: 1.2,
        );

    final resolvedIconSize = matchCurrencyToAmount
        ? (resolvedAmountStyle.fontSize ?? iconSize)
        : iconSize;

    if (scaleToFit) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(amount, style: resolvedAmountStyle),
          SizedBox(width: 4.w),
          CurrencyIcon(
            currency: currency,
            size: resolvedIconSize,
            matchTextSize: matchCurrencyToAmount,
          ),
          if (suffix != null && suffix!.isNotEmpty)
            Text(suffix!, style: resolvedAmountStyle),
        ],
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Flexible(
          fit: FlexFit.loose,
          child: Text(
            amount,
            maxLines: maxLines,
            overflow: TextOverflow.ellipsis,
            style: resolvedAmountStyle,
          ),
        ),
        SizedBox(width: 4.w),
        CurrencyIcon(
          currency: currency,
          size: resolvedIconSize,
          matchTextSize: matchCurrencyToAmount,
        ),
        if (suffix != null && suffix!.isNotEmpty) ...[
          Flexible(
            fit: FlexFit.loose,
            child: Text(
              suffix!,
              maxLines: maxLines,
              overflow: TextOverflow.ellipsis,
              style: resolvedAmountStyle,
            ),
          ),
        ],
      ],
    );
  }
}
