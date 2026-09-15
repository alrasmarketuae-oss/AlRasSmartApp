import 'package:alrasmarket/core/services/api_constants.dart';
import 'package:alrasmarket/core/utils/thousands_separator_input_formatter.dart';

class MyRequestOfferModel {
  const MyRequestOfferModel({
    required this.orderId,
    required this.productId,
    required this.productName,
    this.productNameEn = '',
    this.productNameAr = '',
    this.productDescription = '',
    this.productDescriptionEn = '',
    this.productDescriptionAr = '',
    this.productTypeId = 0,
    this.productTypeNameEn = '',
    required this.quantity,
    required this.unitName,
    required this.unitPrice,
    required this.totalPrice,
    required this.currency,
    required this.unitPriceFormatted,
    required this.totalPriceFormatted,
    required this.statusId,
    required this.statusName,
    this.statusAr = '',
    required this.isApproved,
    this.isAdminApproved = true,
    required this.canAccept,
    required this.canReject,
    required this.createdAt,
    required this.portName,
    this.destinationCountryName = '',
    required this.notes,
    required this.imagePaths,
    required this.documentPaths,
  });

  final int orderId;
  final String productId;
  final String productName;
  final String productNameEn;
  final String productNameAr;
  final String productDescription;
  final String productDescriptionEn;
  final String productDescriptionAr;
  final int productTypeId;
  final String productTypeNameEn;
  final double quantity;
  final String unitName;
  final double unitPrice;
  final double totalPrice;
  final String currency;
  final String unitPriceFormatted;
  final String totalPriceFormatted;
  final int statusId;
  final String statusName;
  final String statusAr;
  final bool isApproved;
  final bool isAdminApproved;
  final bool canAccept;
  final bool canReject;
  final String createdAt;
  final String portName;
  final String destinationCountryName;
  final String notes;
  final List<String> imagePaths;
  final List<String> documentPaths;

  /// Offers on Requests ads use "Accept Offer"; other ads use "Accept Order".
  bool get isRequestProductOffer {
    if (productTypeId == 4) return true;
    final type = productTypeNameEn.trim().toLowerCase();
    return type == 'requests' || type.contains('request');
  }

  String get displayTotalPrice =>
      totalPriceFormatted.isNotEmpty ? totalPriceFormatted : totalPrice.toString();

  String get displayUnitPrice =>
      unitPriceFormatted.isNotEmpty ? unitPriceFormatted : unitPrice.toString();

  String statusLabel({required bool isArabic}) {
    if (isArabic) {
      final ar = statusAr.trim();
      if (ar.isNotEmpty) return ar;
    }
    final en = statusName.trim();
    if (en.isNotEmpty) return en;
    return '—';
  }

  String localizedProductName({required bool isArabic}) => _pickLocalized(
        isArabic: isArabic,
        en: productNameEn,
        ar: productNameAr,
        fallback: productName,
      );

  String localizedProductDescription({required bool isArabic}) => _pickLocalized(
        isArabic: isArabic,
        en: productDescriptionEn,
        ar: productDescriptionAr,
        fallback: productDescription,
      );

  /// Ad specs for the card: localized product description, else offer notes.
  String localizedSpecifications({required bool isArabic}) {
    final description = localizedProductDescription(isArabic: isArabic).trim();
    if (description.isNotEmpty) return description;
    return notes.trim();
  }

  static String _pickLocalized({
    required bool isArabic,
    required String en,
    required String ar,
    required String fallback,
  }) {
    final preferred = (isArabic ? ar : en).trim();
    if (preferred.isNotEmpty) return preferred;
    final secondary = (isArabic ? en : ar).trim();
    if (secondary.isNotEmpty) return secondary;
    return fallback.trim();
  }

  String? get primaryImageUrl {
    if (imagePaths.isEmpty) return null;
    return resolveAssetUrl(imagePaths.first);
  }

  factory MyRequestOfferModel.fromJson(Map<String, dynamic> json) {
    final rawImages = json['imagePaths'] as List<dynamic>? ?? const [];
    final rawDocs = json['documentPaths'] as List<dynamic>? ?? const [];

    final productName = _read(json, const [
          'productName',
          'ProductName',
        ]) ??
        '';
    final productNameEn = _read(json, const [
          'productNameEn',
          'ProductNameEn',
          'nameEn',
          'NameEn',
        ]) ??
        '';
    final productNameAr = _read(json, const [
          'productNameAr',
          'ProductNameAr',
          'nameAr',
          'NameAr',
        ]) ??
        '';
    final productDescription = _read(json, const [
          'productDescription',
          'ProductDescription',
          'description',
          'Description',
        ]) ??
        '';
    final productDescriptionEn = _read(json, const [
          'productDescriptionEn',
          'ProductDescriptionEn',
          'descriptionEn',
          'DescriptionEn',
        ]) ??
        '';
    final productDescriptionAr = _read(json, const [
          'productDescriptionAr',
          'ProductDescriptionAr',
          'descriptionAr',
          'DescriptionAr',
        ]) ??
        '';

    return MyRequestOfferModel(
      orderId: int.tryParse(json['orderId']?.toString() ?? '') ?? 0,
      productId: json['productId']?.toString() ?? '',
      productName: productName,
      productNameEn: productNameEn,
      productNameAr: productNameAr,
      productDescription: productDescription,
      productDescriptionEn: productDescriptionEn,
      productDescriptionAr: productDescriptionAr,
      productTypeId: int.tryParse(
            (json['productTypeId'] ?? json['ProductTypeId'])?.toString() ?? '',
          ) ??
          0,
      productTypeNameEn: (json['productTypeNameEn'] ??
                  json['ProductTypeNameEn'] ??
                  json['productTypeName'] ??
                  json['ProductTypeName'])
              ?.toString()
              .trim() ??
          '',
      quantity: _toDouble(json['quantity']),
      unitName: json['unitName']?.toString() ?? '',
      unitPrice: _toDouble(json['unitPrice']),
      totalPrice: _toDouble(json['totalPrice']),
      currency: json['currency']?.toString() ?? '',
      unitPriceFormatted: json['unitPriceFormatted']?.toString() ?? '',
      totalPriceFormatted: json['totalPriceFormatted']?.toString() ?? '',
      statusId: int.tryParse(json['statusId']?.toString() ?? '') ?? 0,
      statusName: json['statusName']?.toString() ??
          json['StatusName']?.toString() ??
          '',
      statusAr: json['statusAr']?.toString() ??
          json['StatusAr']?.toString() ??
          '',
      isApproved: json['isApproved'] == true,
      isAdminApproved:
          json['isAdminApproved'] == true || json['IsAdminApproved'] == true,
      canAccept: json['canAccept'] == true,
      canReject: json['canReject'] == true,
      createdAt: json['createdAt']?.toString() ?? '',
      portName: json['portName']?.toString() ?? '',
      destinationCountryName:
          json['destinationCountryName']?.toString() ?? '',
      notes: json['notes']?.toString() ?? '',
      imagePaths: rawImages.map((e) => e.toString()).toList(),
      documentPaths: rawDocs.map((e) => e.toString()).toList(),
    );
  }

  static String? _read(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key]?.toString().trim();
      if (value != null && value.isNotEmpty) return value;
    }
    return null;
  }

  static double _toDouble(dynamic value) =>
      ThousandsNumberInput.parseDoubleOrZero(value);

  static String? resolveAssetUrl(String path) {
    final url = ApiConstants.resolveMediaUrl(path);
    return url.isEmpty ? null : url;
  }
}
