import 'dart:io';

import 'package:alrasmarket/core/helper/cach_helper.dart';
import 'package:alrasmarket/core/media/video_compressor.dart';
import 'package:alrasmarket/core/utils/thousands_separator_input_formatter.dart';
import 'package:alrasmarket/features/company/data/models/create_ad_product_request.dart';
import 'package:alrasmarket/features/company/presentation/controller/cubit/create_ad_states.dart';
import 'package:alrasmarket/features/company/presentation/models/booking_price_type.dart';
import 'package:alrasmarket/features/company/presentation/models/create_ad_currency.dart';
import 'package:alrasmarket/features/company/presentation/models/create_ad_packing_options.dart';
import 'package:alrasmarket/features/company/presentation/models/create_ad_type.dart';
import 'package:alrasmarket/features/company/presentation/widgets/create_ad/create_ad_unit_options.dart';
import 'package:alrasmarket/generated/l10n.dart';
import 'package:flutter/material.dart';

class CreateAdFormMapper {
  CreateAdFormMapper._();

  static const int maxProductVideoBytes = 100 * 1024 * 1024;
  static const int maxProductVideoSizeMb = 100;
  static const int maxProductVideoDurationSeconds = 180;
  static const int maxProductVideos = 5;
  static const int maxProductImages = 15;

  /// Current app UI language (`en` / `ar`) — stored on create as CreatedLanguage.
  static String currentAppLanguage() {
    final raw = CachHelper.getData(CachHelper.languageCode)?.toString() ??
        CachHelper.getData('locale')?.toString() ??
        '';
    return raw.trim().toLowerCase().startsWith('ar') ? 'ar' : 'en';
  }

  /// Maps [CreateAdCategorySelectionField] dropdown index → DB CategoryId.
  static const categoryIdsByIndex = <int>[
    1, // herbs
    2, // pulses
    3, // spices
    4, // nuts
    5, // coffee
    6, // cardamom
    7, // cocoa
    8, // acids
    9, // milk
    10, // dates
    11, // sugar
    12, // rice
    13, // sweets
    14, // canned
    15, // flour
    16, // beauty
    17, // poultry
    18, // frozen foods
  ];

  static const categoryLabelsEn = <String>[
    'Herbs',
    'Pulses',
    'Spices',
    'Nuts',
    'Coffee',
    'Cardamom',
    'Cocoa',
    'Acids',
    'Milk',
    'Dates',
    'Sugar',
    'Rice',
    'Sweets',
    'Canned',
    'Flour',
    'Beauty',
    'Poultry',
    'Frozen Foods',
  ];

  /// Maps UI unit labels to canonical Units.UnitNameEn values stored in DB.
  static String mapUnitName(String unit) {
    switch (CreateAdUnitOptions.canonical(unit).toLowerCase()) {
      case 'kg':
        return 'Kilogram';
      case 'gram':
        return 'Gram';
      case 'ton':
        return 'Ton';
      case 'piece':
        return 'Piece';
      case 'box':
        return 'Box';
      case 'carton':
        return 'Carton';
      case 'bag':
        return 'Bag';
      case 'dozen':
        return 'Dozen';
      case 'packet':
        return 'Packet';
      case 'bundle':
        return 'Bundle';
      case 'drum':
        return 'Drum';
      case 'bottle':
        return 'Bottle';
      case 'tin':
        return 'Tin';
      case 'sack':
        return 'Sack';
      case 'case':
        return 'Case';
      case 'pallet':
        return 'Pallet';
      case 'liter':
        return 'Liter';
      case 'ml':
        return 'Ml';
      case 'jar':
        return 'Jar';
      default:
        return unit.trim();
    }
  }

  static int? categoryIdForIndex(int? index) {
    if (index == null || index < 0 || index >= categoryIdsByIndex.length) {
      return null;
    }
    return categoryIdsByIndex[index];
  }

  static String? categoryLabelEnForIndex(int? index) {
    if (index == null || index < 0 || index >= categoryLabelsEn.length) {
      return null;
    }
    return categoryLabelsEn[index];
  }

  static bool isVideoPath(String path) {
    final ext = path.split('.').last.toLowerCase();
    return ext == 'mp4' || ext == 'mov' || ext == 'webm' || ext == 'm4v';
  }

  static bool _isImagePath(String path) {
    final ext = path.split('.').last.toLowerCase();
    return ext == 'png' ||
        ext == 'jpg' ||
        ext == 'jpeg' ||
        ext == 'webp' ||
        ext == 'heic' ||
        ext == 'heif';
  }

  /// Match backend `NormalizeAssetPath` for delete-by-path API.
  static String normalizeRemoteImagePathForApi(String path) {
    var value = path.trim().replaceAll('\\', '/');
    if (value.startsWith('http://') || value.startsWith('https://')) {
      try {
        value = Uri.parse(value).path;
      } catch (_) {
        // keep trimmed value
      }
    }
    const marker = '/product-images/';
    final idx = value.toLowerCase().indexOf(marker);
    if (idx >= 0) {
      value = value.substring(idx);
    }
    if (value.isEmpty) return value;
    if (!value.startsWith('/')) {
      value = '/${value.replaceFirst(RegExp(r'^/+'), '')}';
    }
    return value;
  }

  static bool skipsPortsForBooking(CreateAdFormState state) {
    return state.selectedType == CreateAdType.booking.label &&
        state.bookingPriceType == BookingPriceType.fob;
  }

  /// FOB Booking: destination country is hidden and must not be submitted.
  static bool skipsDestinationForBooking(CreateAdFormState state) {
    return skipsPortsForBooking(state);
  }

  static bool skipsGeoForState(CreateAdFormState state) {
    final selectedType = state.selectedType;
    if (selectedType == CreateAdType.offers.label ||
        selectedType == CreateAdType.retail.label ||
        selectedType == CreateAdType.categories.label ||
        selectedType == CreateAdType.requests.label) {
      return true;
    }
    if ((selectedType == null || selectedType.isEmpty) &&
        state.selectedCategoryId != null) {
      return true;
    }
    return false;
  }

  static ({String? productTypeName, int? categoryId}) resolveCatalogFields({
    required String? selectedType,
    required int? categoryId,
  }) {
    final type = selectedType?.trim();
    final isCategoryAd = type == CreateAdType.categories.label;
    final isHybridRetailOnCategory = categoryId != null &&
        categoryId > 0 &&
        type?.toLowerCase() == CreateAdType.retail.label.toLowerCase();

    if (isCategoryAd || isHybridRetailOnCategory) {
      return (productTypeName: null, categoryId: categoryId);
    }

    if (type != null && type.isNotEmpty) {
      return (productTypeName: type, categoryId: null);
    }

    if (categoryId != null) {
      return (productTypeName: null, categoryId: categoryId);
    }

    return (productTypeName: CreateAdType.retail.label, categoryId: null);
  }

  static String? resolveProductTypeName(
    String? selectedType, {
    int? categoryId,
  }) {
    return resolveCatalogFields(
      selectedType: selectedType,
      categoryId: categoryId,
    ).productTypeName;
  }

  static String? resolveRequestTypeName(CreateAdFormState state) {
    final type = state.selectedType;
    final supportsPriceType = type == CreateAdType.requests.label ||
        type == CreateAdType.offers.label ||
        type == CreateAdType.categories.label;
    if (!supportsPriceType) return null;
    return state.requestFulfillmentType?.apiValue;
  }

  static String? resolveBookingPriceTypeName(CreateAdFormState state) {
    if (state.selectedType != CreateAdType.booking.label) return null;
    return state.bookingPriceType?.apiValue;
  }

  static String? firstLocalVideoPath(List<String> productImages) {
    for (final path in productImages) {
      if (isVideoPath(path) && _isLocalDevicePath(path)) {
        return path;
      }
    }
    return null;
  }

  static List<String> localVideoPaths(List<String> productImages) {
    return productImages
        .where((path) => isVideoPath(path) && _isLocalDevicePath(path))
        .toList(growable: false);
  }

  static Future<String?> validateVideoFile(String path) async {
    if (!isVideoPath(path)) return null;
    if (!_isLocalDevicePath(path)) return null;

    final file = File(path);
    if (!await file.exists()) {
      return S.current.videoFileNotFound;
    }

    final size = await file.length();
    if (size > maxProductVideoBytes) {
      final sizeMb = (size / (1024 * 1024)).toStringAsFixed(1);
      return S.current.videoSizeExceeded(sizeMb, maxProductVideoSizeMb);
    }

    return null;
  }

  static Future<String?> validateVideoDuration(
    String path, {
    String? tooLongMessage,
    String? unreadableMessage,
  }) async {
    if (!isVideoPath(path)) return null;

    final duration = await VideoCompressor.readDurationSeconds(path);
    if (duration <= 0) {
      return unreadableMessage ?? S.current.videoDurationUnreadable;
    }
    if (duration.round() > maxProductVideoDurationSeconds) {
      return tooLongMessage ?? S.current.videoMaxDurationSeconds;
    }
    return null;
  }

  static CreateAdProductRequest buildRequest({
    required CreateAdFormState state,
    required TextEditingController productNameController,
    required TextEditingController quantityController,
    required TextEditingController specificationsController,
    required TextEditingController packingKgController,
    TextEditingController? otherPackingController,
    bool isOtherPacking = false,
    required TextEditingController beforeDiscountController,
    required TextEditingController afterDiscountController,
    required TextEditingController priceController,
    required TextEditingController shippingDurationController,
    required int? selectedCategoryId,
    TextEditingController? retailPriceController,
    TextEditingController? retailQuantityController,
    TextEditingController? retailSpecificationsController,
    TextEditingController? retailPackingKgController,
    TextEditingController? retailOtherPackingController,
    bool isRetailOtherPacking = false,
    File? productVideoFile,
    int? videoDurationSeconds,
    bool isEditMode = false,
    String? canonicalNameEn,
    String? canonicalDescriptionEn,
    String? loadedLocalizedName,
    String? loadedLocalizedDescription,
  }) {
    final typedName = productNameController.text.trim();
    final typedSpecs = specificationsController.text.trim();
    // If Arabic UI showed translated name/description and the user did not edit
    // them, submit the original English values so price/qty-only edits stay live.
    final nameTrim = isEditMode &&
            canonicalNameEn != null &&
            canonicalNameEn.trim().isNotEmpty &&
            typedName == (loadedLocalizedName ?? '').trim()
        ? canonicalNameEn.trim()
        : typedName;
    final specsTrim = isEditMode &&
            canonicalDescriptionEn != null &&
            typedSpecs == (loadedLocalizedDescription ?? '').trim()
        ? canonicalDescriptionEn.trim()
        : typedSpecs;
    final qtyText = quantityController.text.trim();
    final priceText = priceController.text.trim();
    final shippingDurationText = shippingDurationController.text.trim();
    final isOffers = state.selectedType == CreateAdType.offers.label;
    final isCategories =
        state.selectedType == CreateAdType.categories.label ||
        (selectedCategoryId != null &&
            selectedCategoryId > 0 &&
            state.enableRetailPricing);
    final sendsShippingDuration =
        state.selectedType == CreateAdType.booking.label ||
        state.selectedType == CreateAdType.retail.label;
    final skipsGeo = skipsGeoForState(state);
    final skipsPorts = skipsPortsForBooking(state);
    final skipsDestination = skipsDestinationForBooking(state);
    final offerDurationDaysText = isOffers
        ? _normalizeOfferDurationDays(shippingDurationText)
        : null;
    final offerDurationDays = offerDurationDaysText == null
        ? null
        : int.tryParse(offerDurationDaysText);

    final isRequest = state.selectedType == CreateAdType.requests.label;

    final quantity = isEditMode
        ? (qtyText.isEmpty ? null : ThousandsNumberInput.parseInt(qtyText))
        : isRequest
            ? (qtyText.isEmpty
                ? 0
                : ThousandsNumberInput.parseInt(qtyText) ?? 0)
            : (ThousandsNumberInput.parseInt(qtyText) ?? 0);
    final double? usdPrice = isEditMode
        ? _resolveUsdPriceNullable(
            state: state,
            beforeDiscountController: beforeDiscountController,
            afterDiscountController: afterDiscountController,
            priceController: priceController,
          )
        : isRequest
            ? (priceText.isEmpty
                ? 0.0
                : ThousandsNumberInput.parseDouble(priceText) ?? 0.0)
            : _resolveUsdPrice(
                state: state,
                beforeDiscountController: beforeDiscountController,
                afterDiscountController: afterDiscountController,
                priceController: priceController,
              );

    final discount = _resolveDiscount(
      state: state,
      beforeDiscountController: beforeDiscountController,
      afterDiscountController: afterDiscountController,
      shippingDurationController: shippingDurationController,
    );

    final currencyValue = state.selectedType == CreateAdType.booking.label
        ? CreateAdCurrency.usd
        : state.selectedType == CreateAdType.retail.label
            ? CreateAdCurrency.aed
            : isRequest && (usdPrice == null || usdPrice <= 0)
                ? ''
                : CreateAdCurrency.normalize(
                    state.selectedCurrency.trim().isEmpty
                        ? CreateAdCurrency.aed
                        : state.selectedCurrency,
                  );
    final unitValue = isRequest &&
            qtyText.isEmpty &&
            priceText.isEmpty
        ? ''
        : mapUnitName(state.selectedUnit);
    final catalogFields = resolveCatalogFields(
      selectedType: state.selectedType,
      categoryId: selectedCategoryId,
    );

    final enableRetail = isCategories && state.enableRetailPricing;
    double? retailPrice;
    String? retailUnitName;
    int? retailQuantity;
    int? retailPackaging;
    String? retailPackagingDetails;
    String? retailDescriptionEn;
    if (isCategories) {
      if (enableRetail) {
        final retailPriceText = retailPriceController?.text.trim() ?? '';
        final retailQtyText = retailQuantityController?.text.trim() ?? '';
        retailPrice = retailPriceText.isEmpty
            ? (isEditMode ? null : 0.0)
            : ThousandsNumberInput.parseDouble(retailPriceText);
        retailQuantity = retailQtyText.isEmpty
            ? (isEditMode ? null : 0)
            : ThousandsNumberInput.parseInt(retailQtyText);
        retailUnitName = mapUnitName(state.selectedRetailUnit);
        final retailOtherText = retailOtherPackingController?.text.trim() ?? '';
        final useRetailOther = isRetailOtherPacking && retailOtherText.isNotEmpty;
        retailPackaging = useRetailOther
            ? null
            : CreateAdPackingOptions.parseInput(
                retailPackingKgController?.text ?? '',
              );
        retailPackagingDetails = useRetailOther ? retailOtherText : null;
        final retailSpecs =
            retailSpecificationsController?.text.trim() ?? '';
        retailDescriptionEn = retailSpecs.isEmpty
            ? (isEditMode ? null : '')
            : retailSpecs;
      }
    }

    return CreateAdProductRequest(
      nameEn: isEditMode
          ? (nameTrim.isEmpty ? null : nameTrim)
          : nameTrim,
      createdLanguage: isEditMode ? null : currentAppLanguage(),
      usdPrice: usdPrice,
      currency: isEditMode && currencyValue.isEmpty
          ? null
          : (isRequest && currencyValue.isEmpty ? null : currencyValue),
      quantity: quantity,
      descriptionEn: isEditMode
          ? (specsTrim.isEmpty ? null : specsTrim)
          : specsTrim,
      productTypeName: catalogFields.productTypeName,
      unitName: isEditMode
          ? (state.selectedUnit.isEmpty ? null : unitValue)
          : (isRequest && unitValue.isEmpty ? '' : unitValue),
      // Offers / Retail do not collect ports — never send placeholder Egypt/Hurghada.
      originCountryName: skipsGeo
          ? null
          : (isEditMode
              ? _nullableGeoField(skipsGeo: false, value: state.originCountry)
              : state.originCountry),
      destinationCountryName: skipsGeo || skipsDestination
          ? null
          : (isEditMode
              ? _nullableGeoField(
                  skipsGeo: false,
                  value: state.destinationCountry,
                )
              : state.destinationCountry),
      loadingPortName: skipsGeo || skipsPorts
          ? null
          : (isEditMode
              ? _nullableGeoField(skipsGeo: false, value: state.originPort)
              : state.originPort),
      arrivalPortName: skipsGeo || skipsPorts
          ? null
          : (isEditMode
              ? _nullableGeoField(skipsGeo: false, value: state.destinationPort)
              : state.destinationPort),
      categoryId: catalogFields.categoryId,
      negotiable: state.negotiationType.isNegotiable,
      discountPercentage: discount?.percentage,
      discountDays: isOffers
          ? (offerDurationDays != null && offerDurationDays > 0
              ? offerDurationDays
              : discount?.days)
          : discount?.days,
      shippingDuration: () {
        if (sendsShippingDuration && shippingDurationText.isNotEmpty) {
          return shippingDurationText;
        }
        // Requests: persist required delivery date as ShippingDuration.
        if (state.selectedType == CreateAdType.requests.label &&
            state.requiredDeliveryDate != null) {
          // Calendar date only — do not use toUtc() (shifts the day and forces re-review).
          final d = state.requiredDeliveryDate!;
          final mm = d.month.toString().padLeft(2, '0');
          final dd = d.day.toString().padLeft(2, '0');
          return '${d.year}-$mm-$dd';
        }
        return null;
      }(),
      offerDuration: offerDurationDaysText,
      shippingDescriptionEn: null,
      packaging: (isOtherPacking &&
              (otherPackingController?.text.trim().isNotEmpty ?? false))
          ? null
          : CreateAdPackingOptions.parseInput(packingKgController.text),
      packagingDetails: (isOtherPacking &&
              (otherPackingController?.text.trim().isNotEmpty ?? false))
          ? otherPackingController!.text.trim()
          : null,
      requestTypeName: resolveRequestTypeName(state),
      bookingPriceTypeName: resolveBookingPriceTypeName(state),
      address: state.address?.trim().isEmpty ?? true ? null : state.address?.trim(),
      addressId:
          state.addressId?.trim().isEmpty ?? true ? null : state.addressId?.trim(),
      productVideoFile: productVideoFile,
      videoDurationSeconds: productVideoFile != null
          ? (videoDurationSeconds ?? 0)
              .clamp(1, maxProductVideoDurationSeconds)
          : null,
      enableRetailPricing: isCategories
          // On edit, omit false so wholesale Categories do not clear retail /
          // force ProductTypeId=null and falsely require re-review.
          ? (enableRetail ? true : (isEditMode ? null : false))
          : null,
      retailPrice: isCategories ? (enableRetail ? retailPrice : null) : null,
      retailUnitName: isCategories ? (enableRetail ? retailUnitName : null) : null,
      retailQuantity: isCategories ? (enableRetail ? retailQuantity : null) : null,
      retailPackaging:
          isCategories ? (enableRetail ? retailPackaging : null) : null,
      retailPackagingDetails:
          isCategories ? (enableRetail ? retailPackagingDetails : null) : null,
      retailDescriptionEn:
          isCategories ? (enableRetail ? retailDescriptionEn : null) : null,
    );
  }

  static List<String> imagePathsForUpload({
    required List<String> productImages,
    List<String> productDocuments = const [],
  }) {
    final images = <String>[];
    for (final path in [...productImages, ...productDocuments]) {
      if (_isImagePath(path) &&
          _isLocalDevicePath(path) &&
          !images.contains(path)) {
        images.add(path);
      }
    }
    return images;
  }

  static List<String> documentPathsForUpload({
    required List<String> productDocuments,
  }) {
    return productDocuments
        .where(_isLocalDevicePath)
        .where((path) => !_isImagePath(path))
        .toList();
  }

  /// True for http(s) URLs and backend-relative paths (e.g. `/uploads/...`).
  static bool isRemoteAssetPath(String path) {
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return true;
    }
    if (!path.startsWith('/')) {
      return false;
    }
    if (path.contains('/create_ad_assets/')) {
      return false;
    }
    const deviceRoots = [
      '/data/',
      '/var/',
      '/private/',
      '/storage/',
      '/Users/',
    ];
    for (final root in deviceRoots) {
      if (path.startsWith(root)) {
        return false;
      }
    }
    return true;
  }

  static bool _isLocalDevicePath(String path) => !isRemoteAssetPath(path);

  static String? _nullableGeoField({
    required bool skipsGeo,
    required String? value,
  }) {
    if (skipsGeo) return null;
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;
    return trimmed;
  }

  static double? _resolveUsdPriceNullable({
    required CreateAdFormState state,
    required TextEditingController beforeDiscountController,
    required TextEditingController afterDiscountController,
    required TextEditingController priceController,
  }) {
    if (state.selectedType == CreateAdType.offers.label) {
      final afterText = afterDiscountController.text.trim();
      if (afterText.isEmpty) {
        final beforeText = beforeDiscountController.text.trim();
        if (beforeText.isEmpty) return null;
        return ThousandsNumberInput.parseDouble(beforeText);
      }
      return ThousandsNumberInput.parseDouble(afterText);
    }

    final priceText = priceController.text.trim();
    if (priceText.isEmpty) return null;
    return ThousandsNumberInput.parseDouble(priceText);
  }

  static double _resolveUsdPrice({
    required CreateAdFormState state,
    required TextEditingController beforeDiscountController,
    required TextEditingController afterDiscountController,
    required TextEditingController priceController,
  }) {
    if (state.selectedType == CreateAdType.offers.label) {
      final after =
          ThousandsNumberInput.parseDouble(afterDiscountController.text.trim());
      if (after != null && after > 0) return after;
      final before =
          ThousandsNumberInput.parseDouble(beforeDiscountController.text.trim());
      if (before != null && before > 0) return before;
      return 0.0;
    }

    return ThousandsNumberInput.parseDouble(priceController.text.trim()) ?? 0.0;
  }

  static ({int percentage, int days})? _resolveDiscount({
    required CreateAdFormState state,
    required TextEditingController beforeDiscountController,
    required TextEditingController afterDiscountController,
    required TextEditingController shippingDurationController,
  }) {
    if (state.selectedType != CreateAdType.offers.label) return null;

    final before =
        ThousandsNumberInput.parseDouble(beforeDiscountController.text.trim());
    final after =
        ThousandsNumberInput.parseDouble(afterDiscountController.text.trim());
    if (before == null ||
        after == null ||
        before <= 0 ||
        after <= 0 ||
        after >= before) {
      return null;
    }

    final days = int.tryParse(
          _normalizeOfferDurationDays(shippingDurationController.text.trim()) ??
              '',
        ) ??
        0;
    if (days <= 0) return null;

    final percentage = (((before - after) / before) * 100).round().clamp(1, 99);
    return (percentage: percentage, days: days);
  }

  /// Persist offer length as a bare day count ("7") so "7 days" vs "7" never
  /// looks like a content change that forces admin re-review.
  static String? _normalizeOfferDurationDays(String? raw) {
    final text = raw?.trim() ?? '';
    if (text.isEmpty) return null;
    final asInt = int.tryParse(text);
    if (asInt != null && asInt > 0) return asInt.toString();
    final match = RegExp(r'(\d+)').firstMatch(text);
    final parsed = int.tryParse(match?.group(1) ?? '');
    if (parsed != null && parsed > 0) return parsed.toString();
    return text;
  }

  /// Edit-form preload helper (never returns null — empty string if unknown).
  static String normalizeOfferDurationForEdit(String? raw) =>
      _normalizeOfferDurationDays(raw) ?? '';
}
