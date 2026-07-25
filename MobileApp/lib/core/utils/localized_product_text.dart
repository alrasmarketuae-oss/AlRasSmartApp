import 'package:alrasmarket/core/helper/cach_helper.dart';

/// Picks Arabic/English API fields based on the app's saved locale.
class LocalizedProductText {
  LocalizedProductText._();

  static bool get isArabic {
    final raw = CachHelper.getData('languageCode')?.toString() ??
        CachHelper.getData('locale')?.toString() ??
        '';
    return raw.trim().toLowerCase().startsWith('ar');
  }

  static String pick({
    required Map<String, dynamic> json,
    required List<String> arKeys,
    required List<String> enKeys,
    List<String> fallbackKeys = const [],
  }) {
    final preferred = isArabic ? arKeys : enKeys;
    final secondary = isArabic ? enKeys : arKeys;
    for (final key in [...preferred, ...secondary, ...fallbackKeys]) {
      final value = json[key]?.toString().trim();
      if (value != null && value.isNotEmpty) return value;
    }
    return '';
  }

  /// Always picks English keys first (for edit forms / API submit values).
  static String pickEn({
    required Map<String, dynamic> json,
    required List<String> enKeys,
  }) {
    for (final key in enKeys) {
      final value = json[key]?.toString().trim();
      if (value != null && value.isNotEmpty) return value;
    }
    return '';
  }

  /// Picks Arabic/English using [language] (`ar`/`en`) instead of the app locale.
  /// Falls back to [pick] (app locale) when [language] is null/empty.
  static String pickForLanguage({
    required Map<String, dynamic> json,
    required String? language,
    required List<String> arKeys,
    required List<String> enKeys,
    List<String> fallbackKeys = const [],
  }) {
    final normalized = language?.trim().toLowerCase() ?? '';
    if (normalized.isEmpty) {
      return pick(
        json: json,
        arKeys: arKeys,
        enKeys: enKeys,
        fallbackKeys: fallbackKeys,
      );
    }

    final preferAr = normalized.startsWith('ar');
    final preferred = preferAr ? arKeys : enKeys;
    final secondary = preferAr ? enKeys : arKeys;
    for (final key in [...preferred, ...secondary, ...fallbackKeys]) {
      final value = json[key]?.toString().trim();
      if (value != null && value.isNotEmpty) return value;
    }
    return '';
  }

  static String? createdLanguageOf(Map<String, dynamic> json) {
    final raw = (json['createdLanguage'] ??
            json['CreatedLanguage'] ??
            json['sourceLanguage'] ??
            json['SourceLanguage'])
        ?.toString()
        .trim()
        .toLowerCase();
    if (raw == null || raw.isEmpty) return null;
    return raw.startsWith('ar') ? 'ar' : 'en';
  }

  static String pickName(Map<String, dynamic> json) {
    final created = createdLanguageOf(json);
    if (created != null) {
      // API already localized ProductName to CreatedLanguage — prefer it.
      final display = (json['productName'] ?? json['ProductName'])
          ?.toString()
          .trim();
      if (display != null && display.isNotEmpty) return display;
      return pickForLanguage(
        json: json,
        language: created,
        arKeys: const [
          'nameAr',
          'NameAr',
          'productNameAr',
          'ProductNameAr',
        ],
        enKeys: const [
          'nameEn',
          'NameEn',
          'productNameEn',
          'ProductNameEn',
          'name',
          'Name',
        ],
        fallbackKeys: const ['NameEn'],
      );
    }
    return pick(
        json: json,
        arKeys: const [
          'nameAr',
          'NameAr',
          'productNameAr',
          'ProductNameAr',
        ],
        enKeys: const [
          'nameEn',
          'NameEn',
          'productNameEn',
          'ProductNameEn',
          'productName',
          'ProductName',
          'name',
          'Name',
        ],
        fallbackKeys: const ['NameEn'],
      );
  }

  static String pickDescription(Map<String, dynamic> json) {
    final created = createdLanguageOf(json);
    if (created != null) {
      final display = (json['description'] ?? json['Description'])
          ?.toString()
          .trim();
      if (display != null && display.isNotEmpty) return display;
      return pickForLanguage(
        json: json,
        language: created,
        arKeys: const [
          'descriptionAr',
          'DescriptionAr',
          'productDescriptionAr',
          'ProductDescriptionAr',
          'wholesaleDescriptionAr',
          'retailDescriptionAr',
        ],
        enKeys: const [
          'descriptionEn',
          'DescriptionEn',
          'productDescriptionEn',
          'ProductDescriptionEn',
          'description',
          'productDescription',
          'ProductDescription',
          'wholesaleDescriptionEn',
          'wholesaleDescription',
          'retailDescriptionEn',
          'retailDescription',
        ],
      );
    }
    return pick(
        json: json,
        arKeys: const [
          'descriptionAr',
          'DescriptionAr',
          'productDescriptionAr',
          'ProductDescriptionAr',
          'wholesaleDescriptionAr',
          'retailDescriptionAr',
        ],
        enKeys: const [
          'descriptionEn',
          'DescriptionEn',
          'productDescriptionEn',
          'ProductDescriptionEn',
          'description',
          'productDescription',
          'ProductDescription',
          'wholesaleDescriptionEn',
          'wholesaleDescription',
          'retailDescriptionEn',
          'retailDescription',
        ],
      );
  }

  static String pickSupplierNotes(Map<String, dynamic> json) => pick(
        json: json,
        arKeys: const ['supplierNotesAr', 'SupplierNotesAr'],
        enKeys: const [
          'supplierNotesEn',
          'SupplierNotesEn',
          'supplierNotes',
          'SupplierNotes',
        ],
      );

  static String pickShippingDescription(Map<String, dynamic> json) => pick(
        json: json,
        arKeys: const [
          'shippingDescriptionAr',
          'ShippingDescriptionAr',
        ],
        enKeys: const [
          'shippingDescriptionEn',
          'ShippingDescriptionEn',
          'shippingDescription',
          'additionalShippingNotes',
        ],
      );

  static String pickCountry({
    required String? nameEn,
    required String? nameAr,
    String? fallback,
  }) =>
      pickPair(ar: nameAr, en: nameEn, fallback: fallback);

  /// Ports: always prefer English until Arabic port names are complete in the catalog.
  static String pickPort({
    required String? nameEn,
    required String? nameAr,
    String? fallback,
  }) {
    for (final value in [nameEn, fallback, nameAr]) {
      final trimmed = value?.toString().trim();
      if (trimmed != null && trimmed.isNotEmpty) return trimmed;
    }
    return '';
  }

  static String pickPair({
    String? ar,
    String? en,
    String? fallback,
  }) {
    final preferred = isArabic ? ar : en;
    final secondary = isArabic ? en : ar;
    for (final value in [preferred, secondary, fallback]) {
      final trimmed = value?.toString().trim();
      if (trimmed != null && trimmed.isNotEmpty) return trimmed;
    }
    return '';
  }

  static String pickOriginCountry(Map<String, dynamic> json) => pick(
        json: json,
        arKeys: const [
          'originCountryNameAr',
          'OriginCountryNameAr',
          'routeFromCountryAr',
        ],
        enKeys: const [
          'originCountryNameEn',
          'OriginCountryNameEn',
          'originCountryName',
          'routeFromCountry',
        ],
      );

  static String pickDestinationCountry(Map<String, dynamic> json) => pick(
        json: json,
        arKeys: const [
          'destinationCountryNameAr',
          'DestinationCountryNameAr',
          'routeToCountryAr',
        ],
        enKeys: const [
          'destinationCountryNameEn',
          'DestinationCountryNameEn',
          'destinationCountryName',
          'routeToCountry',
        ],
      );

  /// Always English — Arabic port catalog is incomplete.
  static String pickLoadingPort(Map<String, dynamic> json) => pickEn(
        json: json,
        enKeys: const [
          'loadingPortNameEn',
          'LoadingPortNameEn',
          'routeFromPortEn',
          'routeFromPort',
          'loadingPortName',
          'LoadingPortName',
        ],
      );

  /// Always English — Arabic port catalog is incomplete.
  static String pickArrivalPort(Map<String, dynamic> json) => pickEn(
        json: json,
        enKeys: const [
          'arrivalPortNameEn',
          'ArrivalPortNameEn',
          'routeToPortEn',
          'routeToPort',
          'arrivalPortName',
          'ArrivalPortName',
        ],
      );

  static String pickCategory(Map<String, dynamic> json) => pick(
        json: json,
        arKeys: const ['categoryNameAr', 'CategoryNameAr'],
        enKeys: const [
          'categoryNameEn',
          'CategoryNameEn',
          'categoryName',
          'CategoryName',
        ],
      );

  static String pickUnit(Map<String, dynamic> json) => pick(
        json: json,
        arKeys: const ['unitNameAr', 'UnitNameAr'],
        enKeys: const [
          'unitNameEn',
          'UnitNameEn',
          'unitName',
          'UnitName',
        ],
      );

  static String pickRetailUnit(Map<String, dynamic> json) => pick(
        json: json,
        arKeys: const ['retailUnitNameAr', 'RetailUnitNameAr'],
        enKeys: const [
          'retailUnitNameEn',
          'RetailUnitNameEn',
          'retailUnitName',
          'RetailUnitName',
        ],
      );

  static String pickStatus(Map<String, dynamic> json) => pick(
        json: json,
        arKeys: const [
          'statusNameAr',
          'StatusNameAr',
          'statusAr',
          'StatusAr',
        ],
        enKeys: const [
          'statusNameEn',
          'StatusNameEn',
          'statusName',
          'StatusName',
          'status',
          'Status',
        ],
      );

  static String pickApprovalStatus(Map<String, dynamic> json) => pick(
        json: json,
        arKeys: const [
          'approvalStatusAr',
          'ApprovalStatusAr',
        ],
        enKeys: const [
          'approvalStatusEn',
          'ApprovalStatusEn',
          'approvalStatus',
          'ApprovalStatus',
        ],
      );

  static String pickProductType(Map<String, dynamic> json) => pick(
        json: json,
        arKeys: const [
          'productTypeNameAr',
          'ProductTypeNameAr',
        ],
        enKeys: const [
          'productTypeNameEn',
          'ProductTypeNameEn',
          'productTypeName',
          'ProductTypeName',
          'productType',
        ],
      );

  static String pickRequestType(Map<String, dynamic> json) => pick(
        json: json,
        arKeys: const [
          'requestTypeNameAr',
          'RequestTypeNameAr',
        ],
        enKeys: const [
          'requestTypeNameEn',
          'RequestTypeNameEn',
          'requestTypeName',
          'RequestTypeName',
        ],
      );
}
