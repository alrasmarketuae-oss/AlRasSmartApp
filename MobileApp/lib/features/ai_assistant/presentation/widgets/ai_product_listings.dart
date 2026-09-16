import 'dart:convert';

import 'package:alrasmarket/core/utils/product_grid_layout.dart';
import 'package:alrasmarket/features/clint/presentation/widgets/product _card.dart';
import 'package:alrasmarket/features/company/data/models/my_listing_product_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Product cards shown under an AI assistant reply (same card as marketplace).
class AiProductListings extends StatelessWidget {
  const AiProductListings({super.key, required this.products});

  final List<MyListingProductModel> products;

  static List<MyListingProductModel> parse(dynamic raw) {
    final source = _extractList(raw);
    if (source.isEmpty) return const [];

    final items = <MyListingProductModel>[];
    final seen = <String>{};
    for (final item in source) {
      final map = _asStringKeyMap(item);
      if (map == null) continue;
      final productId = _readProductId(map);
      if (productId.isEmpty) continue;
      map['productId'] = productId;
      map.putIfAbsent('ProductId', () => productId);
      map.putIfAbsent('id', () => productId);
      map['images'] = map['images'] ?? map['Images'] ?? const [];
      map['quantity'] = map['quantity'] ?? map['Quantity'];
      map['unitName'] = map['unitName'] ?? map['UnitName'];
      map['productName'] = map['productName'] ??
          map['nameEn'] ??
          map['NameEn'] ??
          map['nameAr'] ??
          map['NameAr'] ??
          map['name'];
      map['price'] = map['price'] ??
          map['displayPrice'] ??
          map['DisplayPrice'] ??
          map['Price'];
      map['shipping'] ??= <String, dynamic>{};
      try {
        final product = MyListingProductModel.fromJson(map);
        if (product.productId.trim().isEmpty) continue;
        if (!seen.add(product.productId.toLowerCase())) continue;
        items.add(product);
      } catch (_) {
        final fallback = MyListingProductModel.notificationStub(
          productId: productId,
          productName: (map['productName'] ??
                  map['nameEn'] ??
                  map['NameEn'] ??
                  map['nameAr'] ??
                  map['name'] ??
                  '')
              .toString(),
        );
        if (!seen.add(fallback.productId.toLowerCase())) continue;
        items.add(fallback);
      }
    }
    return items;
  }

  static List<dynamic> _extractList(dynamic raw) {
    var source = raw;
    if (source == null) return const [];
    if (source is String && source.trim().isNotEmpty) {
      try {
        source = jsonDecode(source);
      } catch (_) {
        return const [];
      }
    }
    if (source is Map) {
      final map = source.map((key, value) => MapEntry(key.toString(), value));
      // Tool payloads sometimes nest cards under content / data.
      final nestedContent = map['content'] ?? map['Content'];
      if (nestedContent is String && nestedContent.trim().isNotEmpty) {
        try {
          final decoded = jsonDecode(nestedContent);
          final fromContent = _extractList(decoded);
          if (fromContent.isNotEmpty) return fromContent;
        } catch (_) {}
      }
      source = map['listings'] ??
          map['Listings'] ??
          map['items'] ??
          map['Items'] ??
          map['products'] ??
          map['Products'] ??
          map['cheapest'] ??
          map['mostExpensive'] ??
          map['alternatives'] ??
          map['data'] ??
          map['Data'];
    }
    if (source is List) return List<dynamic>.from(source);
    if (source is Iterable && source is! String) {
      return List<dynamic>.from(source);
    }
    return const [];
  }

  static Map<String, dynamic>? _asStringKeyMap(dynamic item) {
    if (item is String && item.trim().isNotEmpty) {
      try {
        item = jsonDecode(item);
      } catch (_) {
        return null;
      }
    }
    if (item is Map<String, dynamic>) return Map<String, dynamic>.from(item);
    if (item is Map) {
      return item.map((key, value) => MapEntry(key.toString(), value));
    }
    return null;
  }

  static String _readProductId(Map<String, dynamic> map) {
    for (final key in const [
      'productId',
      'ProductId',
      'productID',
      'id',
      'Id',
      'ID',
    ]) {
      var value = map[key]?.toString().trim() ?? '';
      if (value.isEmpty || value.toLowerCase() == 'null') continue;
      // Normalize GUID braces / whitespace.
      if (value.startsWith('{') && value.endsWith('}')) {
        value = value.substring(1, value.length - 1).trim();
      }
      if (value.isNotEmpty) return value;
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    if (products.isEmpty) return const SizedBox.shrink();
    final spacing = 10.w;
    final cardHeight = ProductGridLayout.estimatedCardHeight(context);
    final rows = <Widget>[];
    for (var i = 0; i < products.length; i += 2) {
      rows.add(
        Padding(
          padding: EdgeInsets.only(bottom: i + 2 < products.length ? spacing : 0),
          child: SizedBox(
            height: cardHeight,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: ProductCard(
                    title: products[i].productName,
                    product: products[i],
                    preferRetailChannel: products[i].preferRetailFromSearchListing,
                  ),
                ),
                SizedBox(width: spacing),
                Expanded(
                  child: i + 1 < products.length
                      ? ProductCard(
                          title: products[i + 1].productName,
                          product: products[i + 1],
                          preferRetailChannel:
                              products[i + 1].preferRetailFromSearchListing,
                        )
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.only(top: 8.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: rows,
      ),
    );
  }
}
