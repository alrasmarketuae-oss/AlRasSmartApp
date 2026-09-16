import 'package:alrasmarket/core/services/api_constants.dart';
import 'package:alrasmarket/core/utils/localized_product_text.dart';
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
    this.productTypeNameAr = '',
    required this.quantity,
    required this.unitName,
    this.unitNameEn = '',
    this.unitNameAr = '',
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
    this.portNameEn = '',
    this.portNameAr = '',
    this.destinationCountryName = '',
    this.destinationCountryNameEn = '',
    this.destinationCountryNameAr = '',
    required this.notes,
    this.notesEn = '',
    this.notesAr = '',
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
  final String productTypeNameAr;
  final double quantity;
  final String unitName;
  final String unitNameEn;
  final String unitNameAr;
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
  final String portNameEn;
  final String portNameAr;
  final String destinationCountryName;
  final String destinationCountryNameEn;
  final String destinationCountryNameAr;
  final String notes;
  final String notesEn;
  final String notesAr;
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

  String localizedNotes({required bool isArabic}) => _pickLocalized(
        isArabic: isArabic,
        en: notesEn,
        ar: notesAr,
        fallback: notes,
      );

  /// Ad specs for the card: localized product description, else offer notes.
  String localizedSpecifications({required bool isArabic}) {
    final description = localizedProductDescription(isArabic: isArabic).trim();
    if (description.isNotEmpty) return description;
    return localizedNotes(isArabic: isArabic).trim();
  }

  String localizedUnitName({required bool isArabic}) => _pickLocalized(
        isArabic: isArabic,
        en: unitNameEn,
        ar: unitNameAr,
        fallback: unitName,
      );

  String localizedPortName({required bool isArabic}) => _pickLocalized(
        isArabic: isArabic,
        en: portNameEn,
        ar: portNameAr,
        fallback: portName,
      );

  String localizedDestinationCountry({required bool isArabic}) => _pickLocalized(
        isArabic: isArabic,
        en: destinationCountryNameEn,
        ar: destinationCountryNameAr,
        fallback: destinationCountryName,
      );

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
    final rawImages = json['imagePaths'] as List<dynamic>? ??
        json['ImagePaths'] as List<dynamic>? ??
        const [];
    final rawDocs = json['documentPaths'] as List<dynamic>? ??
        json['DocumentPaths'] as List<dynamic>? ??
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
    final nameAr = _read(json, const [
          'productNameAr',
          'ProductNameAr',
          'nameAr',
          'NameAr',
        ]) ??
        '';
    final namePair = _splitEnAr(nameEn, nameAr);

    final descriptionEn = LocalizedProductText.pickEn(
      json: json,
      enKeys: const [
        'productDescriptionEn',
        'ProductDescriptionEn',
        'descriptionEn',
        'DescriptionEn',
        'productDescription',
        'ProductDescription',
        'description',
        'Description',
      ],
    );
    final descriptionAr = _read(json, const [
          'productDescriptionAr',
          'ProductDescriptionAr',
          'descriptionAr',
          'DescriptionAr',
        ]) ??
        '';
    final descriptionPair = _splitEnAr(descriptionEn, descriptionAr);

    final unitEn = LocalizedProductText.pickEn(
      json: json,
      enKeys: const [
        'unitNameEn',
        'UnitNameEn',
        'unitName',
        'UnitName',
      ],
    );
    final unitAr = _read(json, const [
          'unitNameAr',
          'UnitNameAr',
        ]) ??
        '';
    final unitPair = _splitEnAr(unitEn, unitAr);

    final portEn = LocalizedProductText.pickEn(
      json: json,
      enKeys: const [
        'portNameEn',
        'PortNameEn',
        'portName',
        'PortName',
      ],
    );
    final portAr = _read(json, const [
          'portNameAr',
          'PortNameAr',
        ]) ??
        '';
    final portPair = _splitEnAr(portEn, portAr);

    final countryEn = LocalizedProductText.pickEn(
      json: json,
      enKeys: const [
        'destinationCountryNameEn',
        'DestinationCountryNameEn',
        'destinationCountryName',
        'DestinationCountryName',
      ],
    );
    final countryAr = _read(json, const [
          'destinationCountryNameAr',
          'DestinationCountryNameAr',
        ]) ??
        '';
    final countryPair = _splitEnAr(countryEn, countryAr);

    final notesEn = LocalizedProductText.pickEn(
      json: json,
      enKeys: const [
        'notesEn',
        'NotesEn',
        'notes',
        'Notes',
      ],
    );
    final notesAr = _read(json, const [
          'notesAr',
          'NotesAr',
        ]) ??
        '';
    final notesPair = _splitEnAr(notesEn, notesAr);

    final typeEn = (json['productTypeNameEn'] ??
                json['ProductTypeNameEn'] ??
                json['productTypeName'] ??
                json['ProductTypeName'])
            ?.toString()
            .trim() ??
        '';
    final typeAr = _read(json, const [
          'productTypeNameAr',
          'ProductTypeNameAr',
        ]) ??
        '';

    return MyRequestOfferModel(
      orderId: int.tryParse(json['orderId']?.toString() ??
              json['OrderId']?.toString() ??
              '') ??
          0,
      productId: json['productId']?.toString() ??
          json['ProductId']?.toString() ??
          '',
      productName: LocalizedProductText.pickName(json).isNotEmpty
          ? LocalizedProductText.pickName(json)
          : (namePair.en.isNotEmpty ? namePair.en : namePair.ar),
      productNameEn: namePair.en,
      productNameAr: namePair.ar,
      productDescription: LocalizedProductText.pickDescription(json).isNotEmpty
          ? LocalizedProductText.pickDescription(json)
          : (descriptionPair.en.isNotEmpty
              ? descriptionPair.en
              : descriptionPair.ar),
      productDescriptionEn: descriptionPair.en,
      productDescriptionAr: descriptionPair.ar,
      productTypeId: int.tryParse(
            (json['productTypeId'] ?? json['ProductTypeId'])?.toString() ?? '',
          ) ??
          0,
      productTypeNameEn: typeEn,
      productTypeNameAr: typeAr,
      quantity: _toDouble(json['quantity'] ?? json['Quantity']),
      unitName: LocalizedProductText.pickUnit(json).isNotEmpty
          ? LocalizedProductText.pickUnit(json)
          : (unitPair.en.isNotEmpty ? unitPair.en : unitPair.ar),
      unitNameEn: unitPair.en,
      unitNameAr: unitPair.ar,
      unitPrice: _toDouble(json['unitPrice'] ?? json['UnitPrice']),
      totalPrice: _toDouble(json['totalPrice'] ?? json['TotalPrice']),
      currency: json['currency']?.toString() ??
          json['Currency']?.toString() ??
          '',
      unitPriceFormatted: json['unitPriceFormatted']?.toString() ??
          json['UnitPriceFormatted']?.toString() ??
          '',
      totalPriceFormatted: json['totalPriceFormatted']?.toString() ??
          json['TotalPriceFormatted']?.toString() ??
          '',
      statusId: int.tryParse(json['statusId']?.toString() ??
              json['StatusId']?.toString() ??
              '') ??
          0,
      statusName: json['statusName']?.toString() ??
          json['StatusName']?.toString() ??
          '',
      statusAr: json['statusAr']?.toString() ??
          json['StatusAr']?.toString() ??
          '',
      isApproved: json['isApproved'] == true || json['IsApproved'] == true,
      isAdminApproved:
          json['isAdminApproved'] == true || json['IsAdminApproved'] == true,
      canAccept: json['canAccept'] == true || json['CanAccept'] == true,
      canReject: json['canReject'] == true || json['CanReject'] == true,
      createdAt: json['createdAt']?.toString() ??
          json['CreatedAt']?.toString() ??
          '',
      portName: portPair.en.isNotEmpty ? portPair.en : portPair.ar,
      portNameEn: portPair.en,
      portNameAr: portPair.ar,
      destinationCountryName:
          countryPair.en.isNotEmpty ? countryPair.en : countryPair.ar,
      destinationCountryNameEn: countryPair.en,
      destinationCountryNameAr: countryPair.ar,
      notes: notesPair.en.isNotEmpty ? notesPair.en : notesPair.ar,
      notesEn: notesPair.en,
      notesAr: notesPair.ar,
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

  static double _toDouble(dynamic value) =>
      ThousandsNumberInput.parseDoubleOrZero(value);

  static String? resolveAssetUrl(String path) {
    final url = ApiConstants.resolveMediaUrl(path);
    return url.isEmpty ? null : url;
  }
}
