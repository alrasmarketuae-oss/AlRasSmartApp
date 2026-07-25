import 'package:alrasmarket/features/clint/data/models/my_order_model.dart';

class MyOrdersPageModel {
  const MyOrdersPageModel({
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
  final List<MyOrderModel> items;

  factory MyOrdersPageModel.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] as List<dynamic>? ?? const [];
    return MyOrdersPageModel(
      page: int.tryParse(json['page']?.toString() ?? '') ?? 1,
      pageSize: int.tryParse(json['pageSize']?.toString() ?? '') ?? 20,
      totalCount: int.tryParse(json['totalCount']?.toString() ?? '') ?? 0,
      totalPages: int.tryParse(json['totalPages']?.toString() ?? '') ?? 0,
      items: rawItems
          .whereType<Map<String, dynamic>>()
          .map(MyOrderModel.fromJson)
          .toList(),
    );
  }
}
