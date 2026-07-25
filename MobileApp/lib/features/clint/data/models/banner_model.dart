import 'package:alrasmarket/features/clint/domain/entities/banner_adds.dart';

class BannerModel extends BannerAdds {
  BannerModel({
    required super.bannerId,
    super.title,
    super.titleEn,
    super.titleAr,
    required super.imageUrl,
    super.linkUrl,
    super.categoryId,
    required super.isActive,
  });

  factory BannerModel.fromJson(Map<String, dynamic> json) {
    return BannerModel(
      bannerId: json['bannerId'] as int,
      title: json['title'] as String?,
      titleEn: json['titleEn'] as String?,
      titleAr: json['titleAr'] as String?,
      imageUrl: json['imageUrl'] as String,
      linkUrl: json['linkUrl'] as String?,
      categoryId: json['categoryId'] as int?,
      isActive: json['isActive'] as bool? ?? true,
    );
  }
}
