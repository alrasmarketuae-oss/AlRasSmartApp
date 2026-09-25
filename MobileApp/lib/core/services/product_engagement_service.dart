import 'package:alrasmarket/core/services/api_constants.dart';
import 'package:alrasmarket/core/services/dio_helper.dart';

class ProductEngagementService {
  ProductEngagementService._();

  static Future<void> trackFavorite(String productId) async {
    final id = productId.trim();
    if (id.isEmpty) return;
    try {
      await DioHelper.postData(
        url: ApiConstants.productIncreaseFavoriteEndPoint(id),
        data: const {},
      );
    } catch (_) {
      // Best-effort analytics; do not block bookmark UX.
    }
  }

  static Future<void> trackShare(String productId) async {
    final id = productId.trim();
    if (id.isEmpty) return;
    try {
      await DioHelper.postData(
        url: ApiConstants.productIncreaseShareEndPoint(id),
        data: const {},
      );
    } catch (_) {
      // Best-effort analytics; do not block share UX.
    }
  }

  static Future<ProductAdStatistics?> fetchOwnerStatistics(String productId) async {
    final id = productId.trim();
    if (id.isEmpty) return null;
    try {
      final response = await DioHelper.getData(
        url: ApiConstants.productStatisticsEndPoint(id),
      );
      final status = response?.statusCode ?? 0;
      if (status < 200 || status >= 300) return null;
      final data = response?.data;
      if (data is! Map) return null;
      return ProductAdStatistics.fromJson(Map<String, dynamic>.from(data));
    } catch (_) {
      return null;
    }
  }
}

class ProductAdStatistics {
  const ProductAdStatistics({
    required this.productId,
    required this.productName,
    required this.viewsCount,
    required this.cartAddsCount,
    required this.showCartAdds,
    required this.purchasesCount,
    required this.favoritesCount,
    required this.sharesCount,
  });

  final String productId;
  final String productName;
  final int viewsCount;
  final int cartAddsCount;
  final bool showCartAdds;
  final int purchasesCount;
  final int favoritesCount;
  final int sharesCount;

  factory ProductAdStatistics.fromJson(Map<String, dynamic> json) {
    int asInt(Object? raw) => int.tryParse(raw?.toString() ?? '') ?? 0;
    bool asBool(Object? raw) {
      if (raw is bool) return raw;
      final text = raw?.toString().trim().toLowerCase();
      return text == 'true' || text == '1';
    }

    return ProductAdStatistics(
      productId: (json['productId'] ?? json['ProductId'] ?? '').toString(),
      productName: (json['productName'] ?? json['ProductName'] ?? '').toString(),
      viewsCount: asInt(json['viewsCount'] ?? json['ViewsCount']),
      cartAddsCount: asInt(json['cartAddsCount'] ?? json['CartAddsCount']),
      showCartAdds: asBool(json['showCartAdds'] ?? json['ShowCartAdds']),
      purchasesCount: asInt(json['purchasesCount'] ?? json['PurchasesCount']),
      favoritesCount: asInt(json['favoritesCount'] ?? json['FavoritesCount']),
      sharesCount: asInt(json['sharesCount'] ?? json['SharesCount']),
    );
  }
}
