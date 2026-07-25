import 'package:alrasmarket/features/clint/data/models/my_order_model.dart';
import 'package:alrasmarket/generated/l10n.dart';

/// Product-type chips for My Orders (Requests live under Account → My Offers).
enum OrderProductTypeFilter {
  all,
  categories,
  retail,
  offers,
  booking;

  String label(S s) {
    switch (this) {
      case OrderProductTypeFilter.all:
        return s.filterAll;
      case OrderProductTypeFilter.categories:
        return s.categories;
      case OrderProductTypeFilter.retail:
        return s.retail;
      case OrderProductTypeFilter.offers:
        return s.offers;
      case OrderProductTypeFilter.booking:
        return s.booking;
    }
  }

  bool matches(MyOrderModel order) {
    switch (this) {
      case OrderProductTypeFilter.all:
        return true;
      case OrderProductTypeFilter.categories:
        final categoryId = order.categoryId;
        return categoryId != null && categoryId > 0;
      case OrderProductTypeFilter.retail:
        return _typeMatches(order, 'retail') ||
            _typeContains(order, 'تجز');
      case OrderProductTypeFilter.offers:
        return _typeMatches(order, 'offers') ||
            _typeMatches(order, 'offer') ||
            _typeContains(order, 'عرض');
      case OrderProductTypeFilter.booking:
        return _typeMatches(order, 'booking') ||
            _typeContains(order, 'بوكينج') ||
            _typeContains(order, 'حجز');
    }
  }

  static String _typeText(MyOrderModel order) {
    final en = order.productTypeNameEn.trim();
    if (en.isNotEmpty) return en.toLowerCase();
    return order.productTypeName.trim().toLowerCase();
  }

  static bool _typeMatches(MyOrderModel order, String wanted) {
    final en = order.productTypeNameEn.trim().toLowerCase();
    final ar = order.productTypeNameAr.trim().toLowerCase();
    final display = order.productTypeName.trim().toLowerCase();
    return en == wanted || display == wanted || ar == wanted;
  }

  static bool _typeContains(MyOrderModel order, String needle) {
    final n = needle.toLowerCase();
    return _typeText(order).contains(n) ||
        order.productTypeNameAr.trim().toLowerCase().contains(n) ||
        order.productTypeName.trim().toLowerCase().contains(n);
  }
}
