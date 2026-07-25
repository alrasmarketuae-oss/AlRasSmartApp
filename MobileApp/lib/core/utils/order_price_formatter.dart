import 'package:alrasmarket/features/clint/data/models/my_order_model.dart';
import 'package:intl/intl.dart';

/// Order price display aligned with backend [ProductCurrencyHelper].
class OrderPriceFormatter {
  OrderPriceFormatter._();

  static final NumberFormat _amountFormat = NumberFormat('#,##0.00');

  static String resolveCurrency(MyOrderModel order) {
    final apiCurrency = order.currency.trim().toUpperCase();
    if (apiCurrency.isNotEmpty) {
      return apiCurrency;
    }
    return 'AED';
  }

  static String formatAmountOnly(double amount) {
    return _amountFormat.format(amount);
  }

  static String displayAmount(MyOrderModel order) {
    final amount = order.displayTotalPrice;
    if (amount > 0) {
      return formatAmountOnly(amount);
    }

    final formatted = displayTotal(order);
    final numeric = formatted.replaceAll(RegExp(r'[^0-9.,]'), '').trim();
    return numeric;
  }

  static String displayTotal(MyOrderModel order) {
    final chargedFormatted = order.chargedGrandTotalFormatted.trim();
    if (chargedFormatted.isNotEmpty) {
      return chargedFormatted;
    }

    final apiFormatted = order.amountFormatted.trim();
    if (apiFormatted.isNotEmpty) {
      return apiFormatted;
    }

    final customerFormatted = order.customerTotalPriceFormatted.trim();
    if (customerFormatted.isNotEmpty) {
      return customerFormatted;
    }

    final amount = order.displayTotalPrice;
    return formatAmount(amount, resolveCurrency(order));
  }

  static String formatAmount(double amount, String currency) {
    final code = currency.trim().toUpperCase();
    final formatted = _amountFormat.format(amount);
    if (code == 'USD') {
      return '\$$formatted';
    }
    if (code == 'AED') {
      return '$formatted AED';
    }
    return '$formatted $code';
  }
}
