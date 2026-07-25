import 'package:alrasmarket/features/company/data/models/my_request_offer_model.dart';

class MyRequestOffersPageModel {
  const MyRequestOffersPageModel({
    required this.page,
    required this.pageSize,
    required this.totalCount,
    required this.totalPages,
    required this.items,
  });

  final int page;
  final int pageSize;
  final int totalCount;
  final int totalPages;
  final List<MyRequestOfferModel> items;

  bool get hasMore => page < totalPages;

  factory MyRequestOffersPageModel.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] as List<dynamic>? ?? const [];

    return MyRequestOffersPageModel(
      page: int.tryParse(json['page']?.toString() ?? '') ?? 1,
      pageSize: int.tryParse(json['pageSize']?.toString() ?? '') ?? 20,
      totalCount: int.tryParse(json['totalCount']?.toString() ?? '') ?? 0,
      totalPages: int.tryParse(json['totalPages']?.toString() ?? '') ?? 0,
      items: rawItems
          .whereType<Map<String, dynamic>>()
          .map(MyRequestOfferModel.fromJson)
          .toList(),
    );
  }
}
