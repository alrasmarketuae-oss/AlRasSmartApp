import 'package:alrasmarket/features/company/data/models/my_listing_product_model.dart';

enum SearchHistoryType { text, code, image }

class SearchHistoryEntry {
  const SearchHistoryEntry({
    required this.id,
    required this.type,
    required this.label,
    required this.createdAtMs,
    this.query,
    this.imagePath,
    this.suggestedNames = const [],
    this.products = const [],
  });

  final String id;
  final SearchHistoryType type;
  final String label;
  final int createdAtMs;
  final String? query;
  final String? imagePath;
  final List<String> suggestedNames;
  final List<Map<String, dynamic>> products;

  bool get hasCachedProducts => products.isNotEmpty;

  /// Image AI names and/or product matches saved for offline replay.
  bool get canReplayWithoutApi =>
      hasCachedProducts ||
      (type == SearchHistoryType.image && suggestedNames.isNotEmpty);

  List<MyListingProductModel> toProductModels() => products
      .map(MyListingProductModel.fromJson)
      .toList(growable: false);

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'label': label,
        'createdAtMs': createdAtMs,
        if (query != null) 'query': query,
        if (imagePath != null) 'imagePath': imagePath,
        'suggestedNames': suggestedNames,
        'products': products,
      };

  factory SearchHistoryEntry.fromJson(Map<String, dynamic> json) {
    final typeName = json['type']?.toString() ?? 'text';
    final type = SearchHistoryType.values.firstWhere(
      (value) => value.name == typeName,
      orElse: () => SearchHistoryType.text,
    );

    final rawProducts = json['products'];
    final products = rawProducts is List
        ? rawProducts
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList(growable: false)
        : const <Map<String, dynamic>>[];

    final rawNames = json['suggestedNames'];
    final suggestedNames = rawNames is List
        ? rawNames.map((item) => item.toString()).toList(growable: false)
        : const <String>[];

    return SearchHistoryEntry(
      id: json['id']?.toString() ?? '',
      type: type,
      label: json['label']?.toString() ?? '',
      createdAtMs: int.tryParse(json['createdAtMs']?.toString() ?? '') ??
          DateTime.now().millisecondsSinceEpoch,
      query: json['query']?.toString(),
      imagePath: json['imagePath']?.toString(),
      suggestedNames: suggestedNames,
      products: products,
    );
  }
}

bool isProductCodeQuery(String value) {
  final normalized = value.trim().toUpperCase().replaceAll(RegExp(r'[\s\-_]'), '');
  return RegExp(r'^RS[23456789ABCDEFGHJKLMNPQRSTUVWXYZ]{9}$').hasMatch(normalized);
}

SearchHistoryType resolveSearchHistoryType(String query) =>
    isProductCodeQuery(query) ? SearchHistoryType.code : SearchHistoryType.text;

/// JSON shape compatible with [MyListingProductModel.fromJson] for history replay.
Map<String, dynamic> productModelToHistoryJson(MyListingProductModel product) {
  return {
    'productId': product.productId,
    'productCode': product.productCode,
    'ownerId': product.ownerId,
    'productName': product.productName,
    'nameEn': product.nameEn,
    'nameAr': product.nameAr,
    'createdLanguage': product.createdLanguage,
    'categoryName': product.categoryName,
    'categoryImagePath': product.categoryImagePath,
    if (product.categoryId != null) 'categoryId': product.categoryId,
    if (product.productTypeId != null) 'productTypeId': product.productTypeId,
    'productTypeName': product.productTypeName,
    'description': product.description,
    'descriptionEn': product.descriptionEn,
    'descriptionAr': product.descriptionAr,
    'price': product.displayPrice,
    'displayPrice': product.displayPrice,
    'priceUsd': product.priceUsd,
    'currency': product.currency,
    'quantity': product.quantity,
    'unitName': product.unitName,
    'minimumOrderQuantity': product.minimumOrderQuantity,
    'maximumOrderQuantity': product.maximumOrderQuantity,
    'status': product.status,
    'approvalStatus': product.approvalStatus,
    'negotiable': product.negotiable,
    'isFeatured': product.isFeatured,
    'viewsCount': product.viewsCount,
    'images': product.images,
    'documents': product.documents,
    'shipping': {
      'routeFromCountry': product.shipping.routeFromCountry,
      'routeFromPort': product.shipping.routeFromPort,
      'routeToCountry': product.shipping.routeToCountry,
      'routeToPort': product.shipping.routeToPort,
      'routeSummary': product.shipping.routeSummary,
      'additionalShippingNotes': product.shipping.additionalShippingNotes,
      'hasRouteInformation': product.shipping.hasRouteInformation,
    },
    'discountPercentage': product.discountPercentage,
    'discountDays': product.discountDays,
    'supplierNotes': product.supplierNotes,
    'shippingDuration': product.shippingDuration,
    'videoPath': product.videoPath,
    'videoPaths': product.videoPaths,
    'videos': product.videos.map((video) => video.toJson()).toList(),
    'videoDurationSeconds': product.videoDurationSeconds,
    'createdAt': product.createdAt,
    'updatedAt': product.updatedAt,
    'hasRetailPricing': product.hasRetailPricing,
    'retailPrice': product.retailPrice,
    'retailUnitName': product.retailUnitName,
    'retailQuantity': product.retailQuantity,
    if (product.requestTypeId != null) 'requestTypeId': product.requestTypeId,
    'requestTypeName': product.requestTypeName,
    'shippingDescriptionEn': product.shippingDescriptionEn,
    if (product.packaging != null) 'packaging': product.packaging,
    'packagingDetails': product.packagingDetails,
  };
}
