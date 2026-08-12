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
    return CategoryModel(
      categoryId: json['categoryId'] as int? ?? json['CategoryId'] as int? ?? 0,
      nameEn: json['nameEn'] as String? ?? json['NameEn'] as String? ?? '',
      nameAr: json['nameAr'] as String? ?? json['NameAr'] as String? ?? '',
      imgPath: json['imgPath'] as String? ?? json['ImgPath'] as String? ?? '',
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
    final raw = json['items'] as List<dynamic>? ?? [];
    final items = raw
        .map((e) => CategoryModel.fromJson(e as Map<String, dynamic>))
        .where((c) => c.categoryId > 0 && (c.nameEn.isNotEmpty || c.nameAr.isNotEmpty))
        .toList();
    return CategoriesResponse(
      count: json['count'] as int? ?? items.length,
      items: items,
    );
  }
}
