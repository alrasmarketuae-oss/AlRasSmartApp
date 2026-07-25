import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

import 'package:alrasmarket/core/media/media_compression_service.dart';
import 'package:alrasmarket/core/media/video_compressor.dart';
import 'package:alrasmarket/core/ui/widgets/feedback/app_toast.dart';
import 'package:alrasmarket/core/serveses/auth_service.dart';
import 'package:alrasmarket/core/serveses/catalog_sync_service.dart';
import 'package:alrasmarket/features/clint/data/models/category_model.dart';
import 'package:alrasmarket/features/clint/domain/usecases/get_categories_usecase.dart';
import 'package:alrasmarket/features/company/data/models/create_ad_product_request.dart';
import 'package:alrasmarket/features/company/data/models/my_listing_product_model.dart';
import 'package:alrasmarket/features/company/domain/usecases/create_ad_usecases.dart';
import 'package:alrasmarket/features/company/domain/usecases/get_geo_usecases.dart';
import 'package:alrasmarket/features/company/presentation/helpers/create_ad_form_mapper.dart';
import 'package:alrasmarket/features/company/presentation/widgets/create_ad/create_ad_unit_options.dart';
import 'package:alrasmarket/generated/l10n.dart';
import '../../models/booking_price_type.dart';
import '../../models/create_ad_currency.dart';
import '../../models/create_ad_packing_options.dart';
import '../../models/create_ad_publish_step.dart';
import '../../models/create_ad_type.dart';
import '../../models/negotiation_type.dart';
import '../../models/request_fulfillment_type.dart';
import 'create_ad_states.dart';

class CreateAdCubit extends Cubit<CreateAdFormState> {
  CreateAdCubit({
    required GetGeoPortsByCountryUseCase getGeoPortsByCountryUseCase,
    required GetCategoriesUseCase getCategoriesUseCase,
    required CreateProductUseCase createProductUseCase,
    required UpdateProductUseCase updateProductUseCase,
    required UploadProductImagesUseCase uploadProductImagesUseCase,
    required DeleteProductImagesByPathUseCase deleteProductImagesByPathUseCase,
    required UploadProductDocumentsUseCase uploadProductDocumentsUseCase,
    required UploadProductVideoUseCase uploadProductVideoUseCase,
    required SubmitProductForAdminReviewUseCase submitProductForAdminReviewUseCase,
  }) : _getGeoPortsByCountryUseCase = getGeoPortsByCountryUseCase,
       _getCategoriesUseCase = getCategoriesUseCase,
       _createProductUseCase = createProductUseCase,
       _updateProductUseCase = updateProductUseCase,
       _uploadProductImagesUseCase = uploadProductImagesUseCase,
       _deleteProductImagesByPathUseCase = deleteProductImagesByPathUseCase,
       _uploadProductDocumentsUseCase = uploadProductDocumentsUseCase,
       _uploadProductVideoUseCase = uploadProductVideoUseCase,
       _submitProductForAdminReviewUseCase = submitProductForAdminReviewUseCase,
       super(const CreateAdFormState()) {
    fetchCategories();
    _applyNonUaeBookingDefault();
  }

  void _applyNonUaeBookingDefault() {
    if (AuthService.instance.isUaePhoneNumber) return;
    if (state.selectedType == CreateAdType.booking.label) {
      if (state.selectedCurrency != CreateAdCurrency.usd) {
        emit(state.copyWith(selectedCurrency: CreateAdCurrency.usd));
      }
      return;
    }
    emit(
      state.copyWith(
        selectedType: CreateAdType.booking.label,
        selectedCurrency: CreateAdCurrency.usd,
      ),
    );
  }

  final GetGeoPortsByCountryUseCase _getGeoPortsByCountryUseCase;
  final GetCategoriesUseCase _getCategoriesUseCase;
  final CreateProductUseCase _createProductUseCase;
  final UpdateProductUseCase _updateProductUseCase;
  final UploadProductImagesUseCase _uploadProductImagesUseCase;
  final DeleteProductImagesByPathUseCase _deleteProductImagesByPathUseCase;
  final UploadProductDocumentsUseCase _uploadProductDocumentsUseCase;
  final UploadProductVideoUseCase _uploadProductVideoUseCase;
  final SubmitProductForAdminReviewUseCase _submitProductForAdminReviewUseCase;

  final List<String> _pendingRemoteImageDeletes = [];
  String? _initialRemoteVideoPath;

  /// Canonical English fields from API — used on submit when the user did not
  /// edit the localized display text (prevents Arabic locale from forcing re-review).
  String? _canonicalNameEn;
  String? _canonicalDescriptionEn;
  String? _loadedLocalizedName;
  String? _loadedLocalizedDescription;

  /// Edit category may resolve after [fetchCategories] completes.
  int? _pendingEditCategoryId;
  String? _pendingEditCategoryLabel;

  /// Local paths already persisted + compressed — safe to upload as-is.
  final Set<String> _uploadReadyLocalPaths = {};
  int _activeMediaPrepJobs = 0;

  static CreateAdCubit get(BuildContext context) =>
      context.read<CreateAdCubit>();

  GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final productNameController = TextEditingController();
  final quantityController = TextEditingController();
  final specificationsController = TextEditingController();
  final packingKgController = TextEditingController();
  final retailSpecificationsController = TextEditingController();
  final retailPackingKgController = TextEditingController();
  final beforeDiscountController = TextEditingController();
  final afterDiscountController = TextEditingController();
  final priceController = TextEditingController();
  final retailPriceController = TextEditingController();
  final retailQuantityController = TextEditingController();

  /// Shared duration field for Offers / Booking / Retail → `ShippingDuration` API.
  final shippingDurationController = TextEditingController();
  final originCountryController = TextEditingController();
  final destinationCountryController = TextEditingController();

  final ImagePicker _imagePicker = ImagePicker();
  final Map<String, ({String country, List<String> ports})> _portsCache = {};

  List<CategoryModel> categories = [];
  bool isLoadingCategories = false;

  Future<void> fetchCategories() async {
    isLoadingCategories = true;
    emit(state.copyWith(formRevision: state.formRevision + 1));

    final result = await _getCategoriesUseCase(
      const GetCategoriesParams(forceRefresh: true),
    );
    result.fold(
      (_) {
        categories = [];
        isLoadingCategories = false;
        emit(state.copyWith(formRevision: state.formRevision + 1));
      },
      (items) {
        categories = items;
        isLoadingCategories = false;
        _reapplyEditCategorySelection();
        emit(state.copyWith(formRevision: state.formRevision + 1));
      },
    );
  }

  /// Edit opens before categories finish loading — re-bind dropdown once ready.
  void _reapplyEditCategorySelection() {
    if (!state.isEditMode) return;
    final id = state.selectedCategoryId ?? _pendingEditCategoryId;
    if (id == null && (_pendingEditCategoryLabel ?? '').isEmpty) return;

    final matched = _matchCategory(
      categoryId: id,
      categoryLabel: _pendingEditCategoryLabel ?? state.selectedCategory,
    );
    if (matched == null) return;

    emit(
      state.copyWith(
        selectedCategoryId: matched.categoryId,
        selectedCategory: matched.nameEn,
        formRevision: state.formRevision + 1,
      ),
    );
  }

  CategoryModel? _matchCategory({
    int? categoryId,
    String? categoryLabel,
  }) {
    if (categories.isEmpty) return null;

    if (categoryId != null && categoryId > 0) {
      for (final item in categories) {
        if (item.categoryId == categoryId) return item;
      }
    }

    final label = (categoryLabel ?? '').trim();
    if (label.isEmpty) return null;
    final lower = label.toLowerCase();
    for (final item in categories) {
      if (item.nameEn.trim().toLowerCase() == lower) return item;
      if (item.nameAr.trim() == label ||
          item.nameAr.trim().toLowerCase() == lower) {
        return item;
      }
    }
    return null;
  }

  void setSelectedType(String? type) {
    final isRetail = type == CreateAdType.retail.label;
    final isBooking = type == CreateAdType.booking.label;
    final isCategory = type == CreateAdType.categories.label;
    final supportsPriceType = type == CreateAdType.requests.label ||
        type == CreateAdType.offers.label ||
        isCategory;
    if (!isCategory) {
      retailPriceController.clear();
      retailQuantityController.clear();
    }
    emit(
      state.copyWith(
        selectedType: type,
        selectedCurrency: isBooking
            ? CreateAdCurrency.usd
            : isRetail
                ? CreateAdCurrency.aed
                : CreateAdCurrency.aed,
        clearRequestFulfillmentType: !supportsPriceType,
        clearBookingPriceType: !isBooking,
        clearSelectedCategory: !isCategory,
        clearSelectedCategoryId: !isCategory,
        enableRetailPricing: isCategory ? state.enableRetailPricing : false,
      ),
    );
  }

  void setRequestFulfillmentType(RequestFulfillmentType type) {
    emit(state.copyWith(requestFulfillmentType: type));
  }

  void setBookingPriceType(BookingPriceType? type) {
    if (type == null) {
      emit(state.copyWith(clearBookingPriceType: true));
      return;
    }
    emit(state.copyWith(bookingPriceType: type));
  }

  void setRequiredDeliveryDate(DateTime date) {
    emit(state.copyWith(requiredDeliveryDate: date));
  }

  void setSelectedCategory(int categoryId, String label) {
    emit(
      state.copyWith(
        selectedCategoryId: categoryId,
        selectedCategory: label,
        selectedType: CreateAdType.categories.label,
      ),
    );
  }

  void clearSubmitFeedback() {
    emit(
      state.copyWith(
        clearSubmitErrorMessage: true,
        clearSubmitSuccessMessage: true,
        clearSubmitNavigateProductId: true,
      ),
    );
  }

  /// Prefill form for PUT /api/Products/{productId} (edit mode).
  void loadProductForEdit(MyListingProductModel product) {
    // Show the language the ad was authored in. Keep English canonical values
    // for submit-if-unchanged so price/qty-only edits do not force re-review.
    final nameEn = product.nameEn.trim().isNotEmpty
        ? product.nameEn.trim()
        : product.productName.trim();
    final descriptionEn = product.descriptionEn.trim().isNotEmpty
        ? product.descriptionEn.trim()
        : product.description.trim();
    final retailDescriptionEn = product.retailDescriptionEn.trim().isNotEmpty
        ? product.retailDescriptionEn.trim()
        : product.retailDescription.trim();

    final displayName = product.editDisplayName;
    final displayDescription = product.editDisplayDescription;
    final displayRetailDescription = product.editDisplayRetailDescription;

    productNameController.text = displayName;
    quantityController.text = product.quantity;
    specificationsController.text = displayDescription;
    _canonicalNameEn = nameEn.isNotEmpty ? nameEn : null;
    _canonicalDescriptionEn =
        descriptionEn.isNotEmpty ? descriptionEn : null;
    _loadedLocalizedName = displayName;
    _loadedLocalizedDescription = displayDescription;
    final packingKg = CreateAdPackingOptions.normalize(product.packaging);
    packingKgController.text = packingKg?.toString() ?? '';
    retailSpecificationsController.text = displayRetailDescription;
    final retailPackingKg =
        CreateAdPackingOptions.normalize(product.retailPackaging);
    retailPackingKgController.text = retailPackingKg?.toString() ?? '';

    final editType = _resolveEditProductType(product);
    final isOffers =
        editType?.toLowerCase() == CreateAdType.offers.label.toLowerCase();

    if (isOffers) {
      final saleUsd = double.tryParse(product.priceUsd.trim()) ?? 0;
      final pct = product.discountPercentValue;
      final beforeUsd = (saleUsd > 0 && pct > 0 && pct < 100)
          ? saleUsd / (1 - pct / 100)
          : saleUsd;
      afterDiscountController.text = saleUsd > 0
          ? _formatEditPrice(saleUsd)
          : product.displayPrice.trim();
      beforeDiscountController.text =
          beforeUsd > 0 ? _formatEditPrice(beforeUsd) : '';
      final offerDays = product.offerDuration.trim().isNotEmpty
          ? product.offerDuration.trim()
          : product.discountDays.trim().isNotEmpty
              ? product.discountDays.trim()
              : product.resolvedShippingDuration;
      shippingDurationController.text =
          CreateAdFormMapper.normalizeOfferDurationForEdit(offerDays);
      priceController.clear();
    } else {
      priceController.text = product.isRequestProduct
          ? product.ownerListingPrice
          : (product.displayPrice.trim().isNotEmpty
              ? product.displayPrice
              : product.priceUsd);
      beforeDiscountController.clear();
      afterDiscountController.clear();
      shippingDurationController.text = product.resolvedShippingDuration;
    }

    int? resolvedCategoryId = product.categoryId;
    _pendingEditCategoryId = product.categoryId;
    _pendingEditCategoryLabel = product.categoryNameEn.trim().isNotEmpty
        ? product.categoryNameEn.trim()
        : product.categoryName.trim();

    final matchedCategory = _matchCategory(
      categoryId: resolvedCategoryId,
      categoryLabel: _pendingEditCategoryLabel,
    );
    if (matchedCategory != null) {
      resolvedCategoryId = matchedCategory.categoryId;
    }

    final hasRetail = product.hasRetailPricing ||
        (product.retailPrice.trim().isNotEmpty &&
            (double.tryParse(product.retailPrice.trim()) ?? 0) > 0);
    if (hasRetail) {
      retailPriceController.text = product.retailPrice.trim().isNotEmpty
          ? product.retailPrice.trim()
          : '';
      retailQuantityController.text = product.retailQuantity.trim();
    } else {
      retailPriceController.clear();
      retailQuantityController.clear();
    }

    final isRequests =
        editType?.toLowerCase() == CreateAdType.requests.label.toLowerCase();
    final isCategories =
        editType?.toLowerCase() == CreateAdType.categories.label.toLowerCase();
    final supportsPriceType = isRequests || isOffers || isCategories;
    final requestFulfillment = supportsPriceType
        ? (_requestFulfillmentFromProduct(product))
        : null;
    final isBooking =
        editType?.toLowerCase() == CreateAdType.booking.label.toLowerCase();
    final bookingPriceType = isBooking
        ? BookingPriceType.fromApiValue(product.bookingPriceTypeNameEn) ??
            BookingPriceType.fromApiValue(product.bookingPriceTypeName) ??
            BookingPriceType.fromId(product.bookingPriceTypeId)
        : null;

    DateTime? requiredDeliveryDate;
    if (isRequests) {
      requiredDeliveryDate = _parseRequiredDeliveryDate(
        product.resolvedShippingDuration,
      );
    }

    final originCountry = product.originCountryNameEn.trim().isNotEmpty
        ? product.originCountryNameEn.trim()
        : product.originCountryName.trim();
    final destinationCountry =
        product.destinationCountryNameEn.trim().isNotEmpty
            ? product.destinationCountryNameEn.trim()
            : product.destinationCountryName.trim();
    final originPort = product.loadingPortNameEn.trim().isNotEmpty
        ? product.loadingPortNameEn.trim()
        : product.loadingPortName.trim();
    final destinationPort = product.arrivalPortNameEn.trim().isNotEmpty
        ? product.arrivalPortNameEn.trim()
        : product.arrivalPortName.trim();

    emit(
      CreateAdFormState(
        editingProductId: product.productId,
        selectedType: editType,
        selectedCategory: matchedCategory?.nameEn ??
            (product.categoryNameEn.trim().isNotEmpty
                ? product.categoryNameEn.trim()
                : product.categoryName),
        selectedCategoryId: resolvedCategoryId,
        selectedUnit: _mapUnitFromApi(
          product.unitNameEn.trim().isNotEmpty
              ? product.unitNameEn
              : product.unitName,
        ),
        selectedRetailUnit: hasRetail &&
                (product.retailUnitNameEn.trim().isNotEmpty ||
                    product.retailUnitName.trim().isNotEmpty)
            ? _mapUnitFromApi(
                product.retailUnitNameEn.trim().isNotEmpty
                    ? product.retailUnitNameEn
                    : product.retailUnitName,
              )
            : 'Kg',
        enableRetailPricing: hasRetail,
        selectedCurrency: editType == CreateAdType.booking.label
            ? CreateAdCurrency.usd
            : editType == CreateAdType.retail.label
                ? CreateAdCurrency.aed
                : CreateAdCurrency.normalize(
                    product.currency.trim().isEmpty
                        ? CreateAdCurrency.aed
                        : product.currency,
                  ),
        negotiationType: product.negotiable.toLowerCase() == 'yes'
            ? NegotiationType.negotiable
            : NegotiationType.nonNegotiable,
        requestFulfillmentType: requestFulfillment,
        bookingPriceType: bookingPriceType,
        requiredDeliveryDate: requiredDeliveryDate,
        productImages: [
          ...product.images,
          ...product.allVideoPaths,
        ],
        productDocuments: List<String>.from(product.documents),
        originCountry: originCountry.isEmpty ? null : originCountry,
        originPort: originPort.isEmpty ? null : originPort,
        destinationCountry:
            destinationCountry.isEmpty ? null : destinationCountry,
        destinationPort: destinationPort.isEmpty ? null : destinationPort,
        formRevision: state.formRevision + 1,
      ),
    );

    _pendingRemoteImageDeletes.clear();
    _initialRemoteVideoPath =
        product.videoPath.trim().isEmpty ? null : product.videoPath.trim();

    if (originCountry.isNotEmpty) {
      originCountryController.text = originCountry;
    }
    if (destinationCountry.isNotEmpty) {
      destinationCountryController.text = destinationCountry;
    }

    // Ports lists load async — keep selected ports after lists arrive.
    if (originCountry.isNotEmpty) {
      unawaited(() async {
        await _loadPorts(country: originCountry, isOrigin: true);
        if (isClosed || originPort.isEmpty) return;
        emit(state.copyWith(originPort: originPort));
      }());
    }
    if (destinationCountry.isNotEmpty) {
      unawaited(() async {
        await _loadPorts(country: destinationCountry, isOrigin: false);
        if (isClosed || destinationPort.isEmpty) return;
        emit(state.copyWith(destinationPort: destinationPort));
      }());
    }
  }

  String _mapUnitFromApi(String unitName) {
    final normalized = CreateAdUnitOptions.canonical(unitName);
    if (normalized.isEmpty) return 'Ton';
    return CreateAdUnitOptions.values.contains(normalized) ? normalized : 'Ton';
  }

  String? _resolveEditProductType(MyListingProductModel product) {
    // Hybrid listings store ProductTypeId=Retail for the retail feed but keep
    // CategoryId for wholesale/home catalog. Edit flow must stay on Categories.
    if (product.isHybridCategoryRetail ||
        (product.categoryId != null &&
            product.categoryId! > 0 &&
            product.hasRetailPricing)) {
      return CreateAdType.categories.label;
    }

    // Prefer stable productTypeId over localized productTypeName (Arabic UI).
    switch (product.productTypeId) {
      case 1:
        return product.categoryId != null && product.categoryId! > 0
            ? CreateAdType.categories.label
            : CreateAdType.retail.label;
      case 2:
        return CreateAdType.booking.label;
      case 3:
        return CreateAdType.offers.label;
      case 4:
        return CreateAdType.requests.label;
    }

    if (product.isRequestProduct) return CreateAdType.requests.label;
    if (product.isOfferProduct) return CreateAdType.offers.label;
    if (product.isBookingProduct) return CreateAdType.booking.label;
    if (product.isPureRetailProduct) return CreateAdType.retail.label;

    // Prefer English type name; localized Arabic alone used to break fromLabel.
    final type = product.productTypeNameEn.trim().isNotEmpty
        ? product.productTypeNameEn.trim()
        : product.productTypeName.trim();
    if (type.isEmpty || type == '—' || type == '-') {
      if (product.categoryId != null ||
          product.categoryName.trim().isNotEmpty) {
        return CreateAdType.categories.label;
      }
      return null;
    }

    final fromLabel = CreateAdType.fromLabel(type);
    if (fromLabel != null) return fromLabel.label;

    if (product.categoryId != null && product.categoryId! > 0) {
      return CreateAdType.categories.label;
    }
    return null;
  }

  String _formatEditPrice(double value) {
    if (value == value.roundToDouble()) {
      return value.toInt().toString();
    }
    return value.toStringAsFixed(2);
  }

  /// Parses request required-receipt dates stored in ShippingDuration.
  DateTime? _parseRequiredDeliveryDate(String raw) {
    final text = raw.trim();
    if (text.isEmpty) return null;

    final iso = DateTime.tryParse(text);
    if (iso != null) return iso;

    final ymd = RegExp(r'^(\d{4})[-/.](\d{1,2})[-/.](\d{1,2})').firstMatch(text);
    if (ymd != null) {
      final year = int.tryParse(ymd.group(1)!);
      final month = int.tryParse(ymd.group(2)!);
      final day = int.tryParse(ymd.group(3)!);
      if (year != null && month != null && day != null) {
        return DateTime(year, month, day);
      }
    }

    final dmy = RegExp(r'^(\d{1,2})[-/.](\d{1,2})[-/.](\d{4})').firstMatch(text);
    if (dmy != null) {
      final day = int.tryParse(dmy.group(1)!);
      final month = int.tryParse(dmy.group(2)!);
      final year = int.tryParse(dmy.group(3)!);
      if (year != null && month != null && day != null) {
        return DateTime(year, month, day);
      }
    }

    return null;
  }

  void clearEditMode() {
    emit(state.copyWith(clearEditingProductId: true));
  }

  void setSelectedUnit(String? unit) {
    if (unit == null) return;
    emit(state.copyWith(selectedUnit: unit));
  }

  void setSelectedRetailUnit(String? unit) {
    if (unit == null) return;
    emit(state.copyWith(selectedRetailUnit: unit));
  }

  void setEnableRetailPricing(bool enabled) {
    if (!enabled) {
      retailPriceController.clear();
      retailQuantityController.clear();
    }
    emit(state.copyWith(enableRetailPricing: enabled));
  }

  void setSelectedCurrency(String currency) {
    if (state.selectedType == CreateAdType.booking.label) {
      emit(state.copyWith(selectedCurrency: CreateAdCurrency.usd));
      return;
    }
    if (state.selectedType == CreateAdType.retail.label) {
      emit(state.copyWith(selectedCurrency: CreateAdCurrency.aed));
      return;
    }

    emit(
      state.copyWith(selectedCurrency: CreateAdCurrency.normalize(currency)),
    );
  }

  void setNegotiationType(NegotiationType type) {
    emit(state.copyWith(negotiationType: type));
  }

  Future<void> setOriginCountry(String? country) async {
    if (country == null || country.isEmpty) return;

    originCountryController.text = country;
    emit(
      state.copyWith(
        originCountry: country,
        clearOriginPort: true,
        clearOriginPorts: true,
        isOriginPortsLoading: true,
      ),
    );
    await _loadPorts(country: country, isOrigin: true);
  }

  Future<void> setDestinationCountry(String? country) async {
    if (country == null || country.isEmpty) return;

    destinationCountryController.text = country;
    emit(
      state.copyWith(
        destinationCountry: country,
        clearDestinationPort: true,
        clearDestinationPorts: true,
        isDestinationPortsLoading: true,
      ),
    );
    await _loadPorts(country: country, isOrigin: false);
  }

  Future<void> fetchOriginPorts() async {
    final country = originCountryController.text.trim();
    await setOriginCountry(country.isEmpty ? null : country);
  }

  Future<void> fetchDestinationPorts() async {
    final country = destinationCountryController.text.trim();
    await setDestinationCountry(country.isEmpty ? null : country);
  }

  void setOriginPort(String? port) {
    emit(state.copyWith(originPort: port));
  }

  void setDestinationPort(String? port) {
    emit(state.copyWith(destinationPort: port));
  }

  Future<void> _loadPorts({
    required String country,
    required bool isOrigin,
  }) async {
    final cacheKey = country.trim().toLowerCase();
    if (_portsCache.containsKey(cacheKey)) {
      final cached = _portsCache[cacheKey]!;
      if (isOrigin) {
        emit(
          state.copyWith(
            originCountry: cached.country,
            originPorts: cached.ports,
            isOriginPortsLoading: false,
          ),
        );
      } else {
        emit(
          state.copyWith(
            destinationCountry: cached.country,
            destinationPorts: cached.ports,
            isDestinationPortsLoading: false,
          ),
        );
      }
      return;
    }

    final result = await _getGeoPortsByCountryUseCase(country);
    result.fold(
      (_) => emit(
        state.copyWith(
          isOriginPortsLoading: false,
          isDestinationPortsLoading: false,
        ),
      ),
      (response) {
        final portNames = response.ports
            .map((port) => port.englishName)
            .where((name) => name.isNotEmpty)
            .toList();
        final normalizedCountry = response.country.isNotEmpty
            ? response.country
            : country;
        _portsCache[cacheKey] = (country: normalizedCountry, ports: portNames);

        if (isOrigin) {
          if (originCountryController.text.trim().toLowerCase() == cacheKey) {
            originCountryController.text = normalizedCountry;
          }
          emit(
            state.copyWith(
              originCountry: normalizedCountry,
              originPorts: portNames,
              isOriginPortsLoading: false,
            ),
          );
        } else {
          if (destinationCountryController.text.trim().toLowerCase() ==
              cacheKey) {
            destinationCountryController.text = normalizedCountry;
          }
          emit(
            state.copyWith(
              destinationCountry: normalizedCountry,
              destinationPorts: portNames,
              isDestinationPortsLoading: false,
            ),
          );
        }
      },
    );
  }

  void removeProductImage(int index) {
    final updated = List<String>.from(state.productImages);
    if (index < 0 || index >= updated.length) return;
    final removed = updated.removeAt(index);
    if (CreateAdFormMapper.isRemoteAssetPath(removed) &&
        !CreateAdFormMapper.isVideoPath(removed)) {
      final normalized =
          CreateAdFormMapper.normalizeRemoteImagePathForApi(removed);
      if (normalized.isNotEmpty) {
        _pendingRemoteImageDeletes.add(normalized);
      }
    }
    if (CreateAdFormMapper.isVideoPath(removed) &&
        CreateAdFormMapper.isRemoteAssetPath(removed) &&
        removed == _initialRemoteVideoPath) {
      _initialRemoteVideoPath = null;
    }
    emit(state.copyWith(productImages: updated));
  }

  void removeProductDocument(int index) {
    final updated = List<String>.from(state.productDocuments)..removeAt(index);
    emit(state.copyWith(productDocuments: updated));
  }

  Future<void> pickProductDocuments(BuildContext context) async {
    final choice = await _showPickSourceSheet(
      context,
      includeFiles: true,
    );
    if (!context.mounted || choice == null) return;

    final rawPaths = await _pickPathsRaw(
      context: context,
      choice: choice,
      documentMode: true,
    );
    if (!context.mounted || rawPaths.isEmpty) return;

    // Show immediately — persist in background.
    _appendUniquePaths(
      current: state.productDocuments,
      picked: rawPaths,
      onUpdate: (paths) => emit(
        state.copyWith(
          productDocuments: paths,
          isCompressingMedia: true,
        ),
      ),
    );

    unawaited(
      _preparePickedMediaInBackground(
        context: context,
        rawPaths: rawPaths,
        forDocuments: true,
      ),
    );
  }

  Future<void> pickProductImages(BuildContext context) async {
    final rawPaths = await _pickGalleryImagesAndVideos();
    if (!context.mounted || rawPaths.isEmpty) return;

    // Show gallery paths immediately so thumbnails appear without waiting.
    _appendUniquePaths(
      current: state.productImages,
      picked: rawPaths,
      onUpdate: (paths) => emit(
        state.copyWith(
          productImages: paths,
          isCompressingMedia: true,
        ),
      ),
    );

    unawaited(
      _preparePickedMediaInBackground(
        context: context,
        rawPaths: rawPaths,
        forDocuments: false,
      ),
    );
  }

  /// Opens the device photo gallery for images and videos (not the files app).
  Future<List<String>> _pickGalleryImagesAndVideos() async {
    // Avoid imageQuality here — it compresses during pick and delays UI.
    // Compression runs in parallel after thumbnails are shown.
    final media = await _imagePicker.pickMultipleMedia();
    return media
        .map((item) => item.path)
        .where((path) => path.isNotEmpty)
        .where(_isGalleryImageOrVideoPath)
        .toList();
  }

  bool _isGalleryImageOrVideoPath(String path) {
    return CreateAdFormMapper.isVideoPath(path) ||
        MediaCompressionService.isImagePath(path);
  }

  Future<void> submitForm() async {
    if (state.isCompressingMedia) {
      emit(
        state.copyWith(
          submitErrorMessage: S.current.adUploadProgressCompressingImages,
          clearSubmitSuccessMessage: true,
        ),
      );
      return;
    }

    if (!state.isEditMode && !(formKey.currentState?.validate() ?? false)) {
      return;
    }

    final selectedType = CreateAdType.fromLabel(state.selectedType);
    if (!AuthService.instance.isUaePhoneNumber &&
        selectedType != CreateAdType.booking) {
      emit(
        state.copyWith(
          submitErrorMessage: S.current.selectAnOption,
          clearSubmitSuccessMessage: true,
        ),
      );
      return;
    }

    final requiresUserGeo = !state.isEditMode &&
        selectedType == CreateAdType.booking;

    await _executeSubmit(requiresGeo: requiresUserGeo);
  }

  /// Creates a **Requests** product from the client add-order form.
  Future<void> submitRequestOrder({
    required BuildContext context,
    required String productName,
    required String specifications,
    required String quantity,
    required String unit,
    required String targetPrice,
    required NegotiationType negotiationType,
    String? additionalNotes,
    String? address,
    String? addressId,
    DateTime? requiredDeliveryDate,
    List<String> mediaPaths = const [],
  }) async {
    if (state.isSubmitting) return;

    productNameController.text = productName.trim();
    quantityController.text = quantity.trim();
    priceController.text = targetPrice.trim();

    final specs = specifications.trim();
    final notes = additionalNotes?.trim();
    specificationsController.text =
        notes != null && notes.isNotEmpty ? '$specs\n\n$notes' : specs;

    final preparedMedia = await _finalizePickedPaths(
      context: context,
      rawPaths: mediaPaths,
    );
    if (preparedMedia.isEmpty && mediaPaths.isNotEmpty) return;

    emit(
      state.copyWith(
        clearEditingProductId: true,
        selectedType: CreateAdType.requests.label,
        selectedUnit: unit,
        negotiationType: negotiationType,
        requestFulfillmentType: RequestFulfillmentType.local,
        requiredDeliveryDate: requiredDeliveryDate,
        address: address?.trim(),
        addressId: addressId?.trim(),
        productImages: preparedMedia,
        productDocuments: const [],
        clearSubmitErrorMessage: true,
        clearSubmitSuccessMessage: true,
      ),
    );

    await _executeSubmit(
      requiresGeo: false,
      createSuccessMessage: S.current.requestPublishedSuccessfully,
      resetFormOnSuccess: false,
    );
  }

  Future<void> _executeSubmit({
    required bool requiresGeo,
    String? createSuccessMessage,
    String? updateSuccessMessage,
    bool resetFormOnSuccess = true,
  }) async {
    if (state.isSubmitting) return;

    final token = AuthService.instance.currentToken;
    if (token == null || token.isEmpty) {
      emit(
        state.copyWith(
          submitErrorMessage: S.current.pleaseLoginToPublish,
          clearSubmitSuccessMessage: true,
        ),
      );
      return;
    }

    emit(
      state.copyWith(
        isSubmitting: true,
        clearSubmitErrorMessage: true,
        clearSubmitSuccessMessage: true,
      ),
    );

    var stateForRequest = state;
    if ((stateForRequest.selectedType == null ||
            stateForRequest.selectedType!.trim().isEmpty) &&
        stateForRequest.selectedCategoryId != null) {
      stateForRequest = stateForRequest.copyWith(
        selectedType: CreateAdType.categories.label,
      );
    }
    if (requiresGeo) {
      final geo = await _resolveUserGeoForSubmit();
      if (geo == null) {
        emit(
          state.copyWith(
            isSubmitting: false,
            submitErrorMessage: S.current.completeOriginDestination,
            clearSubmitSuccessMessage: true,
          ),
        );
        return;
      }
      stateForRequest = state.copyWith(
        originCountry: geo.originCountry,
        originPort: geo.loadingPort,
        destinationCountry: geo.destinationCountry,
        destinationPort: geo.arrivalPort,
      );
    }

    final localVideoPaths = CreateAdFormMapper.localVideoPaths(
      stateForRequest.productImages,
    );
    for (final videoPath in localVideoPaths) {
      final videoFile = File(videoPath);
      if (!await videoFile.exists()) {
        emit(
          state.copyWith(
            isSubmitting: false,
            submitErrorMessage: S.current.videoFileNotFound,
            clearSubmitSuccessMessage: true,
          ),
        );
        return;
      }

      final durationError = await CreateAdFormMapper.validateVideoDuration(
        videoPath,
        tooLongMessage: S.current.videoMaxDurationSeconds,
        unreadableMessage: S.current.videoDurationUnreadable,
      );
      if (durationError != null) {
        emit(
          state.copyWith(
            isSubmitting: false,
            submitErrorMessage: durationError,
            clearSubmitSuccessMessage: true,
          ),
        );
        return;
      }
    }

    final request = CreateAdFormMapper.buildRequest(
      state: stateForRequest,
      productNameController: productNameController,
      quantityController: quantityController,
      specificationsController: specificationsController,
      packingKgController: packingKgController,
      beforeDiscountController: beforeDiscountController,
      afterDiscountController: afterDiscountController,
      priceController: priceController,
      shippingDurationController: shippingDurationController,
      selectedCategoryId: state.selectedCategoryId,
      retailPriceController: retailPriceController,
      retailQuantityController: retailQuantityController,
      retailSpecificationsController: retailSpecificationsController,
      retailPackingKgController: retailPackingKgController,
      productVideoFile: null,
      videoDurationSeconds: null,
      isEditMode: state.editingProductId != null || state.isEditMode,
      canonicalNameEn: _canonicalNameEn,
      canonicalDescriptionEn: _canonicalDescriptionEn,
      loadedLocalizedName: _loadedLocalizedName,
      loadedLocalizedDescription: _loadedLocalizedDescription,
    );

    final isCategoriesSubmit =
        stateForRequest.selectedType == CreateAdType.categories.label;
    final documentPathsForLog = isCategoriesSubmit
        ? const <String>[]
        : CreateAdFormMapper.documentPathsForUpload(
            productDocuments: state.productDocuments,
          );
    final imagePaths = CreateAdFormMapper.imagePathsForUpload(
      productImages: state.productImages,
      productDocuments:
          isCategoriesSubmit ? const [] : state.productDocuments,
    );

    _debugLogCreateAdPayload(
      request: request,
      imagePaths: imagePaths,
      documentPaths: documentPathsForLog,
    );

    if (!state.isEditMode) {
      var selectedType = stateForRequest.selectedType?.trim();
      if ((selectedType == null || selectedType.isEmpty) &&
          stateForRequest.selectedCategoryId != null) {
        selectedType = CreateAdType.categories.label;
      }

      if (selectedType == null || selectedType.isEmpty) {
        emit(
          state.copyWith(
            isSubmitting: false,
            submitErrorMessage: S.current.selectAnOption,
            clearSubmitSuccessMessage: true,
          ),
        );
        return;
      }

      if (selectedType == CreateAdType.categories.label &&
          stateForRequest.selectedCategoryId == null) {
        emit(
          state.copyWith(
            isSubmitting: false,
            submitErrorMessage: S.current.selectCategory,
            clearSubmitSuccessMessage: true,
          ),
        );
        return;
      }

      if ((selectedType == CreateAdType.requests.label ||
              selectedType == CreateAdType.offers.label ||
              selectedType == CreateAdType.categories.label) &&
          stateForRequest.requestFulfillmentType == null) {
        emit(
          state.copyWith(
            isSubmitting: false,
            submitErrorMessage: S.current.selectRequestFulfillment,
            clearSubmitSuccessMessage: true,
          ),
        );
        return;
      }

      if ((request.usdPrice ?? 0) <= 0) {
        emit(
          state.copyWith(
            isSubmitting: false,
            submitErrorMessage: S.current.enterValidPrice,
            clearSubmitSuccessMessage: true,
          ),
        );
        return;
      }

      if ((request.currency ?? '').isEmpty) {
        emit(
          state.copyWith(
            isSubmitting: false,
            submitErrorMessage: S.current.selectCurrency,
            clearSubmitSuccessMessage: true,
          ),
        );
        return;
      }

      final hasImages = imagePaths.isNotEmpty;
      final hasVideo = localVideoPaths.isNotEmpty;
      final hasDocuments =
          !isCategoriesSubmit && documentPathsForLog.isNotEmpty;

      emit(
        state.copyWith(
          publishStep: CreateAdPublishStep.creatingAd,
          publishVideoPercent: 0,
          publishHasImages: hasImages,
          publishHasVideo: hasVideo,
          publishHasDocuments: hasDocuments,
        ),
      );

      // 1) Create the ad first, then attach media synchronously with progress.
      final createResult = await _createProductUseCase(
        request: request.copyWith(clearProductVideoFile: true),
        token: token,
      );

      final createdProductId = createResult.fold<String?>((failure) {
        _emitSubmitFailure(failure.message);
        return null;
      }, (response) => response.productId);

      if (createdProductId == null || createdProductId.isEmpty) {
        return;
      }

      // 2) Images — already compressed after pick when possible.
      if (hasImages) {
        _emitPublishStep(CreateAdPublishStep.preparingImages);
        if (isClosed) return;
        final compressedImagePaths =
            await _ensureLocalMediaReadyForUpload(imagePaths);
        if (compressedImagePaths.any((p) => p.isEmpty)) {
          _emitSubmitFailure(
            S.current.adUploadProgressCompressingImages,
          );
          return;
        }

        _emitPublishStep(CreateAdPublishStep.uploadingImages);
        final imagesResult = await _uploadProductImagesUseCase(
          productId: createdProductId,
          filePaths: compressedImagePaths,
          token: token,
        );
        final imagesError = imagesResult.fold<String?>(
          (failure) => failure.message,
          (_) => null,
        );
        if (imagesError != null) {
          _emitSubmitFailure(imagesError);
          return;
        }
      }

      // 3) Videos next (compress then upload).
      if (hasVideo) {
        final videoError = await _uploadLocalVideos(
          productId: createdProductId,
          localVideoPaths: localVideoPaths,
          token: token,
        );
        if (videoError != null) {
          _emitSubmitFailure(videoError);
          return;
        }
      }

      // 4) Other files last.
      if (hasDocuments) {
        _emitPublishStep(CreateAdPublishStep.uploadingDocuments);
        final documentsResult = await _uploadProductDocumentsUseCase(
          productId: createdProductId,
          filePaths: documentPathsForLog,
          token: token,
        );
        final documentsError = documentsResult.fold<String?>(
          (failure) => failure.message,
          (_) => null,
        );
        if (documentsError != null) {
          _emitSubmitFailure(documentsError);
          return;
        }
      }

      _emitPublishStep(CreateAdPublishStep.finishing);

      final submitError = await _submitForAdminReview(
        productId: createdProductId,
        token: token,
      );
      if (submitError != null) {
        _emitSubmitFailure(submitError);
        return;
      }

      try {
        unawaited(CatalogSyncService.instance.afterAdMutation());
      } catch (_) {}

      final successMessage =
          createSuccessMessage ?? S.current.adSubmittedForReview;

      if (resetFormOnSuccess) {
        _resetForm(
          successMessage: successMessage,
          navigateProductId: createdProductId,
        );
      } else {
        emit(
          state.copyWith(
            isSubmitting: false,
            publishStep: CreateAdPublishStep.idle,
            publishVideoPercent: 0,
            submitSuccessMessage: successMessage,
            submitNavigateProductId: createdProductId,
            clearSubmitErrorMessage: true,
          ),
        );
      }
      return;
    }

    // Edit mode: update fields first so PendingProductChanges stores the
    // previous name/description before any media upload can touch the row.
    final updateRequest = request.copyWith(
      clearProductVideoFile: true,
    );

    final createResult = await _updateProductUseCase(
      productId: state.editingProductId!,
      request: updateRequest,
      token: token,
    );

    final productId = createResult.fold<String?>((failure) {
      emit(
        state.copyWith(
          isSubmitting: false,
          submitErrorMessage: failure.message,
          clearSubmitSuccessMessage: true,
        ),
      );
      return null;
    }, (response) => response.productId);

    if (productId == null || productId.isEmpty) return;

    final requiresAdminReview = createResult.fold(
      (_) => true,
      (response) => response.requiresAdminReview,
    );

    if (localVideoPaths.isNotEmpty) {
      final videoError = await _uploadLocalVideos(
        productId: productId,
        localVideoPaths: localVideoPaths,
        token: token,
      );
      if (videoError != null) {
        emit(
          state.copyWith(
            isSubmitting: false,
            submitErrorMessage: videoError,
            clearSubmitSuccessMessage: true,
          ),
        );
        return;
      }
    }

    final compressedImagePaths = imagePaths.isEmpty
        ? <String>[]
        : await _ensureLocalMediaReadyForUpload(imagePaths);
    if (compressedImagePaths.any((p) => p.isEmpty)) {
      emit(
        state.copyWith(
          isSubmitting: false,
          submitErrorMessage: S.current.adUploadProgressCompressingImages,
          clearSubmitSuccessMessage: true,
        ),
      );
      return;
    }

    final hadRemoteImageDeletes = _pendingRemoteImageDeletes.isNotEmpty;

    // Delete removed remote images first (normalized path; "not found" ignored),
    // then upload replacements so the ad can reach Under Review.
    if (hadRemoteImageDeletes) {
      final deleteResult = await _deleteProductImagesByPathUseCase(
        productId: productId,
        imagePaths: List<String>.from(_pendingRemoteImageDeletes),
        token: token,
      );
      final deleteError = deleteResult.fold<String?>(
        (failure) => failure.message,
        (_) => null,
      );
      if (deleteError != null) {
        emit(
          state.copyWith(
            isSubmitting: false,
            submitErrorMessage: deleteError,
            clearSubmitSuccessMessage: true,
          ),
        );
        return;
      }
      _pendingRemoteImageDeletes.clear();
    }

    final assetsError = await _uploadAssetsAfterProductCreated(
      productId: productId,
      token: token,
      imagePathsOverride: compressedImagePaths,
      documentPathsOverride: documentPathsForLog,
      skipDocuments: isCategoriesSubmit,
    );
    if (assetsError != null) {
      emit(
        state.copyWith(
          isSubmitting: false,
          submitErrorMessage: assetsError,
          clearSubmitSuccessMessage: true,
        ),
      );
      return;
    }

    final hasMediaMutations = localVideoPaths.isNotEmpty
        || compressedImagePaths.isNotEmpty
        || documentPathsForLog.isNotEmpty
        || hadRemoteImageDeletes;

    // Price-only field updates stay live; skip review unless media also changed.
    if (requiresAdminReview || hasMediaMutations) {
      final submitError = await _submitForAdminReview(
        productId: productId,
        token: token,
      );
      if (submitError != null) {
        emit(
          state.copyWith(
            isSubmitting: false,
            submitErrorMessage: submitError,
            clearSubmitSuccessMessage: true,
          ),
        );
        return;
      }
    }

    unawaited(CatalogSyncService.instance.afterAdMutation());

    emit(
      state.copyWith(
        isSubmitting: false,
        submitSuccessMessage:
            updateSuccessMessage ?? S.current.adUpdatedSuccessfully,
        clearSubmitErrorMessage: true,
      ),
    );
  }

  Future<String?> _submitForAdminReview({
    required String productId,
    required String token,
  }) async {
    final result = await _submitProductForAdminReviewUseCase(
      productId: productId,
      token: token,
    );
    return result.fold<String?>((failure) => failure.message, (_) => null);
  }

  void _resetForm({String? successMessage, String? navigateProductId}) {
    productNameController.clear();
    quantityController.clear();
    specificationsController.clear();
    packingKgController.clear();
    retailSpecificationsController.clear();
    retailPackingKgController.clear();
    beforeDiscountController.clear();
    afterDiscountController.clear();
    priceController.clear();
    retailPriceController.clear();
    retailQuantityController.clear();
    shippingDurationController.clear();
    originCountryController.clear();
    destinationCountryController.clear();
    _portsCache.clear();
    _canonicalNameEn = null;
    _canonicalDescriptionEn = null;
    _loadedLocalizedName = null;
    _loadedLocalizedDescription = null;
    _pendingEditCategoryId = null;
    _pendingEditCategoryLabel = null;
    _uploadReadyLocalPaths.clear();
    _activeMediaPrepJobs = 0;
    formKey = GlobalKey<FormState>();

    emit(
      CreateAdFormState(
        formRevision: state.formRevision + 1,
        submitSuccessMessage: successMessage,
        submitNavigateProductId: navigateProductId,
      ),
    );
    _applyNonUaeBookingDefault();
  }

  RequestFulfillmentType? _requestFulfillmentFromProduct(
    MyListingProductModel product,
  ) {
    final id = product.requestTypeId;
    if (id == 1) return RequestFulfillmentType.local;
    if (id == 2) return RequestFulfillmentType.reexport;

    final fromName = RequestFulfillmentType.fromApiValue(product.requestTypeName);
    if (fromName != null) return fromName;

    return RequestFulfillmentType.fromApiValue(product.shippingDescriptionEn);
  }

  void _emitPublishStep(CreateAdPublishStep step, {int? videoPercent}) {
    if (isClosed) return;
    emit(
      state.copyWith(
        publishStep: step,
        publishVideoPercent: videoPercent ?? state.publishVideoPercent,
      ),
    );
  }

  void _emitSubmitFailure(String message) {
    if (isClosed) return;
    emit(
      state.copyWith(
        isSubmitting: false,
        publishStep: CreateAdPublishStep.idle,
        publishVideoPercent: 0,
        submitErrorMessage: message,
        clearSubmitSuccessMessage: true,
      ),
    );
  }

  Future<String?> _uploadAssetsAfterProductCreated({
    required String productId,
    required String token,
    List<String>? imagePathsOverride,
    List<String>? documentPathsOverride,
    bool? skipDocuments,
  }) async {
    final skipDocs = skipDocuments ??
        (state.selectedType == CreateAdType.categories.label);
    final imagePaths = imagePathsOverride ??
        CreateAdFormMapper.imagePathsForUpload(
          productImages: state.productImages,
          productDocuments: skipDocs ? const [] : state.productDocuments,
        );
    if (imagePaths.isNotEmpty) {
      final imagesResult = await _uploadProductImagesUseCase(
        productId: productId,
        filePaths: imagePaths,
        token: token,
      );
      final imagesError = imagesResult.fold<String?>(
        (failure) => failure.message,
        (_) => null,
      );
      if (imagesError != null) return imagesError;
    }

    if (skipDocs) return null;

    final documentPaths = documentPathsOverride ??
        CreateAdFormMapper.documentPathsForUpload(
          productDocuments: state.productDocuments,
        );
    if (documentPaths.isNotEmpty) {
      final documentsResult = await _uploadProductDocumentsUseCase(
        productId: productId,
        filePaths: documentPaths,
        token: token,
      );
      final documentsError = documentsResult.fold<String?>(
        (failure) => failure.message,
        (_) => null,
      );
      if (documentsError != null) return documentsError;
    }

    return null;
  }

  Future<
    ({
      String originCountry,
      String destinationCountry,
      String loadingPort,
      String arrivalPort,
    })?
  >
  _resolveUserGeoForSubmit() async {
    final originCountry = state.originCountry;
    final loadingPort = state.originPort;
    final destinationCountry = state.destinationCountry;
    final arrivalPort = state.destinationPort;

    if ([
      originCountry,
      loadingPort,
      destinationCountry,
      arrivalPort,
    ].any((value) => value == null || value.isEmpty)) {
      return null;
    }

    return (
      originCountry: originCountry!,
      destinationCountry: destinationCountry!,
      loadingPort: loadingPort!,
      arrivalPort: arrivalPort!,
    );
  }

  Future<String?> _showPickSourceSheet(
    BuildContext context, {
    required bool includeFiles,
  }) {
    return showModalBottomSheet<String>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Gallery'),
                onTap: () => Navigator.pop(context, 'gallery'),
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined),
                title: const Text('Camera'),
                onTap: () => Navigator.pop(context, 'camera'),
              ),
              if (includeFiles)
                ListTile(
                  leading: const Icon(Icons.folder_outlined),
                  title: const Text('Files'),
                  onTap: () => Navigator.pop(context, 'files'),
                ),
            ],
          ),
        );
      },
    );
  }

  Future<List<String>> _pickPathsRaw({
    required BuildContext context,
    required String choice,
    required bool documentMode,
  }) async {
    final pickedPaths = <String>[];

    if (choice == 'gallery') {
      final images = await _imagePicker.pickMultiImage();
      pickedPaths.addAll(images.map((image) => image.path).whereType<String>());
    } else if (choice == 'camera') {
      final image = await _imagePicker.pickImage(source: ImageSource.camera);
      if (image?.path != null) pickedPaths.add(image!.path);
    } else if (choice == 'files') {
      final result = await FilePicker.pickFiles(
        allowMultiple: true,
        type: FileType.custom,
        allowedExtensions: documentMode
            ? const [
                'jpg',
                'jpeg',
                'png',
                'pdf',
                'doc',
                'docx',
                'xls',
                'xlsx',
                'ppt',
                'pptx',
              ]
            : const ['jpg', 'jpeg', 'png', 'mp4', 'mov'],
      );
      if (result != null) {
        for (final file in result.files) {
          if (file.path != null) pickedPaths.add(file.path!);
        }
      }
    }

    return pickedPaths;
  }

  Future<List<String>> _finalizePickedPaths({
    required BuildContext context,
    required List<String> rawPaths,
  }) async {
    final mapped = await _finalizePickedPathsMapped(
      context: context,
      rawPaths: rawPaths,
    );
    return [
      for (final raw in rawPaths)
        if (mapped[raw] != null && mapped[raw]!.isNotEmpty) mapped[raw]!,
    ];
  }

  /// Persists picks in parallel and soft-validates video duration.
  /// Maps each successful raw gallery path → durable app-documents path.
  Future<Map<String, String>> _finalizePickedPathsMapped({
    required BuildContext context,
    required List<String> rawPaths,
  }) async {
    if (rawPaths.isEmpty) return const {};

    final results = await Future.wait(
      List.generate(rawPaths.length, (i) async {
        final raw = rawPaths[i];
        final persistedPath = await _persistPickedFile(raw, index: i);
        if (persistedPath == null) return MapEntry(raw, '');

        if (CreateAdFormMapper.isVideoPath(persistedPath)) {
          final durationError = await CreateAdFormMapper.validateVideoDuration(
            persistedPath,
            tooLongMessage: S.current.videoMaxDurationSeconds,
            unreadableMessage: S.current.videoDurationUnreadable,
          );
          if (durationError != null) {
            if (context.mounted) {
              AppToast.showError(context, durationError);
            }
            return MapEntry(raw, '');
          }
        }
        return MapEntry(raw, persistedPath);
      }),
    );

    return {
      for (final entry in results)
        if (entry.value.isNotEmpty) entry.key: entry.value,
    };
  }

  /// Android image_picker often returns scaled temp files under /cache that
  /// can be deleted before upload — copy picks into app documents first.
  Future<String?> _persistPickedFile(String sourcePath, {int index = 0}) async {
    try {
      final source = File(sourcePath);
      if (!await source.exists()) {
        debugPrint('[CreateAd] Picked file missing: $sourcePath');
        return null;
      }

      if (sourcePath.contains('/create_ad_assets/')) {
        return sourcePath;
      }

      final docsDir = await getApplicationDocumentsDirectory();
      final assetsDir = Directory('${docsDir.path}/create_ad_assets');
      if (!await assetsDir.exists()) {
        await assetsDir.create(recursive: true);
      }

      final originalName = sourcePath.split('/').last;
      final uniqueName =
          '${DateTime.now().millisecondsSinceEpoch}_${index}_$originalName';
      final destPath = '${assetsDir.path}/$uniqueName';
      await source.copy(destPath);
      return destPath;
    } catch (e) {
      debugPrint('[CreateAd] Failed to persist picked file ($sourcePath): $e');
      return null;
    }
  }

  void _debugLogCreateAdPayload({
    required CreateAdProductRequest request,
    required List<String> imagePaths,
    required List<String> documentPaths,
  }) {
    debugPrint('========== [CreateAd] Submit Payload ==========');
    debugPrint('--- Product Request ---');
    debugPrint('NameEn: ${request.nameEn}');
    debugPrint('USDPrice: ${request.usdPrice}');
    debugPrint('Currency: ${request.currency}');
    debugPrint('Quantity: ${request.quantity}');
    debugPrint('DescriptionEn: ${request.descriptionEn}');
    debugPrint('ProductTypeName: ${request.productTypeName}');
    debugPrint('UnitName: ${request.unitName}');
    debugPrint('CategoryId: ${request.categoryId}');
    debugPrint(
      'CategoryLabel: ${state.selectedCategory}',
    );
    debugPrint('Negotiable: ${request.negotiable}');
    debugPrint('DiscountPercentage: ${request.discountPercentage}');
    debugPrint('DiscountDays: ${request.discountDays}');
    debugPrint('SupplierNotesEn: ${request.supplierNotesEn}');
    debugPrint('ShippingDuration: ${request.shippingDuration}');
    debugPrint('AddressId: ${request.addressId}');
    debugPrint('AddressLabel: ${request.address}');
    debugPrint(
      'ProductVideoFile: ${request.productVideoFile?.path ?? '(none)'}',
    );
    debugPrint('VideoDurationSeconds: ${request.videoDurationSeconds ?? 0}');
    debugPrint('--- Geo ---');
    debugPrint('OriginCountryName: ${request.originCountryName}');
    debugPrint('DestinationCountryName: ${request.destinationCountryName}');
    debugPrint('LoadingPortName: ${request.loadingPortName}');
    debugPrint('ArrivalPortName: ${request.arrivalPortName}');
    debugPrint('--- Form State ---');
    debugPrint('SelectedType: ${state.selectedType}');
    debugPrint('SelectedUnit: ${state.selectedUnit}');
    debugPrint('NegotiationType: ${state.negotiationType}');
    debugPrint('BeforeDiscount: ${beforeDiscountController.text.trim()}');
    debugPrint('AfterDiscount: ${afterDiscountController.text.trim()}');
    debugPrint('Price: ${priceController.text.trim()}');
    debugPrint('EnableRetailPricing: ${request.enableRetailPricing}');
    debugPrint('RetailPrice: ${request.retailPrice}');
    debugPrint('RetailUnitName: ${request.retailUnitName}');
    debugPrint('RetailQuantity: ${request.retailQuantity}');
    debugPrint('--- Assets (uploaded after product creation) ---');
    debugPrint('ImagePaths (${imagePaths.length}): $imagePaths');
    debugPrint('DocumentPaths (${documentPaths.length}): $documentPaths');
    debugPrint('AllProductImages: ${state.productImages}');
    debugPrint('AllProductDocuments: ${state.productDocuments}');
    debugPrint('=================================================');
  }

  void _appendUniquePaths({
    required List<String> current,
    required List<String> picked,
    required ValueChanged<List<String>> onUpdate,
  }) {
    final updated = List<String>.from(current);
    for (final path in picked) {
      if (!updated.contains(path)) updated.add(path);
    }

    final videos =
        updated.where(CreateAdFormMapper.isVideoPath).toList(growable: false);
    if (videos.length > CreateAdFormMapper.maxProductVideos) {
      updated.removeWhere(CreateAdFormMapper.isVideoPath);
      updated.addAll(videos.take(CreateAdFormMapper.maxProductVideos));
      emit(
        state.copyWith(
          submitErrorMessage: S.current.maxProductVideosExceeded(
            CreateAdFormMapper.maxProductVideos,
          ),
          clearSubmitSuccessMessage: true,
        ),
      );
    }

    final imagePaths = updated
        .where((path) => !CreateAdFormMapper.isVideoPath(path))
        .toList(growable: false);
    if (imagePaths.length > CreateAdFormMapper.maxProductImages) {
      final keptImages =
          imagePaths.take(CreateAdFormMapper.maxProductImages).toList();
      final keptVideos = videos.take(CreateAdFormMapper.maxProductVideos).toList();
      updated
        ..clear()
        ..addAll(keptImages)
        ..addAll(keptVideos);
      emit(
        state.copyWith(
          submitErrorMessage: S.current.maxProductImagesExceeded,
          clearSubmitSuccessMessage: true,
        ),
      );
    }

    onUpdate(updated);
  }

  Future<String?> _uploadLocalVideos({
    required String productId,
    required List<String> localVideoPaths,
    required String token,
  }) async {
    if (localVideoPaths.isEmpty) return null;

    _emitPublishStep(CreateAdPublishStep.preparingVideo, videoPercent: 0);
    final compressedVideos =
        await _ensureLocalMediaReadyForUpload(localVideoPaths);

    for (final compressedVideo in compressedVideos) {
      if (compressedVideo.isEmpty) {
        return S.current.videoCompressFailed(
          CreateAdFormMapper.maxProductVideoSizeMb,
        );
      }

      final sizeError =
          await CreateAdFormMapper.validateVideoFile(compressedVideo);
      if (sizeError != null) {
        return sizeError;
      }

      final videoDurationSeconds =
          await VideoCompressor.readDurationSecondsRounded(
        compressedVideo,
        maxSeconds: CreateAdFormMapper.maxProductVideoDurationSeconds,
      );
      if (videoDurationSeconds < 1) {
        return S.current.videoDurationUnreadable;
      }

      _emitPublishStep(CreateAdPublishStep.uploadingVideo);
      final uploadResult = await _uploadProductVideoUseCase(
        productId: productId,
        filePath: compressedVideo,
        videoDurationSeconds: videoDurationSeconds,
        token: token,
      );
      final uploadError = uploadResult.fold<String?>(
        (failure) => failure.message,
        (_) => null,
      );
      if (uploadError != null) {
        return uploadError;
      }
    }

    return null;
  }

  /// Persist + compress newly picked media in the background so Publish stays
  /// gated on success without freezing the form while the user reviews fields.
  Future<void> _preparePickedMediaInBackground({
    required BuildContext context,
    required List<String> rawPaths,
    required bool forDocuments,
  }) async {
    _activeMediaPrepJobs++;
    emit(
      state.copyWith(
        isCompressingMedia: true,
        mediaCompressionProgress: 0,
        mediaCompressionLabel: S.current.adUploadProgressCompressingImages,
      ),
    );

    try {
      final persistedByRaw = await _finalizePickedPathsMapped(
        context: context,
        rawPaths: rawPaths,
      );
      if (isClosed) return;

      void replaceInList({
        required List<String> current,
        required void Function(List<String> next) emitList,
      }) {
        final next = <String>[];
        for (final path in current) {
          if (persistedByRaw.containsKey(path)) {
            final mapped = persistedByRaw[path]!;
            if (mapped.isNotEmpty) next.add(mapped);
            continue;
          }
          if (rawPaths.contains(path)) continue;
          next.add(path);
        }
        emitList(next);
      }

      if (forDocuments) {
        replaceInList(
          current: state.productDocuments,
          emitList: (paths) {
            _uploadReadyLocalPaths.addAll(
              paths.where((p) => !CreateAdFormMapper.isRemoteAssetPath(p)),
            );
            emit(state.copyWith(productDocuments: paths));
          },
        );
        return;
      }

      replaceInList(
        current: state.productImages,
        emitList: (paths) => emit(state.copyWith(productImages: paths)),
      );

      final toCompress = state.productImages
          .where(
            (p) =>
                !CreateAdFormMapper.isRemoteAssetPath(p) &&
                !_uploadReadyLocalPaths.contains(p) &&
                (MediaCompressionService.isImagePath(p) ||
                    MediaCompressionService.isVideoPath(p)),
          )
          .toList();

      if (toCompress.isEmpty) return;

      final compressed = await MediaCompressionService.prepareAdMediaMany(
        toCompress,
        onFraction: (fraction) {
          if (isClosed) return;
          emit(
            state.copyWith(
              isCompressingMedia: true,
              mediaCompressionProgress: fraction,
              mediaCompressionLabel:
                  S.current.adUploadProgressCompressingImages,
            ),
          );
        },
      );
      if (isClosed) return;

      final bySource = <String, String>{};
      for (var i = 0; i < toCompress.length; i++) {
        final out = compressed[i];
        if (out.isEmpty) continue;
        bySource[toCompress[i]] = out;
        _uploadReadyLocalPaths.add(out);
      }

      final failed = toCompress.where((p) => !bySource.containsKey(p)).toList();
      final updated = <String>[];
      for (final path in state.productImages) {
        if (bySource.containsKey(path)) {
          updated.add(bySource[path]!);
          continue;
        }
        if (failed.contains(path)) continue;
        updated.add(path);
      }

      if (failed.isNotEmpty && context.mounted) {
        AppToast.showError(
          context,
          S.current.adUploadProgressCompressingImages,
        );
      }

      emit(
        state.copyWith(
          productImages: updated,
          mediaCompressionProgress: 1,
        ),
      );
    } finally {
      _activeMediaPrepJobs =
          (_activeMediaPrepJobs - 1).clamp(0, 1000);
      if (!isClosed && _activeMediaPrepJobs == 0) {
        emit(
          state.copyWith(
            isCompressingMedia: false,
            mediaCompressionProgress: 0,
            clearMediaCompressionLabel: true,
          ),
        );
      }
    }
  }

  /// Prefer already-compressed local paths; compress any leftovers in parallel.
  Future<List<String>> _ensureLocalMediaReadyForUpload(
    List<String> paths,
  ) async {
    if (paths.isEmpty) return const [];

    final results = List<String>.from(paths);
    final pendingIndexes = <int>[];
    for (var i = 0; i < paths.length; i++) {
      final path = paths[i];
      if (CreateAdFormMapper.isRemoteAssetPath(path) ||
          _uploadReadyLocalPaths.contains(path) ||
          (!MediaCompressionService.isImagePath(path) &&
              !MediaCompressionService.isVideoPath(path))) {
        continue;
      }
      pendingIndexes.add(i);
    }

    if (pendingIndexes.isEmpty) return results;

    emit(
      state.copyWith(
        isCompressingMedia: true,
        mediaCompressionProgress: 0,
        mediaCompressionLabel: S.current.adUploadProgressCompressingImages,
      ),
    );
    final pendingPaths = [for (final i in pendingIndexes) paths[i]];
    final compressed = await MediaCompressionService.prepareAdMediaMany(
      pendingPaths,
      onFraction: (fraction) {
        if (isClosed) return;
        emit(
          state.copyWith(
            isCompressingMedia: true,
            mediaCompressionProgress: fraction,
            mediaCompressionLabel: S.current.adUploadProgressCompressingImages,
          ),
        );
      },
    );
    for (var j = 0; j < pendingIndexes.length; j++) {
      final out = compressed[j];
      results[pendingIndexes[j]] = out;
      if (out.isNotEmpty) _uploadReadyLocalPaths.add(out);
    }
    if (!isClosed) {
      emit(
        state.copyWith(
          isCompressingMedia: false,
          mediaCompressionProgress: 0,
          clearMediaCompressionLabel: true,
        ),
      );
    }
    return results;
  }

  @override
  Future<void> close() {
    productNameController.dispose();
    quantityController.dispose();
    specificationsController.dispose();
    packingKgController.dispose();
    retailSpecificationsController.dispose();
    retailPackingKgController.dispose();
    beforeDiscountController.dispose();
    afterDiscountController.dispose();
    priceController.dispose();
    retailPriceController.dispose();
    retailQuantityController.dispose();
    shippingDurationController.dispose();
    originCountryController.dispose();
    destinationCountryController.dispose();
    return super.close();
  }
}
