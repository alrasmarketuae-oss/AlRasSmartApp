class BannerAdds {
  final int bannerId;
  final String? title;
  final String? titleEn;
  final String? titleAr;
  final String imageUrl;
  final String? linkUrl;
  final int? categoryId;
  final bool isActive;

  BannerAdds({
    required this.bannerId,
    this.title,
    this.titleEn,
    this.titleAr,
    required this.imageUrl,
    this.linkUrl,
    this.categoryId,
    required this.isActive,
  });
}
