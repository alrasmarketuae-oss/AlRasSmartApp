import 'package:alrasmarket/features/company/data/models/my_listing_product_model.dart';
import 'package:flutter/material.dart';

/// Accent colors for marketplace product cards — stable color per category.
class ProductCardTheme {
  const ProductCardTheme({
    required this.accent,
    required this.accentSoft,
  });

  final Color accent;
  final Color accentSoft;

  /// Distinct palette (one color per category bucket).
  static const _palette = <ProductCardTheme>[
    ProductCardTheme(accent: Color(0xFF3A7DC5), accentSoft: Color(0xFFE8F1FA)), // blue
    ProductCardTheme(accent: Color(0xFF2F6B4F), accentSoft: Color(0xFFE8F3EC)), // green
    ProductCardTheme(accent: Color(0xFFC45C26), accentSoft: Color(0xFFF8EDE6)), // terracotta
    ProductCardTheme(accent: Color(0xFF7C3AED), accentSoft: Color(0xFFF1E9FE)), // purple
    ProductCardTheme(accent: Color(0xFF0F766E), accentSoft: Color(0xFFE6F4F3)), // teal
    ProductCardTheme(accent: Color(0xFFB45309), accentSoft: Color(0xFFF8EEDF)), // amber
    ProductCardTheme(accent: Color(0xFFBE185D), accentSoft: Color(0xFFF9E8F0)), // rose
    ProductCardTheme(accent: Color(0xFF1D4ED8), accentSoft: Color(0xFFE8EEFB)), // indigo
    ProductCardTheme(accent: Color(0xFF15803D), accentSoft: Color(0xFFE7F5EC)), // emerald
    ProductCardTheme(accent: Color(0xFF9333EA), accentSoft: Color(0xFFF4E9FC)), // violet
    ProductCardTheme(accent: Color(0xFFDC2626), accentSoft: Color(0xFFFBEAEA)), // red
    ProductCardTheme(accent: Color(0xFF0891B2), accentSoft: Color(0xFFE6F6FA)), // cyan
  ];

  static ProductCardTheme forProduct(MyListingProductModel product) {
    final key = _categoryKey(product);
    final index = key.hashCode.abs() % _palette.length;
    return _palette[index];
  }

  static String _categoryKey(MyListingProductModel product) {
    if (product.categoryId != null && product.categoryId! > 0) {
      return 'id:${product.categoryId}';
    }
    final name = product.categoryName.trim().toLowerCase();
    if (name.isNotEmpty && name != '—') {
      return 'name:$name';
    }
    // Fallback by product service type so Retail/Booking/Offers/Requests stay distinct.
    final typeId = product.productTypeId;
    if (typeId != null) return 'type:$typeId';
    final typeName = product.productTypeName.trim().toLowerCase();
    if (typeName.isNotEmpty) return 'typename:$typeName';
    return 'product:${product.productId}';
  }
}
