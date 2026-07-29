import 'dart:async';

import 'package:alrasmarket/core/cache/api_cache_keys.dart';
import 'package:alrasmarket/core/cache/api_cache_store.dart';
import 'package:alrasmarket/core/services/api_constants.dart';
import 'package:alrasmarket/core/services/dio_helper.dart';
import 'package:flutter/foundation.dart';

/// Local index of product names for search autocomplete.
class ProductSearchIndexService {
  ProductSearchIndexService._();

  static final ProductSearchIndexService instance = ProductSearchIndexService._();

  static const _cacheKey = ApiCacheKeys.productSearchNames;

  List<String> _names = [];
  bool _ready = false;

  bool get isReady => _ready && _names.isNotEmpty;

  int get totalCount => _names.length;

  Future<void> init() async {
    // Disk only at startup — network refresh must not block native splash.
    await _loadFromDisk();
    if (_names.isEmpty) {
      await _loadFallbackFromProductCaches();
    }
    debugPrint(
      'ProductSearchIndexService ready=$_ready count=${_names.length}',
    );
    unawaited(refresh());
  }

  /// Rebuild search index after catalog mutations.
  Future<void> refresh() async {
    await ApiCacheStore.instance.remove(_cacheKey);
    await _refreshFromNetwork();
    if (_names.isEmpty) {
      await _loadFallbackFromProductCaches();
    }
  }

  Iterable<String> suggest(String query, {int limit = 8}) sync* {
    final normalized = query.trim().toLowerCase();
    if (normalized.isEmpty || _names.isEmpty) return;

    var count = 0;
    for (final name in _names) {
      if (name.toLowerCase().contains(normalized)) {
        yield name;
        count++;
        if (count >= limit) break;
      }
    }
  }

  Future<void> _loadFromDisk() async {
    final entry = await ApiCacheStore.instance.read(
      _cacheKey,
      allowStale: true,
    );
    if (entry == null) return;

    try {
      _applyPayload(entry.data);
    } catch (_) {
      await ApiCacheStore.instance.remove(_cacheKey);
    }
  }

  Future<void> _refreshFromNetwork() async {
    try {
      final response = await DioHelper.getData(
        url: ApiConstants.productsSearchNamesEndPoint,
      );
      if (response?.statusCode != 200) {
        debugPrint(
          'ProductSearchIndexService HTTP ${response?.statusCode}',
        );
        return;
      }

      final map = _asStringKeyedMap(response?.data);
      if (map == null) return;

      _applyPayload(map);
      await ApiCacheStore.instance.write(
        _cacheKey,
        map,
        ApiCacheTtl.catalog,
      );
    } catch (e) {
      debugPrint('ProductSearchIndexService network error: $e');
    }
  }

  Future<void> _loadFallbackFromProductCaches() async {
    final keys = [
      ApiCacheKeys.homeProducts(1, 20),
      ApiCacheKeys.featuredProducts(1, 100),
      ApiCacheKeys.productsByType('retail', 1, 50),
    ];

    final collected = <String>{};
    for (final key in keys) {
      final entry = await ApiCacheStore.instance.read(key, allowStale: true);
      if (entry == null) continue;
      collected.addAll(_extractNamesFromPayload(entry.data));
    }

    if (collected.isEmpty) return;

    _names = collected.toList()..sort();
    _ready = _names.isNotEmpty;
  }

  Set<String> _extractNamesFromPayload(dynamic data) {
    final names = <String>{};
    if (data is! Map) return names;

    final items = data['items'];
    if (items is! List) return names;

    for (final item in items) {
      if (item is! Map) continue;
      final map = Map<String, dynamic>.from(item);
      final name = (map['productName'] ?? map['ProductName'] ?? map['nameEn'] ??
              map['NameEn'] ??
              map['name'] ??
              map['Name'])
          ?.toString()
          .trim();
      if (name != null && name.isNotEmpty) {
        names.add(name);
      }
    }
    return names;
  }

  Map<String, dynamic>? _asStringKeyedMap(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    return null;
  }

  void _applyPayload(dynamic data) {
    final map = _asStringKeyedMap(data);
    if (map == null) return;

    final raw = map['names'] ?? map['Names'];
    final codesRaw = map['productCodes'] ?? map['ProductCodes'];
    final collected = <String>{};

    if (raw is List) {
      collected.addAll(
        raw
            .map((item) => item.toString().trim())
            .where((item) => item.isNotEmpty),
      );
    }

    if (codesRaw is List) {
      collected.addAll(
        codesRaw
            .map((item) => item.toString().trim().toUpperCase())
            .where((item) => item.isNotEmpty),
      );
    }

    _names = collected.toList()..sort();
    _ready = _names.isNotEmpty;
  }
}
