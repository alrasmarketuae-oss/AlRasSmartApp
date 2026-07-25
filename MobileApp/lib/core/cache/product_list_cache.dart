import 'package:alrasmarket/core/cache/api_cache_keys.dart';
import 'package:alrasmarket/core/cache/api_cache_store.dart';
import 'package:alrasmarket/core/services/dio_helper.dart';
import 'package:alrasmarket/features/company/data/models/my_listing_product_model.dart';

/// Persists raw product list API payloads for home/category/type feeds.
class ProductListCache {
  ProductListCache._();

  static Future<bool> hydrate({
    required String cacheKey,
    required void Function(List<MyListingProductModel> products) apply,
    required List<MyListingProductModel> Function(dynamic data) parse,
  }) async {
    final entry = await ApiCacheStore.instance.read(cacheKey, allowStale: true);
    if (entry == null) return false;
    try {
      final products = parse(entry.data);
      if (products.isEmpty) return false;
      apply(products);
      return true;
    } catch (_) {
      return false;
    }
  }

  static Future<void> save({
    required String cacheKey,
    required dynamic rawData,
  }) async {
    if (rawData == null) return;
    await ApiCacheStore.instance.write(
      cacheKey,
      rawData,
      ApiCacheTtl.products,
    );
  }

  static Future<dynamic> fetchRaw({
    required String url,
    Map<String, dynamic>? query,
    String? token,
  }) async {
    final response = await DioHelper.getData(
      url: url,
      query: query,
      token: token,
    );
    final status = response?.statusCode ?? 0;
    if (status < 200 || status >= 300) {
      throw Exception('Request failed ($status)');
    }
    return response?.data;
  }
}
