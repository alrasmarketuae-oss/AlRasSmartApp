import 'package:alrasmarket/core/services/api_constants.dart';
import 'package:alrasmarket/core/utils/category_localization.dart';
import 'package:flutter/widgets.dart';

class CategoryModel {
  const CategoryModel({
    required this.categoryId,
    required this.nameEn,
    required this.nameAr,
    required this.imgPath,
    this.commissionPercent = 0,
  });

  final int categoryId;
  final String nameEn;
  final String nameAr;
  final String imgPath;
  final double commissionPercent;

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    int readId() {
      final raw = json['categoryId'] ?? json['CategoryId'];
      if (raw is int) return raw;
      if (raw is num) return raw.toInt();
      return int.tryParse(raw?.toString() ?? '') ?? 0;
    }

    return CategoryModel(
      categoryId: readId(),
      nameEn: json['nameEn']?.toString() ?? json['NameEn']?.toString() ?? '',
      nameAr: json['nameAr']?.toString() ?? json['NameAr']?.toString() ?? '',
      imgPath: json['imgPath']?.toString() ?? json['ImgPath']?.toString() ?? '',
      commissionPercent:
          (json['commissionPercent'] as num?)?.toDouble() ??
          (json['CommissionPercent'] as num?)?.toDouble() ??
          0,
    );
  }

  String displayName(BuildContext context) =>
      localizedCategoryName(context, nameEn, nameAr: nameAr);

  String get imageUrl {
    final path = imgPath.trim();
    if (path.isEmpty || path.endsWith('default.jpg')) return '';
    return ApiConstants.resolveMediaUrl(path);
  }
}

class CategoriesResponse {
  const CategoriesResponse({required this.count, required this.items});

  final int count;
  final List<CategoryModel> items;

  factory CategoriesResponse.fromJson(Map<String, dynamic> json) {
    final raw = json['items'] as List<dynamic>? ?? const [];
    final items = raw
        .whereType<Map>()
        .map((e) => CategoryModel.fromJson(Map<String, dynamic>.from(e)))
        .where(
          (c) =>
              c.categoryId > 0 && (c.nameEn.isNotEmpty || c.nameAr.isNotEmpty),
        )
        .toList();
    return CategoriesResponse(
      count: json['count'] as int? ?? items.length,
      items: items,
    );
  }
}
