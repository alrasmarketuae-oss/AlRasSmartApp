import 'package:alrasmarket/core/services/api_constants.dart';
import 'package:alrasmarket/core/utils/localized_product_text.dart';
import 'package:alrasmarket/core/utils/utc_date_time.dart';

import 'my_listing_shipping_model.dart';

class ProductVideoMetadata {
  const ProductVideoMetadata({
    this.id = '',
    required this.path,
    this.durationSeconds,
    this.isMuted = true,
  });

  final String id;
  final String path;
  final int? durationSeconds;
  final bool isMuted;

  Map<String, dynamic> toJson() => {
        if (id.isNotEmpty) 'id': id,
        'path': path,
        'videoPath': path,
        if (durationSeconds != null) 'durationSeconds': durationSeconds,
        'isMuted': isMuted,
      };
}

class MyListingProductModel {
  const MyListingProductModel({
    required this.productId,
    required this.productName,
    this.nameEn = '',
    this.nameAr = '',
    this.createdLanguage = 'en',
    required this.categoryName,
    this.categoryNameEn = '',
    required this.categoryImagePath,
    this.categoryId,
    this.productTypeId,
    required this.productTypeName,
    this.productTypeNameEn = '',
    this.productCode = '',
    required this.description,
    this.descriptionEn = '',
    this.descriptionAr = '',
    required this.priceUsd,
    required this.displayPrice,
    required this.currency,
    required this.quantity,
    required this.unitName,
    this.unitNameEn = '',
    required this.minimumOrderQuantity,
    required this.maximumOrderQuantity,
    required this.status,
    this.statusNameEn = '',
    required this.approvalStatus,
    required this.negotiable,
    required this.isFeatured,
    required this.viewsCount,
    required this.images,
    required this.documents,
    required this.shipping,
    this.discountPercentage = '',
    this.discountDays = '',
    this.offerDuration = '',
    this.supplierNotes = '',
    this.packaging,
    this.packagingDetails = '',
    this.shippingDuration = '',
    this.videoPath = '',
    this.videoPaths = const [],
    this.videos = const [],
    this.videoDurationSeconds = '',
    this.createdAt = '',
    this.updatedAt = '',
    this.ownerId = '',
    this.pendingOffersCount = 0,
    this.hasRetailPricing = false,
    this.searchListingChannel = '',
    this.retailPrice = '',
    this.retailUnitName = '',
    this.retailUnitNameEn = '',
    this.retailQuantity = '',
    this.retailPackaging,
    this.retailPackagingDetails = '',
    this.retailDescription = '',
    this.retailDescriptionEn = '',
    this.retailDescriptionAr = '',
    this.requestTypeId,
    this.requestTypeName = '',
    this.bookingPriceTypeId,
    this.bookingPriceTypeName = '',
    this.bookingPriceTypeNameEn = '',
    this.shippingDescriptionEn = '',
  });

  final String productId;
  final String productName;
  /// Canonical English name from API (`nameEn`) — use for edit submit.
  final String nameEn;
  /// Arabic name from API translations (`nameAr`).
  final String nameAr;
  /// Language the seller used when creating the ad (`en` / `ar`).
  final String createdLanguage;
  final String categoryName;
  final String categoryNameEn;
  final String categoryImagePath;
  final int? categoryId;
  final int? productTypeId;
  final String productTypeName;
  /// Canonical English type from API — use for edit type resolution.
  final String productTypeNameEn;
  final String productCode;

  bool get isRetailProduct =>
      productTypeId == 1 ||
      _typeMatches(const {'retail', 'تجزئة'});

  /// Pure Retail listing (no main category) — cart checkout.
  bool get isPureRetailProduct => isRetailProduct && hasNoMainCategory;

  /// Booking / Retail / Offers / Requests — shown under service sections only.
  bool get isServiceTypeProduct {
    final typeId = productTypeId;
    if (typeId != null && typeId >= 1 && typeId <= 4) return true;
    return _typeMatches(const {
      'retail',
      'booking',
      'offers',
      'requests',
      'تجزئة',
      'حجز',
      'عروض',
      'طلبات',
    });
  }

  bool get hasNoMainCategory =>
      categoryId == null || categoryId! <= 0;

  /// Retail / Booking / Offers / Requests listing with no main category.
  bool get isPureServiceTypeListing =>
      isServiceTypeProduct && hasNoMainCategory;

  /// Home Products for company customer / supplier / guest: CategoryId only.
  bool get isMainCategoryHomeProduct =>
      categoryId != null && categoryId! > 0;

  /// Home Products for personal customer: Retail only, no main category.
  bool get isPersonalRetailHomeProduct =>
      isRetailProduct && hasNoMainCategory;

  /// Retail service tab / by-type feed: pure retail OR category hybrids dual-listed as Retail.
  bool get isRetailFeedProduct =>
      isRetailProduct || hasRetailPricing;

  /// Prefer retail cart when opening from search dual-list retail card.
  bool get preferRetailFromSearchListing {
    if (searchListingChannel == 'retail') return true;
    if (searchListingChannel == 'category') return false;
    return isRetailProduct && hasNoMainCategory;
  }

  /// Category + retail dual listing (wholesale + retail fields).
  bool get isHybridCategoryRetail =>
      hasRetailPricing && categoryId != null && categoryId! > 0;

  /// Main-category catalog (incl. hybrids). Uses Purchase Order, not cart.
  bool get isCategoryCatalogProduct =>
      categoryId != null && categoryId! > 0;

  /// Price shown for a browse channel (My Ads Retail vs Categories).
  String priceForChannel({required bool preferRetail}) {
    if (preferRetail && hasRetailPricing) {
      final retail = retailPrice.trim();
      if (retail.isNotEmpty) return retail;
    }
    final display = displayPrice.trim();
    if (display.isNotEmpty) return display;
    return priceUsd.trim();
  }

  /// Quantity shown for a browse channel.
  String quantityForChannel({required bool preferRetail}) {
    if (preferRetail && hasRetailPricing) {
      final qty = retailQuantity.trim();
      if (qty.isNotEmpty) return qty;
    }
    return quantity;
  }

  /// Unit shown for a browse channel.
  String unitNameForChannel({required bool preferRetail}) {
    if (preferRetail && hasRetailPricing) {
      final unit = retailUnitName.trim();
      if (unit.isNotEmpty) return unit;
    }
    return unitName;
  }

  final String description;
  final String descriptionEn;
  final String descriptionAr;
  final String priceUsd;
  final String displayPrice;
  final String currency;
  final String quantity;
  final String unitName;
  final String unitNameEn;
  final String minimumOrderQuantity;
  final String maximumOrderQuantity;
  final String status;
  /// Canonical English status from API — use for filters / matching.
  final String statusNameEn;
  final String approvalStatus;
  final String negotiable;
  final String isFeatured;
  final String viewsCount;
  final List<String> images;
  final List<String> documents;
  final MyListingShippingModel shipping;
  final String discountPercentage;
  final String discountDays;
  final String offerDuration;
  final String supplierNotes;
  /// Packing type id (1–255).
  final int? packaging;
  final String packagingDetails;
  final String shippingDuration;
  final String videoPath;
  final List<String> videoPaths;
  final List<ProductVideoMetadata> videos;
  final String videoDurationSeconds;
  final String createdAt;
  final String updatedAt;
  final String ownerId;
  final int pendingOffersCount;
  /// Search/image dual listing: `retail` | `category` (empty when not expanded).
  final String searchListingChannel;

  final bool hasRetailPricing;
  final String retailPrice;
  final String retailUnitName;
  final String retailUnitNameEn;
  final String retailQuantity;
  final int? retailPackaging;
  final String retailPackagingDetails;
  final String retailDescription;
  final String retailDescriptionEn;
  final String retailDescriptionAr;
  final int? requestTypeId;
  final String requestTypeName;
  final int? bookingPriceTypeId;
  final String bookingPriceTypeName;
  final String bookingPriceTypeNameEn;
  final String shippingDescriptionEn;

  /// English/canonical status for filters (`Active`, `Paused`, …).
  String get statusCanonical {
    final en = statusNameEn.trim();
    if (en.isNotEmpty) return en;
    return status.trim();
  }

  /// Listing visibility from API: `Active`, `Paused`, `Under Review`, etc.
  bool get isListingActive {
    final s = statusCanonical.toLowerCase();
    return s == 'active' || s.contains('نشط');
  }

  bool get isApprovalApproved {
    final s = approvalStatus.trim().toLowerCase();
    return s == 'approved' || s.contains('معتمد');
  }

  bool get isNegotiable => _parseBoolFlag(negotiable);

  bool get isCreatedInArabic =>
      createdLanguage.trim().toLowerCase().startsWith('ar');

  /// Text to show in the edit form (authored language first).
  String get editDisplayName {
    if (isCreatedInArabic) {
      final ar = nameAr.trim();
      if (ar.isNotEmpty) return ar;
      final display = productName.trim();
      if (display.isNotEmpty) return display;
    }
    final en = nameEn.trim();
    if (en.isNotEmpty) return en;
    return productName.trim();
  }

  String get editDisplayDescription {
    if (isCreatedInArabic) {
      final ar = descriptionAr.trim();
      if (ar.isNotEmpty) return ar;
      final display = description.trim();
      if (display.isNotEmpty) return display;
    }
    final en = descriptionEn.trim();
    if (en.isNotEmpty) return en;
    return description.trim();
  }

  String get editDisplayRetailDescription {
    if (isCreatedInArabic) {
      final ar = retailDescriptionAr.trim();
      if (ar.isNotEmpty) return ar;
      final display = retailDescription.trim();
      if (display.isNotEmpty) return display;
    }
    final en = retailDescriptionEn.trim();
    if (en.isNotEmpty) return en;
    return retailDescription.trim();
  }

  bool get isRequestProduct =>
      productTypeId == 4 || _typeMatches(const {'requests', 'طلبات', 'طلب'});

  bool get isOfferProduct =>
      productTypeId == 3 || _typeMatches(const {'offers', 'عروض', 'عرض'});

  bool get isBookingProduct =>
      productTypeId == 2 ||
      _typeMatches(const {'booking', 'حجز', 'بوكينج'});

  /// Orders on these ad types require admin review before the seller can act
  /// when the order includes notes/media (Booking / Offers / Requests / Category).
  bool get requiresAdminOrderModeration {
    if (isCategoryCatalogProduct) return true;
    if (isPureRetailProduct) return false;
    final typeId = productTypeId;
    if (typeId == 2 || typeId == 3 || typeId == 4) return true;
    return _typeMatches(const {
      'booking',
      'offers',
      'requests',
      'حجز',
      'عروض',
      'طلبات',
    });
  }

  bool _typeMatches(Set<String> keys) {
    final candidates = <String>{
      productTypeNameEn.trim().toLowerCase(),
      productTypeName.trim().toLowerCase(),
    };
    for (final value in candidates) {
      if (value.isEmpty) continue;
      if (keys.contains(value)) return true;
    }
    return false;
  }

  /// Base listing price without customer markup (for edit forms).
  String get ownerListingPrice {
    final base = priceUsd.trim();
    if (base.isNotEmpty) return base;
    return displayPrice.trim();
  }

  bool get isFeaturedListing => _parseBoolFlag(isFeatured);

  List<String> get allVideoPaths {
    final paths = <String>[];
    for (final video in videos) {
      final path = video.path.trim();
      if (path.isNotEmpty && !paths.contains(path)) {
        paths.add(path);
      }
    }
    for (final path in videoPaths) {
      final trimmed = path.trim();
      if (trimmed.isNotEmpty && !paths.contains(trimmed)) {
        paths.add(trimmed);
      }
    }
    final primary = videoPath.trim();
    if (primary.isNotEmpty && !paths.contains(primary)) {
      paths.insert(0, primary);
    }
    return paths;
  }

  List<ProductVideoMetadata> get allVideos {
    final videosByPath = <String, ProductVideoMetadata>{};
    for (final video in videos) {
      final path = video.path.trim();
      if (path.isNotEmpty) videosByPath.putIfAbsent(path, () => video);
    }
    for (final path in allVideoPaths) {
      videosByPath.putIfAbsent(
        path,
        () => ProductVideoMetadata(
          path: path,
          durationSeconds: int.tryParse(videoDurationSeconds),
        ),
      );
    }
    return videosByPath.values.toList(growable: false);
  }

  /// Duration / required-date value for edit preload (top-level or nested shipping).
  String get resolvedShippingDuration {
    final top = shippingDuration.trim();
    if (top.isNotEmpty) return top;
    return shipping.shippingDuration.trim();
  }

  String get originCountryName => shipping.routeFromCountry;

  String get destinationCountryName => shipping.routeToCountry;

  String get loadingPortName => shipping.routeFromPort;

  String get arrivalPortName => shipping.routeToPort;

  String get originCountryNameEn => shipping.routeFromCountryEn;

  String get destinationCountryNameEn => shipping.routeToCountryEn;

  String get loadingPortNameEn => shipping.routeFromPortEn;

  String get arrivalPortNameEn => shipping.routeToPortEn;

  /// Minimal listing used when opening ad orders from a push notification.
  factory MyListingProductModel.notificationStub({
    required String productId,
    String productName = '',
    String productTypeName = '',
  }) {
    return MyListingProductModel(
      productId: productId,
      productName: productName,
      nameEn: '',
      categoryName: '',
      categoryImagePath: '',
      productTypeName: productTypeName,
      description: '',
      descriptionEn: '',
      priceUsd: '',
      displayPrice: '',
      currency: 'AED',
      quantity: '',
      unitName: '',
      unitNameEn: '',
      minimumOrderQuantity: '',
      maximumOrderQuantity: '',
      status: '',
      approvalStatus: '',
      negotiable: '',
      isFeatured: '',
      viewsCount: '',
      images: const [],
      documents: const [],
      shipping: const MyListingShippingModel(),
    );
  }

  factory MyListingProductModel.fromJson(Map<String, dynamic> json) {
    final images = _parseStringList(json['images']);
    final videos = _parseVideos(json['videos'] ?? json['Videos']);
    final shippingJson = _asStringKeyMap(json['shipping'] ?? json['Shipping']);
    final createdLang = LocalizedProductText.createdLanguageOf(json);

    return MyListingProductModel(
      productId: json['productId']?.toString() ??
          _extractProductIdFromAssetPaths(images) ??
          '',
      productName: () {
        final localized = LocalizedProductText.pickName(json);
        if (localized.isNotEmpty) return localized;
        return json['productName']?.toString() ??
            json['nameEn']?.toString() ??
            json['NameEn']?.toString() ??
            json['name']?.toString() ??
            '';
      }(),
      nameEn: json['nameEn']?.toString() ??
          json['NameEn']?.toString() ??
          json['productName']?.toString() ??
          '',
      nameAr: json['nameAr']?.toString() ??
          json['NameAr']?.toString() ??
          '',
      createdLanguage: createdLang ?? 'en',
      categoryName: () {
        final localized = LocalizedProductText.pick(
          json: json,
          arKeys: const ['categoryNameAr', 'CategoryNameAr'],
          enKeys: const [
            'categoryNameEn',
            'CategoryNameEn',
            'categoryName',
            'CategoryName',
          ],
        );
        if (localized.isNotEmpty) return localized;
        return json['categoryName']?.toString() ?? '';
      }(),
      categoryNameEn: json['categoryNameEn']?.toString() ??
          json['CategoryNameEn']?.toString() ??
          json['categoryName']?.toString() ??
          '',
      categoryImagePath: json['categoryImagePath']?.toString() ?? '',
      categoryId: _parseCategoryId(json),
      productTypeId: _parseProductTypeId(json),
      productTypeName: () {
        final localized = LocalizedProductText.pickForLanguage(
          json: json,
          language: createdLang,
          arKeys: const ['productTypeNameAr', 'ProductTypeNameAr'],
          enKeys: const [
            'productTypeNameEn',
            'ProductTypeNameEn',
            'productTypeName',
            'ProductTypeName',
            'productType',
          ],
        );
        if (localized.isNotEmpty) return localized;
        return json['productTypeName']?.toString() ??
            json['ProductTypeName']?.toString() ??
            json['productType']?.toString() ??
            '';
      }(),
      productTypeNameEn: () {
        final en = (json['productTypeNameEn'] ?? json['ProductTypeNameEn'])
                ?.toString()
                .trim() ??
            '';
        if (en.isNotEmpty) return en;
        final raw = (json['productTypeName'] ?? json['ProductTypeName'])
                ?.toString()
                .trim() ??
            '';
        // If only Arabic label is present, keep raw; filter helpers also match Arabic.
        return raw;
      }(),
      productCode: json['productCode']?.toString() ??
          json['ProductCode']?.toString() ??
          '',
      description: () {
        final localized = LocalizedProductText.pickDescription(json);
        if (localized.isNotEmpty) return localized;
        return json['description']?.toString() ??
            json['descriptionEn']?.toString() ??
            json['DescriptionEn']?.toString() ??
            '';
      }(),
      descriptionEn: json['descriptionEn']?.toString() ??
          json['DescriptionEn']?.toString() ??
          json['description']?.toString() ??
          '',
      descriptionAr: json['descriptionAr']?.toString() ??
          json['DescriptionAr']?.toString() ??
          '',
      priceUsd: json['usdPrice']?.toString() ??
          json['priceUsd']?.toString() ??
          json['USDPrice']?.toString() ??
          (json['currency']?.toString().toUpperCase() == 'USD'
              ? json['price']?.toString()
              : null) ??
          '',
      displayPrice: json['price']?.toString() ??
          json['displayPrice']?.toString() ??
          json['priceAed']?.toString() ??
          json['priceUsd']?.toString() ??
          json['usdPrice']?.toString() ??
          '',
      currency: (json['currency'] ?? json['Currency'] ?? 'AED')
          .toString()
          .toUpperCase(),
      quantity: json['quantity']?.toString() ?? '',
      unitName: () {
        final localized = LocalizedProductText.pickForLanguage(
          json: json,
          language: createdLang,
          arKeys: const ['unitNameAr', 'UnitNameAr'],
          enKeys: const [
            'unitNameEn',
            'UnitNameEn',
            'unitName',
            'UnitName',
          ],
        );
        if (localized.isNotEmpty) return localized;
        return json['unitName']?.toString() ?? '';
      }(),
      unitNameEn: json['unitNameEn']?.toString() ??
          json['UnitNameEn']?.toString() ??
          json['unitName']?.toString() ??
          '',
      minimumOrderQuantity: json['minimumOrderQuantity']?.toString() ?? '',
      maximumOrderQuantity: json['maximumOrderQuantity']?.toString() ?? '',
      status: () {
        final localized = LocalizedProductText.pickForLanguage(
          json: json,
          language: createdLang,
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
        if (localized.isNotEmpty) return localized;
        return json['status']?.toString() ?? '';
      }(),
      statusNameEn: LocalizedProductText.pickEn(
        json: json,
        enKeys: const [
          'statusNameEn',
          'StatusNameEn',
          'status',
          'Status',
        ],
      ),
      approvalStatus: () {
        final localized = LocalizedProductText.pickForLanguage(
          json: json,
          language: createdLang,
          arKeys: const ['approvalStatusAr', 'ApprovalStatusAr'],
          enKeys: const [
            'approvalStatusEn',
            'ApprovalStatusEn',
            'approvalStatus',
            'ApprovalStatus',
          ],
        );
        if (localized.isNotEmpty) return localized;
        return json['approvalStatus']?.toString() ?? '';
      }(),
      negotiable: _parseBoolFlag(json['negotiable'] ?? json['Negotiable'])
          ? 'Yes'
          : 'No',
      isFeatured: _parseBoolFlag(json['isFeatured'] ?? json['IsFeatured'])
          ? 'Yes'
          : 'No',
      viewsCount: json['viewsCount']?.toString() ?? '',
      images: images,
      documents: _parseStringList(json['documents']),
      shipping: () {
        final shippingSource = shippingJson != null
            ? <String, dynamic>{...json, ...shippingJson}
            : json;
        final localizedShipping = LocalizedProductText.pickForLanguage(
          json: shippingSource,
          language: createdLang,
          arKeys: const [
            'shippingDescriptionAr',
            'ShippingDescriptionAr',
            'additionalShippingNotesAr',
            'AdditionalShippingNotesAr',
          ],
          enKeys: const [
            'shippingDescriptionEn',
            'ShippingDescriptionEn',
            'shippingDescription',
            'additionalShippingNotes',
            'AdditionalShippingNotes',
          ],
        );
        final shippingDescription = localizedShipping.isNotEmpty
            ? localizedShipping
            : (shippingJson != null
                ? (shippingJson['shippingDescriptionEn'] ??
                    shippingJson['additionalShippingNotes'] ??
                    json['shippingDescriptionEn'] ??
                    json['ShippingDescriptionEn'])
                : (json['shippingDescriptionEn'] ??
                    json['ShippingDescriptionEn']));
        final originCountry = LocalizedProductText.pickForLanguage(
          json: shippingSource,
          language: createdLang,
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
        final destinationCountry = LocalizedProductText.pickForLanguage(
          json: shippingSource,
          language: createdLang,
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
        final loadingPort =
            LocalizedProductText.pickLoadingPort(shippingSource);
        final arrivalPort =
            LocalizedProductText.pickArrivalPort(shippingSource);
        final originCountryEn = LocalizedProductText.pickEn(
          json: shippingSource,
          enKeys: const [
            'originCountryNameEn',
            'OriginCountryNameEn',
            'originCountryName',
            'OriginCountryName',
            'routeFromCountry',
          ],
        );
        final destinationCountryEn = LocalizedProductText.pickEn(
          json: shippingSource,
          enKeys: const [
            'destinationCountryNameEn',
            'DestinationCountryNameEn',
            'destinationCountryName',
            'DestinationCountryName',
            'routeToCountry',
          ],
        );
        final loadingPortEn = LocalizedProductText.pickEn(
          json: shippingSource,
          enKeys: const [
            'loadingPortNameEn',
            'LoadingPortNameEn',
            'routeFromPortEn',
            'routeFromPort',
            'loadingPortName',
            'LoadingPortName',
          ],
        );
        final arrivalPortEn = LocalizedProductText.pickEn(
          json: shippingSource,
          enKeys: const [
            'arrivalPortNameEn',
            'ArrivalPortNameEn',
            'routeToPortEn',
            'routeToPort',
            'arrivalPortName',
            'ArrivalPortName',
          ],
        );
        final nestedDuration = shippingJson?['shippingDuration']?.toString() ??
            shippingJson?['ShippingDuration']?.toString() ??
            json['shippingDuration']?.toString() ??
            json['ShippingDuration']?.toString() ??
            '';
        if (shippingJson != null) {
          return MyListingShippingModel.fromJson({
            ...shippingJson,
            'shippingDescriptionEn': shippingDescription,
            if (nestedDuration.trim().isNotEmpty)
              'shippingDuration': nestedDuration.trim(),
            if (originCountry.isNotEmpty) 'routeFromCountry': originCountry,
            if (destinationCountry.isNotEmpty)
              'routeToCountry': destinationCountry,
            if (loadingPort.isNotEmpty) 'routeFromPort': loadingPort,
            if (arrivalPort.isNotEmpty) 'routeToPort': arrivalPort,
            if (originCountryEn.isNotEmpty)
              'routeFromCountryEn': originCountryEn,
            if (destinationCountryEn.isNotEmpty)
              'routeToCountryEn': destinationCountryEn,
            if (loadingPortEn.isNotEmpty) 'routeFromPortEn': loadingPortEn,
            if (arrivalPortEn.isNotEmpty) 'routeToPortEn': arrivalPortEn,
          });
        }
        return MyListingShippingModel.fromJson({
          'originCountryName': originCountry.isNotEmpty
              ? originCountry
              : json['originCountryName'],
          'destinationCountryName': destinationCountry.isNotEmpty
              ? destinationCountry
              : json['destinationCountryName'],
          'loadingPortName':
              loadingPort.isNotEmpty ? loadingPort : json['loadingPortName'],
          'arrivalPortName':
              arrivalPort.isNotEmpty ? arrivalPort : json['arrivalPortName'],
          'originCountryNameEn': originCountryEn,
          'destinationCountryNameEn': destinationCountryEn,
          'loadingPortNameEn': loadingPortEn,
          'arrivalPortNameEn': arrivalPortEn,
          'shippingDescriptionEn': shippingDescription,
          'routeSummary': json['routeSummary'],
          if (nestedDuration.trim().isNotEmpty)
            'shippingDuration': nestedDuration.trim(),
        });
      }(),
      discountPercentage: json['discountPercentage']?.toString() ?? '',
      discountDays: json['discountDays']?.toString() ?? '',
      offerDuration: json['offerDuration']?.toString() ??
          json['OfferDuration']?.toString() ??
          '',
      supplierNotes: () {
        final direct = (json['supplierNotes'] ?? json['SupplierNotes'])
            ?.toString()
            .trim();
        if (direct != null && direct.isNotEmpty) return direct;
        final localized = LocalizedProductText.pickForLanguage(
          json: json,
          language: createdLang,
          arKeys: const ['supplierNotesAr', 'SupplierNotesAr'],
          enKeys: const [
            'supplierNotesEn',
            'SupplierNotesEn',
            'supplierNotes',
            'SupplierNotes',
          ],
        );
        if (localized.isNotEmpty) return localized;
        return json['supplierNotesEn']?.toString() ?? '';
      }(),
      packaging: _parsePackaging(json),
      packagingDetails: json['packagingDetails']?.toString() ??
          json['PackagingDetails']?.toString() ??
          '',
      shippingDuration: () {
        final top = json['shippingDuration']?.toString() ??
            json['ShippingDuration']?.toString() ??
            '';
        if (top.trim().isNotEmpty) return top.trim();
        if (shippingJson != null) {
          final nested = shippingJson['shippingDuration']?.toString() ??
              shippingJson['ShippingDuration']?.toString() ??
              '';
          if (nested.trim().isNotEmpty) return nested.trim();
        }
        return '';
      }(),
      videoPath: json['videoPath']?.toString() ?? '',
      videoPaths: _parseStringList(json['videoPaths'] ?? json['VideoPaths']),
      videos: videos,
      videoDurationSeconds: json['videoDurationSeconds']?.toString() ?? '',
      createdAt: json['createdAt']?.toString() ?? '',
      updatedAt: json['updatedAt']?.toString() ?? '',
      ownerId: json['ownerId']?.toString() ?? '',
      pendingOffersCount: int.tryParse(
            json['pendingOffersCount']?.toString() ??
                json['PendingOffersCount']?.toString() ??
                '0',
          ) ??
          0,
      hasRetailPricing: _parseBoolFlag(
        json['hasRetailPricing'] ?? json['HasRetailPricing'],
      ),
      searchListingChannel: (json['searchListingChannel'] ??
                  json['SearchListingChannel'] ??
                  '')
              .toString()
              .trim()
              .toLowerCase(),
      retailPrice: json['retailPrice']?.toString() ??
          json['RetailPrice']?.toString() ??
          '',
      retailUnitName: () {
        final localized = LocalizedProductText.pickForLanguage(
          json: json,
          language: createdLang,
          arKeys: const ['retailUnitNameAr', 'RetailUnitNameAr'],
          enKeys: const [
            'retailUnitNameEn',
            'RetailUnitNameEn',
            'retailUnitName',
            'RetailUnitName',
          ],
        );
        if (localized.isNotEmpty) return localized;
        return json['retailUnitName']?.toString() ??
            json['RetailUnitName']?.toString() ??
            '';
      }(),
      retailUnitNameEn: json['retailUnitNameEn']?.toString() ??
          json['RetailUnitNameEn']?.toString() ??
          json['retailUnitName']?.toString() ??
          json['RetailUnitName']?.toString() ??
          '',
      retailQuantity: json['retailQuantity']?.toString() ??
          json['RetailQuantity']?.toString() ??
          '',
      retailPackaging: _parsePackaging({
        'packaging': json['retailPackaging'] ?? json['RetailPackaging'],
      }),
      retailPackagingDetails: json['retailPackagingDetails']?.toString() ??
          json['RetailPackagingDetails']?.toString() ??
          '',
      retailDescription: () {
        final localized = LocalizedProductText.pickForLanguage(
          json: json,
          language: LocalizedProductText.createdLanguageOf(json),
          arKeys: const [
            'retailDescriptionAr',
            'RetailDescriptionAr',
          ],
          enKeys: const [
            'retailDescriptionEn',
            'RetailDescriptionEn',
            'retailDescription',
            'RetailDescription',
          ],
        );
        if (localized.isNotEmpty) return localized;
        return json['retailDescription']?.toString() ??
            json['RetailDescription']?.toString() ??
            json['retailDescriptionEn']?.toString() ??
            json['RetailDescriptionEn']?.toString() ??
            '';
      }(),
      retailDescriptionEn: json['retailDescriptionEn']?.toString() ??
          json['RetailDescriptionEn']?.toString() ??
          json['retailDescription']?.toString() ??
          json['RetailDescription']?.toString() ??
          '',
      retailDescriptionAr: json['retailDescriptionAr']?.toString() ??
          json['RetailDescriptionAr']?.toString() ??
          '',
      requestTypeId: _parseRequestTypeId(json),
      requestTypeName: () {
        // Prefer English for edit matching; Arabic aliases still resolve via fromApiValue.
        final en = json['requestTypeNameEn']?.toString() ??
            json['RequestTypeNameEn']?.toString() ??
            '';
        if (en.trim().isNotEmpty) return en.trim();
        return _parseRequestTypeName(json);
      }(),
      bookingPriceTypeId: _parseBookingPriceTypeId(json),
      bookingPriceTypeName: _parseBookingPriceTypeName(json),
      bookingPriceTypeNameEn: _parseBookingPriceTypeName(json),
      shippingDescriptionEn: json['shippingDescriptionEn']?.toString() ??
          json['ShippingDescriptionEn']?.toString() ??
          (shippingJson is Map<String, dynamic>
              ? (shippingJson['shippingDescriptionEn']?.toString() ??
                  shippingJson['ShippingDescriptionEn']?.toString() ??
                  shippingJson['additionalShippingNotes']?.toString() ??
                  '')
              : ''),
    );
  }

  static bool _parseBoolFlag(dynamic value) {
    if (value is bool) return value;
    final asString = value?.toString().trim().toLowerCase();
    return asString == 'true' || asString == '1' || asString == 'yes';
  }

  static List<ProductVideoMetadata> _parseVideos(dynamic value) {
    if (value is! List) return const [];
    final videos = <ProductVideoMetadata>[];
    for (final item in value) {
      if (item is! Map) continue;
      final path = (item['path'] ??
                  item['Path'] ??
                  item['videoPath'] ??
                  item['VideoPath'])
              ?.toString()
              .trim() ??
          '';
      if (path.isEmpty) continue;
      final duration = int.tryParse(
        (item['durationSeconds'] ?? item['DurationSeconds'])?.toString() ?? '',
      );
      videos.add(
        ProductVideoMetadata(
          id: (item['id'] ?? item['Id'])?.toString().trim() ?? '',
          path: path,
          durationSeconds: duration,
          isMuted: _parseBoolOrDefault(
            item['isMuted'] ?? item['IsMuted'],
            defaultValue: true,
          ),
        ),
      );
    }
    return videos;
  }

  static bool _parseBoolOrDefault(
    dynamic value, {
    required bool defaultValue,
  }) {
    if (value == null) return defaultValue;
    return _parseBoolFlag(value);
  }

  static String? _extractProductIdFromAssetPaths(List<String> paths) {
    for (final path in paths) {
      final match = RegExp(
        r'/(?:product-images|product-documents)/([^/]+)/',
      ).firstMatch(path);
      if (match != null) return match.group(1);
    }
    return null;
  }

  static int? _parseCategoryId(Map<String, dynamic> json) {
    final raw = json['categoryId'] ?? json['CategoryId'];
    if (raw == null) return null;
    final parsed = int.tryParse(raw.toString());
    if (parsed == null || parsed <= 0) return null;
    return parsed;
  }

  static int? _parseProductTypeId(Map<String, dynamic> json) {
    final raw = json['productTypeId'] ?? json['ProductTypeId'];
    if (raw == null) return null;
    return int.tryParse(raw.toString());
  }

  static int? _parsePackaging(Map<String, dynamic> json) {
    final raw = json['packaging'] ?? json['Packaging'];
    if (raw == null || raw.toString().trim().isEmpty) return null;
    if (raw is num) {
      final value = raw.toInt();
      if (value <= 0 || value > 255) return null;
      return value;
    }
    final value = int.tryParse(raw.toString().trim());
    if (value == null || value <= 0 || value > 255) return null;
    return value;
  }

  static int? _parseRequestTypeId(Map<String, dynamic> json) {
    final raw = json['requestTypeId'] ?? json['RequestTypeId'];
    final fromRaw = _requestTypeIdFromDynamic(raw);
    if (fromRaw != null) return fromRaw;

    final nested = json['requestType'] ?? json['RequestType'];
    if (nested is Map) {
      return _requestTypeIdFromDynamic(nested['id'] ?? nested['Id']);
    }
    if (nested is num || nested is String) {
      return _requestTypeIdFromDynamic(nested);
    }
    return null;
  }

  /// Backend public list: `requestTypeName` = "Local" | "Reexport".
  /// Mutation response may use `requestType` as the name string.
  static String _parseRequestTypeName(Map<String, dynamic> json) {
    for (final key in const [
      'requestTypeName',
      'RequestTypeName',
      'requestFulfillment',
      'RequestFulfillment',
    ]) {
      final value = json[key]?.toString().trim() ?? '';
      if (value.isNotEmpty && int.tryParse(value) == null) return value;
      // Numeric string belongs to id — still keep readable name if only digits.
      if (value == '1') return 'Local';
      if (value == '2') return 'Reexport';
    }

    final requestType = json['requestType'] ?? json['RequestType'];
    if (requestType is String) {
      final value = requestType.trim();
      if (value.isNotEmpty) {
        if (value == '1') return 'Local';
        if (value == '2') return 'Reexport';
        if (int.tryParse(value) == null) return value;
      }
    }
    if (requestType is Map) {
      for (final key in const ['nameEn', 'NameEn', 'name', 'Name']) {
        final value = requestType[key]?.toString().trim() ?? '';
        if (value.isNotEmpty) return value;
      }
    }
    return '';
  }

  static String _parseBookingPriceTypeName(Map<String, dynamic> json) {
    for (final key in const [
      'bookingPriceTypeName',
      'BookingPriceTypeName',
      'bookingPriceType',
      'BookingPriceType',
    ]) {
      final value = json[key]?.toString().trim() ?? '';
      if (value.isEmpty) continue;
      if (value == '1') return 'FOB';
      if (value == '2') return 'CNF';
      if (value == '3') return 'CIF';
      if (int.tryParse(value) == null) return value;
    }
    return '';
  }

  static int? _parseBookingPriceTypeId(Map<String, dynamic> json) {
    final raw = json['bookingPriceTypeId'] ?? json['BookingPriceTypeId'];
    if (raw == null) return null;
    if (raw is int) return raw;
    return int.tryParse(raw.toString());
  }

  static int? _requestTypeIdFromDynamic(dynamic raw) {
    if (raw == null) return null;
    if (raw is int) return raw > 0 ? raw : null;
    if (raw is num) {
      final value = raw.toInt();
      return value > 0 ? value : null;
    }
    final text = raw.toString().trim();
    if (text.isEmpty) return null;
    final parsed = int.tryParse(text);
    if (parsed != null && parsed > 0) return parsed;

    final lower = text.toLowerCase();
    if (lower == 'local' || lower == 'محلي') return 1;
    if (lower == 'reexport' ||
        lower == 'rexport' ||
        lower == 're-export' ||
        lower == 'booking' ||
        lower == 'إعادة تصدير' ||
        lower == 'اعادة تصدير') {
      return 2;
    }
    return null;
  }

  static Map<String, dynamic>? _asStringKeyMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      return value.map((key, item) => MapEntry(key.toString(), item));
    }
    return null;
  }

  static List<String> _parseStringList(dynamic value) {
    if (value is! List) return const [];
    final paths = <String>[];
    for (final item in value) {
      if (item is String) {
        final trimmed = item.trim();
        if (trimmed.isNotEmpty) paths.add(trimmed);
        continue;
      }
      if (item is Map) {
        final path = item['path'] ??
            item['Path'] ??
            item['imagePath'] ??
            item['ImagePath'] ??
            item['documentPath'] ??
            item['DocumentPath'];
        final trimmed = path?.toString().trim() ?? '';
        if (trimmed.isNotEmpty) paths.add(trimmed);
      }
    }
    return paths;
  }

  String? get primaryImageUrl => _assetUrl(images.isNotEmpty ? images.first : null);

  String? get categoryImageUrl => _assetUrl(categoryImagePath);

  static String? _assetUrl(String? path) {
    final url = ApiConstants.resolveMediaUrl(path);
    return url.isEmpty ? null : url;
  }

  bool get hasDiscount {
    final value = int.tryParse(discountPercentage.trim());
    return value != null && value > 0;
  }

  String get discountLabel => hasDiscount ? '-$discountPercentage%' : '';

  bool get hasDiscountDays {
    final value = int.tryParse(discountDays.trim());
    return value != null && value > 0;
  }

  int get discountPercentValue =>
      int.tryParse(discountPercentage.trim()) ?? 0;

  int get viewsCountValue => int.tryParse(viewsCount.trim()) ?? 0;

  int get discountDaysValue {
    final fromDays = int.tryParse(discountDays.trim());
    if (fromDays != null && fromDays > 0) return fromDays;

    // Fallback: OfferDuration may hold the day count (e.g. "7" or "7 days").
    final raw = offerDuration.trim();
    if (raw.isEmpty) return 0;
    final asInt = int.tryParse(raw);
    if (asInt != null && asInt > 0) return asInt;
    final match = RegExp(r'(\d+)').firstMatch(raw);
    return int.tryParse(match?.group(1) ?? '') ?? 0;
  }

  DateTime? get createdAtUtc => UtcDateTime.parseAsUtc(createdAt);

  DateTime? get discountEndsAtUtc {
    final created = createdAtUtc;
    final days = discountDaysValue;
    if (created == null || days <= 0) return null;
    return created.add(Duration(days: days));
  }

  bool get isDiscountActive {
    if (!hasDiscount) return false;
    final ends = discountEndsAtUtc;
    if (ends == null) return true;
    return DateTime.now().toUtc().isBefore(ends);
  }

  /// Sale price currently stored on the product (after discount while active).
  double get salePriceValue =>
      double.tryParse(displayPrice.trim().isNotEmpty ? displayPrice : priceUsd) ??
      0;

  /// Pre-discount price derived from sale price + percentage.
  double get originalPriceValue {
    final sale = salePriceValue;
    final pct = discountPercentValue;
    if (sale <= 0 || pct <= 0 || pct >= 100) return sale;
    return sale / (1 - (pct / 100));
  }

  Duration? get discountRemaining {
    final ends = discountEndsAtUtc;
    if (ends == null) return null;
    final left = ends.difference(DateTime.now().toUtc());
    return left.isNegative ? Duration.zero : left;
  }
}
