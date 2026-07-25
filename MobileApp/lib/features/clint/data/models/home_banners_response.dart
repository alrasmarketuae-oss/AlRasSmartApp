import 'package:alrasmarket/core/services/api_constants.dart';
import 'package:alrasmarket/features/clint/domain/entities/banner_adds.dart';

class HomeBannersResponse {
  HomeBannersResponse({required this.count, required this.items});

  final int count;
  final List<HomeBannerItem> items;

  factory HomeBannersResponse.fromJson(Map<String, dynamic> json) {
    final raw = json['items'] as List<dynamic>? ?? [];
    final items = raw
        .map((e) => HomeBannerItem.fromJson(e as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => a.displayOrder.compareTo(b.displayOrder));
    return HomeBannersResponse(
      count: json['count'] as int? ?? items.length,
      items: items,
    );
  }

  List<BannerAdds> toBannerAdds() {
    return items.map((e) {
      final imageUrl = ApiConstants.resolveMediaUrl(e.imagePath);
      final link = e.linkUrl?.trim();
      final validLink = (link != null &&
              link.isNotEmpty &&
              link != '..' &&
              link != '.')
          ? link
          : null;
      return BannerAdds(
        bannerId: e.id,
        imageUrl: imageUrl,
        linkUrl: validLink,
        isActive: true,
      );
    }).toList();
  }
}

class HomeBannerItem {
  HomeBannerItem({
    required this.id,
    required this.imagePath,
    this.linkUrl,
    required this.displayOrder,
  });

  final int id;
  final String imagePath;
  final String? linkUrl;
  final int displayOrder;

  factory HomeBannerItem.fromJson(Map<String, dynamic> json) {
    return HomeBannerItem(
      id: json['id'] as int,
      imagePath: json['imagePath'] as String? ?? '',
      linkUrl: json['linkUrl'] as String?,
      displayOrder: json['displayOrder'] as int? ?? 0,
    );
  }
}
