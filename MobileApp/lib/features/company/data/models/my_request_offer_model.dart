import 'package:alrasmarket/core/services/api_constants.dart';

class MyRequestOfferModel {
  const MyRequestOfferModel({
    required this.orderId,
    required this.productId,
    required this.productName,
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
    return isArabic ? '—' : '—';
  }

  String? get primaryImageUrl {
    if (imagePaths.isEmpty) return null;
    return resolveAssetUrl(imagePaths.first);
  }

  factory MyRequestOfferModel.fromJson(Map<String, dynamic> json) {
    final rawImages = json['imagePaths'] as List<dynamic>? ?? const [];
    final rawDocs = json['documentPaths'] as List<dynamic>? ?? const [];

    return MyRequestOfferModel(
      orderId: int.tryParse(json['orderId']?.toString() ?? '') ?? 0,
      productId: json['productId']?.toString() ?? '',
      productName: json['productName']?.toString() ?? '',
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

  static double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  static String? resolveAssetUrl(String path) {
    final url = ApiConstants.resolveMediaUrl(path);
    return url.isEmpty ? null : url;
  }
}
