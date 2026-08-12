import 'package:alrasmarket/core/widgets/currency_icon.dart';
import 'package:alrasmarket/features/company/presentation/models/create_ad_currency.dart';
import 'package:flutter/material.dart';

class CreateAdCurrencyLabel extends StatelessWidget {
  const CreateAdCurrencyLabel({
    super.key,
    required this.currency,
    this.iconHeight,
    this.matchTextSize,
  });

  final String currency;
  final double? iconHeight;
  final bool? matchTextSize;

  @override
  Widget build(BuildContext context) {
    return CurrencyIcon(
      currency: CreateAdCurrency.normalize(currency),
      size: iconHeight ?? 20,
      matchTextSize: matchTextSize ?? iconHeight != null,
    );
  }
}
