import 'package:alrasmarket/generated/l10n.dart';

class CreateAdCurrency {
  CreateAdCurrency._();

  static const usd = 'USD';
  static const aed = 'AED';

  static const options = <String>[aed, usd];

  /// Currencies shown in a free-select dropdown (AED first when available).
  static List<String> get selectableOptions => options;

  static String displayLabel(String currency) {
    switch (currency.toUpperCase()) {
      case aed:
        return 'AED';
      default:
        return 'USD';
    }
  }

  static String fullDisplayLabel(String currency, S s) {
    switch (normalize(currency)) {
      case aed:
        return s.currencyAedFull;
      default:
        return s.currencyUsdFull;
    }
  }

  static String normalize(String? value) {
    if (value == null || value.trim().isEmpty) return aed;
    return value.toUpperCase() == aed ? aed : usd;
  }
}
