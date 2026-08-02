import 'package:alrasmarket/core/services/api_constants.dart';
import 'package:alrasmarket/core/utils/localized_product_text.dart';
import 'package:alrasmarket/features/clint/data/models/my_order_image_model.dart';

class MyOrderModel {
  const MyOrderModel({
    required this.id,
    required this.productId,
    required this.customerName,
    required this.customerEmail,
    required this.customerPhone,
    required this.supplierName,
    required this.supplierEmail,
    required this.supplierPhone,
    required this.productName,
    this.productNameEn = '',
    this.productNameAr = '',
    required this.productDescription,
    this.productDescriptionEn = '',
    this.productDescriptionAr = '',
    required this.productTypeName,
    this.productTypeNameEn = '',
    this.productTypeNameAr = '',
    required this.categoryName,
    this.categoryNameEn = '',
    this.categoryNameAr = '',
    required this.categoryId,
    required this.primaryImagePath,
    required this.unitName,
    this.unitNameEn = '',
    this.unitNameAr = '',
    required this.statusId,
    required this.statusName,
    required this.statusLabelAr,
    required this.unitPrice,
    required this.totalPrice,
    required this.customerTotalPrice,
    required this.amountFormatted,
    required this.currency,
    required this.customerTotalPriceFormatted,
    required this.chargedGrandTotalAed,
    required this.chargedGrandTotalFormatted,
    required this.quantity,
    required this.paymentMethod,
    required this.paymentMethodName,
    required this.createdAt,
    required this.isApproved,
    required this.notes,
    required this.videoPaths,
    required this.images,
    required this.portId,
    required this.portName,
    this.refundedAtUtc,
    this.isRefunded = false,
    this.returnReason,
    this.returnMediaPaths = const [],
    this.returnRequestedAtUtc,
    this.returnAdminResponse,
    this.returnRespondedAtUtc,
    this.statusHistory = const [],
  });

  final int id;
  final String productId;
  final String customerName;
  final String customerEmail;
  final String customerPhone;
  final String supplierName;
  final String supplierEmail;
  final String supplierPhone;
  /// Locale-baked display name (prefer [localizedProductName] with UI locale).
  final String productName;
  final String productNameEn;
  final String productNameAr;
  final String productDescription;
  final String productDescriptionEn;
  final String productDescriptionAr;
  final String productTypeName;
  final String productTypeNameEn;
  final String productTypeNameAr;
  final String categoryName;
  final String categoryNameEn;
  final String categoryNameAr;
  final int? categoryId;
  final String? primaryImagePath;
  final String unitName;
  final String unitNameEn;
  final String unitNameAr;
  final int statusId;
  final String statusName;
  final String statusLabelAr;
  final double unitPrice;
  final double totalPrice;
  final double customerTotalPrice;
  final String amountFormatted;
  final String currency;
  final String customerTotalPriceFormatted;
  final double chargedGrandTotalAed;
  final String chargedGrandTotalFormatted;

  double get displayTotalPrice {
    // Prefer checkout snapshot fields; never invent from a drifted customerTotal alone.
    if (chargedGrandTotalAed > 0) return chargedGrandTotalAed;
    if (totalPrice > 0) return totalPrice;
    if (customerTotalPrice > 0) return customerTotalPrice;
    return totalPrice;
  }

  final double quantity;
  final int paymentMethod;
  final String paymentMethodName;
  final String createdAt;
  final bool isApproved;
  final String? notes;
  final List<String> videoPaths;
  final List<MyOrderImageModel> images;
  final int? portId;
  final String? portName;
  final String? refundedAtUtc;
  final bool isRefunded;
  final String? returnReason;
  final List<String> returnMediaPaths;
  final String? returnRequestedAtUtc;
  final String? returnAdminResponse;
  final String? returnRespondedAtUtc;
  final List<MyOrderStatusHistoryModel> statusHistory;

  bool get isRetail {
    final type = productTypeNameEn.trim().isNotEmpty
        ? productTypeNameEn.trim().toLowerCase()
        : productTypeName.trim().toLowerCase();
    return type == 'retail' || type.contains('تجز');
  }

  bool get canRequestReturn =>
      isRetail &&
      (statusId == 5 || statusId == 7) &&
      (returnReason == null || returnReason!.trim().isEmpty);

  String localizedProductName({required bool isArabic}) =>
      _pickLocalized(
        isArabic: isArabic,
        en: productNameEn,
        ar: productNameAr,
        fallback: productName,
      );

  String localizedProductDescription({required bool isArabic}) =>
      _pickLocalized(
        isArabic: isArabic,
        en: productDescriptionEn,
        ar: productDescriptionAr,
        fallback: productDescription,
      );

  String localizedProductTypeName({required bool isArabic}) =>
      _pickLocalized(
        isArabic: isArabic,
        en: productTypeNameEn,
        ar: productTypeNameAr,
        fallback: productTypeName,
      );

  String localizedCategoryName({required bool isArabic}) =>
      _pickLocalized(
        isArabic: isArabic,
        en: categoryNameEn,
        ar: categoryNameAr,
        fallback: categoryName,
      );

  String localizedUnitName({required bool isArabic}) =>
      _pickLocalized(
        isArabic: isArabic,
        en: unitNameEn,
        ar: unitNameAr,
        fallback: unitName,
      );

  static String _pickLocalized({
    required bool isArabic,
    required String en,
    required String ar,
    required String fallback,
  }) {
    final preferred = isArabic ? ar.trim() : en.trim();
    if (preferred.isNotEmpty) return preferred;
    final secondary = isArabic ? en.trim() : ar.trim();
    if (secondary.isNotEmpty) return secondary;
    return fallback.trim();
  }

  factory MyOrderModel.fromJson(Map<String, dynamic> json) {
    final rawImages = json['images'] as List<dynamic>? ??
        json['Images'] as List<dynamic>? ??
        const [];
    final rawVideos = json['videoPaths'] as List<dynamic>? ??
        json['VideoPaths'] as List<dynamic>? ??
        const [];
    // Product gallery images when order has no attached images.
    final rawProductImages = json['productImagePaths'] as List<dynamic>? ??
        json['ProductImagePaths'] as List<dynamic>? ??
        const [];
    final productImageFallback = rawProductImages
        .map((e) => e.toString().trim())
        .where((e) => e.isNotEmpty)
        .toList();

    final primaryFromJson = json['primaryImagePath']?.toString() ??
        json['PrimaryImagePath']?.toString();
    final resolvedPrimary = (primaryFromJson != null &&
            primaryFromJson.trim().isNotEmpty)
        ? primaryFromJson
        : (productImageFallback.isNotEmpty ? productImageFallback.first : null);
    final rawReturnMedia =
        json['returnMediaPaths'] as List<dynamic>? ??
        json['ReturnMediaPaths'] as List<dynamic>? ??
        const [];
    final rawHistory =
        json['statusHistory'] as List<dynamic>? ??
        json['StatusHistory'] as List<dynamic>? ??
        const [];

    final nameEn = LocalizedProductText.pickEn(
      json: json,
      enKeys: const [
        'productNameEn',
        'ProductNameEn',
        'nameEn',
        'NameEn',
        'productName',
        'ProductName',
      ],
    );
    final nameAr = _pickAr(
      json,
      const [
        'productNameAr',
        'ProductNameAr',
        'nameAr',
        'NameAr',
      ],
    );
    final descriptionEn = LocalizedProductText.pickEn(
      json: json,
      enKeys: const [
        'productDescriptionEn',
        'ProductDescriptionEn',
        'descriptionEn',
        'DescriptionEn',
        'productDescription',
        'ProductDescription',
      ],
    );
    final descriptionAr = _pickAr(
      json,
      const [
        'productDescriptionAr',
        'ProductDescriptionAr',
        'descriptionAr',
        'DescriptionAr',
      ],
    );
    final typeEn = LocalizedProductText.pickEn(
      json: json,
      enKeys: const [
        'productTypeNameEn',
        'ProductTypeNameEn',
        'productTypeName',
        'ProductTypeName',
      ],
    );
    final typeAr = _pickAr(
      json,
      const [
        'productTypeNameAr',
        'ProductTypeNameAr',
      ],
    );
    final categoryEn = LocalizedProductText.pickEn(
      json: json,
      enKeys: const [
        'categoryNameEn',
        'CategoryNameEn',
        'categoryName',
        'CategoryName',
      ],
    );
    final categoryAr = _pickAr(
      json,
      const [
        'categoryNameAr',
        'CategoryNameAr',
      ],
    );
    final unitEn = LocalizedProductText.pickEn(
      json: json,
      enKeys: const [
        'unitNameEn',
        'UnitNameEn',
        'unitName',
        'UnitName',
      ],
    );
    final unitAr = _pickAr(
      json,
      const [
        'unitNameAr',
        'UnitNameAr',
      ],
    );

    final namePair = _splitEnAr(nameEn, nameAr);
    final descriptionPair = _splitEnAr(descriptionEn, descriptionAr);

    return MyOrderModel(
      id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
      productId: json['productId']?.toString() ?? '',
      customerName: json['customerName']?.toString() ?? '',
      customerEmail: json['customerEmail']?.toString() ?? '',
      customerPhone: json['customerPhone']?.toString() ?? '',
      supplierName: json['supplierName']?.toString() ?? '',
      supplierEmail: json['supplierEmail']?.toString() ?? '',
      supplierPhone: json['supplierPhone']?.toString() ?? '',
      productName: LocalizedProductText.pickName(json)
          .ifEmpty(namePair.en)
          .ifEmpty(namePair.ar),
      productNameEn: namePair.en,
      productNameAr: namePair.ar,
      productDescription: LocalizedProductText.pickDescription(json)
          .ifEmpty(descriptionPair.en)
          .ifEmpty(descriptionPair.ar),
      productDescriptionEn: descriptionPair.en,
      productDescriptionAr: descriptionPair.ar,
      productTypeName: LocalizedProductText.pickProductType(json)
          .ifEmpty(typeEn)
          .ifEmpty(typeAr),
      productTypeNameEn: typeEn,
      productTypeNameAr: typeAr,
      categoryName: LocalizedProductText.pickCategory(json)
          .ifEmpty(categoryEn)
          .ifEmpty(categoryAr),
      categoryNameEn: categoryEn,
      categoryNameAr: categoryAr,
      categoryId: int.tryParse(
        (json['categoryId'] ?? json['CategoryId'])?.toString() ?? '',
      ),
      primaryImagePath: resolvedPrimary,
      unitName: LocalizedProductText.pickUnit(json)
          .ifEmpty(unitEn)
          .ifEmpty(unitAr),
      unitNameEn: unitEn,
      unitNameAr: unitAr,
      statusId: int.tryParse(json['statusId']?.toString() ?? '') ?? 0,
      statusName: json['statusName']?.toString() ?? '',
      statusLabelAr: json['statusLabelAr']?.toString() ?? '',
      unitPrice: _toDouble(json['unitPrice']),
      totalPrice: _toDouble(json['totalPrice']),
      customerTotalPrice: _toDouble(
        json['customerTotalPrice'] ?? json['CustomerTotalPrice'],
      ),
      amountFormatted: json['amountFormatted']?.toString() ?? '',
      currency: _parseCurrency(json),
      customerTotalPriceFormatted:
          json['customerTotalPriceFormatted']?.toString() ??
          json['CustomerTotalPriceFormatted']?.toString() ??
          '',
      chargedGrandTotalAed: _toDouble(
        json['chargedGrandTotalAed'] ?? json['ChargedGrandTotalAed'],
      ),
      chargedGrandTotalFormatted:
          json['chargedGrandTotalFormatted']?.toString() ??
          json['ChargedGrandTotalFormatted']?.toString() ??
          '',
      quantity: _toDouble(json['quantity'] ?? json['Quantity']),
      paymentMethod: int.tryParse(json['paymentMethod']?.toString() ?? '') ?? 0,
      paymentMethodName: json['paymentMethodName']?.toString() ?? '',
      createdAt: json['createdAt']?.toString() ?? '',
      isApproved: json['isApproved'] == true,
      notes: json['notes']?.toString(),
      videoPaths: rawVideos.map((e) => e.toString()).toList(),
      images: rawImages
          .whereType<Map<String, dynamic>>()
          .map(MyOrderImageModel.fromJson)
          .toList(),
      portId: int.tryParse(json['portId']?.toString() ?? ''),
      portName: json['portName']?.toString(),
      refundedAtUtc: json['refundedAtUtc']?.toString() ??
          json['RefundedAtUtc']?.toString(),
      isRefunded:
          json['isRefunded'] == true || json['IsRefunded'] == true,
      returnReason: json['returnReason']?.toString() ??
          json['ReturnReason']?.toString(),
      returnMediaPaths: rawReturnMedia.map((e) => e.toString()).toList(),
      returnRequestedAtUtc: json['returnRequestedAtUtc']?.toString() ??
          json['ReturnRequestedAtUtc']?.toString(),
      returnAdminResponse: json['returnAdminResponse']?.toString() ??
          json['ReturnAdminResponse']?.toString(),
      returnRespondedAtUtc: json['returnRespondedAtUtc']?.toString() ??
          json['ReturnRespondedAtUtc']?.toString(),
      statusHistory: rawHistory
          .whereType<Map<String, dynamic>>()
          .map(MyOrderStatusHistoryModel.fromJson)
          .toList(),
    );
  }

  static String _pickAr(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key]?.toString().trim();
      if (value != null && value.isNotEmpty) return value;
    }
    return '';
  }

  /// When legacy APIs store Arabic in *En fields, move it to Ar.
  static ({String en, String ar}) _splitEnAr(String en, String ar) {
    final enTrim = en.trim();
    final arTrim = ar.trim();
    if (arTrim.isEmpty && _hasArabic(enTrim)) {
      return (en: '', ar: enTrim);
    }
    if (enTrim.isNotEmpty && _hasArabic(enTrim) && arTrim.isNotEmpty) {
      return (en: '', ar: arTrim);
    }
    return (en: enTrim, ar: arTrim);
  }

  static bool _hasArabic(String text) {
    for (final code in text.runes) {
      if (code >= 0x0600 && code <= 0x06FF) return true;
    }
    return false;
  }

  String? get resolvedPrimaryImageUrl {
    final path = primaryImagePath?.trim();
    if (path != null && path.isNotEmpty && _isImagePath(path)) {
      return _resolveAssetUrl(path);
    }
    for (final image in images) {
      final imagePath = image.path.trim();
      if (imagePath.isNotEmpty && _isImagePath(imagePath)) {
        return _resolveAssetUrl(imagePath);
      }
    }
    return null;
  }

  String? get resolvedPrimaryVideoUrl {
    for (final path in videoPaths) {
      final trimmed = path.trim();
      if (trimmed.isEmpty) continue;
      return _resolveAssetUrl(trimmed);
    }
    // Some payloads put the product video in primaryImagePath by mistake.
    final primary = primaryImagePath?.trim();
    if (primary != null && primary.isNotEmpty && _isVideoPath(primary)) {
      return _resolveAssetUrl(primary);
    }
    return null;
  }

  String statusLabel({required bool isArabic}) =>
      isArabic && statusLabelAr.trim().isNotEmpty
          ? statusLabelAr.trim()
          : statusName.trim();

  static String _parseCurrency(Map<String, dynamic> json) {
    return (json['currency'] ?? json['Currency'])?.toString().trim() ?? '';
  }

  static double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  static bool _isVideoPath(String path) {
    final lower = path.toLowerCase();
    return lower.endsWith('.mp4') ||
        lower.endsWith('.mov') ||
        lower.endsWith('.webm') ||
        lower.endsWith('.m4v') ||
        lower.endsWith('.avi') ||
        lower.endsWith('.mkv') ||
        lower.contains('/product-videos/') ||
        lower.contains('/order-videos/');
  }

  static bool _isImagePath(String path) => !_isVideoPath(path);

  static String? _resolveAssetUrl(String path) {
    final url = ApiConstants.resolveMediaUrl(path);
    return url.isEmpty ? null : url;
  }
}

extension on String {
  String ifEmpty(String fallback) => trim().isEmpty ? fallback : this;
}

class MyOrderStatusHistoryModel {
  const MyOrderStatusHistoryModel({
    required this.id,
    required this.statusId,
    required this.statusNameEn,
    required this.statusNameAr,
    required this.createdAtUtc,
  });

  final int id;
  final int statusId;
  final String statusNameEn;
  final String statusNameAr;
  final String createdAtUtc;

  factory MyOrderStatusHistoryModel.fromJson(Map<String, dynamic> json) {
    return MyOrderStatusHistoryModel(
      id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
      statusId: int.tryParse(json['statusId']?.toString() ?? '') ?? 0,
      statusNameEn: json['statusNameEn']?.toString() ??
          json['StatusNameEn']?.toString() ??
          '',
      statusNameAr: json['statusNameAr']?.toString() ??
          json['StatusNameAr']?.toString() ??
          '',
      createdAtUtc: json['createdAtUtc']?.toString() ??
          json['CreatedAtUtc']?.toString() ??
          '',
    );
  }

  String label({required bool isArabic}) =>
      isArabic && statusNameAr.trim().isNotEmpty
          ? statusNameAr.trim()
          : statusNameEn.trim();
}
