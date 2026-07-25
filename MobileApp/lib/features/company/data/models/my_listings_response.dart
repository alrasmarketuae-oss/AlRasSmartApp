import 'my_listing_product_model.dart';

class MyListingsResponse {
  const MyListingsResponse({
    required this.ownerName,
    required this.productCount,
    required this.products,
  });

  final String ownerName;
  final int productCount;
  final List<MyListingProductModel> products;

  factory MyListingsResponse.fromJson(Map<String, dynamic> json) {
    final productsJson = json['products'] as List<dynamic>? ?? [];
    return MyListingsResponse(
      ownerName: json['ownerName']?.toString() ?? '',
      productCount: int.tryParse(json['productCount']?.toString() ?? '') ?? 0,
      products: productsJson
          .map(
            (item) => MyListingProductModel.fromJson(
              item as Map<String, dynamic>,
            ),
          )
          .toList(),
    );
  }
}
