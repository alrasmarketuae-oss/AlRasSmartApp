import 'dart:async';
import 'dart:io';

import 'package:alrasmarket/core/search/search_history_entry.dart';
import 'package:alrasmarket/core/search/user_search_history_service.dart';
import 'package:alrasmarket/core/media/image_compressor.dart';
import 'package:alrasmarket/core/media/image_source_picker.dart';
import 'package:alrasmarket/core/error/failure.dart';
import 'package:alrasmarket/core/constants/uae_retail_emirates.dart';
import 'package:alrasmarket/core/cache/api_cache_keys.dart';
import 'package:alrasmarket/core/cache/api_cache_store.dart';
import 'package:alrasmarket/core/cache/product_list_cache.dart';
import 'package:alrasmarket/core/services/api_constants.dart';
import 'package:alrasmarket/core/services/dio_helper.dart';
import 'package:alrasmarket/core/serveses/auth_service.dart';
import 'package:alrasmarket/core/utils/localized_product_text.dart';
import 'package:alrasmarket/core/utils/thousands_separator_input_formatter.dart';
import 'package:alrasmarket/features/clint/presentation/helpers/product_ownership_helper.dart';
import 'package:alrasmarket/core/services_locator/services_locator.dart';
import 'package:alrasmarket/core/usecase/base_usecase.dart';
import 'package:alrasmarket/features/company/presentation/controller/cubit/company_cubit.dart';

import 'package:alrasmarket/features/clint/data/models/category_model.dart';
import 'package:alrasmarket/features/clint/data/models/client_address_model.dart';
import 'package:alrasmarket/features/clint/data/models/domestic_emirate_model.dart';
import 'package:alrasmarket/features/clint/domain/usecases/address_usecases.dart';
import 'package:alrasmarket/features/clint/domain/entities/banner_adds.dart';
import 'package:alrasmarket/features/clint/domain/entities/cart_entity.dart';
import 'package:alrasmarket/features/clint/domain/entities/cart_item_entity.dart';
import 'package:alrasmarket/features/clint/domain/entities/cart_payment_method.dart';
import 'package:alrasmarket/features/clint/domain/usecases/add_cart_item_usecase.dart';
import 'package:alrasmarket/features/clint/domain/usecases/confirm_cart_order_usecase.dart';
import 'package:alrasmarket/features/clint/domain/usecases/payment_usecases.dart';
import 'package:alrasmarket/features/clint/data/models/create_order_request.dart';
import 'package:alrasmarket/features/clint/data/models/international_shipping_post_model.dart';
import 'package:alrasmarket/features/clint/data/models/my_order_model.dart';
import 'package:alrasmarket/features/clint/domain/usecases/get_cart_usecase.dart';
import 'package:alrasmarket/features/clint/domain/usecases/get_home_banners_usecase.dart';
import 'package:alrasmarket/features/clint/domain/usecases/get_categories_usecase.dart';
import 'package:alrasmarket/features/clint/domain/usecases/order_usecases.dart';
import 'package:alrasmarket/features/company/domain/usecases/ad_offers_usecases.dart';
import 'package:alrasmarket/features/clint/domain/usecases/reduce_cart_item_quantity_usecase.dart';
import 'package:alrasmarket/features/clint/domain/usecases/remove_cart_item_usecase.dart';
import 'package:alrasmarket/features/company/data/models/my_listing_product_model.dart';
import 'package:alrasmarket/features/company/domain/usecases/get_geo_usecases.dart';
import 'package:alrasmarket/features/company/presentation/helpers/create_ad_form_mapper.dart';
import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:alrasmarket/features/clint/presentation/views/stripe_checkout_webview.dart';
import 'package:alrasmarket/features/clint/presentation/models/service_product_type.dart';
import 'package:alrasmarket/features/clint/presentation/widgets/track_order_widgets/track_order_status_helper.dart';
import 'package:alrasmarket/core/utils/product_price_formatter.dart';
import 'package:alrasmarket/core/utils/product_quantity_validator.dart';
import 'package:alrasmarket/core/utils/user_facing_error_localizer.dart';
import 'package:alrasmarket/generated/l10n.dart';
import 'clint_states.dart';

class ClintCubit extends Cubit<ClintStates> {
  ClintCubit({
    required GetHomeBannersUseCase getHomeBannersUseCase,
    required GetCategoriesUseCase getCategoriesUseCase,
    required GetCartUseCase getCartUseCase,
    required AddCartItemUseCase addCartItemUseCase,
    required RemoveCartItemUseCase removeCartItemUseCase,
    required ReduceCartItemQuantityUseCase reduceCartItemQuantityUseCase,
    required ConfirmCartOrderUseCase confirmCartOrderUseCase,
    required CreateStripeCheckoutUseCase createStripeCheckoutUseCase,
    required GetCheckoutStatusUseCase getCheckoutStatusUseCase,
    required UploadOrderImageUseCase uploadOrderImageUseCase,
    required UploadOrderVideoUseCase uploadOrderVideoUseCase,
    required UploadOrderDocumentUseCase uploadOrderDocumentUseCase,
    required CreateOrderUseCase createOrderUseCase,
    required GetMyOrdersUseCase getMyOrdersUseCase,
    required GetMyOffersUseCase getMyOffersUseCase,
    required GetOrderByIdUseCase getOrderByIdUseCase,
    required UpdateOrderStatusUseCase updateOrderStatusUseCase,
    required RequestOrderReturnUseCase requestOrderReturnUseCase,
    required GetGeoPortsByCountryUseCase getGeoPortsByCountryUseCase,
    required GetClientAddressesUseCase getClientAddressesUseCase,
  }) : _getHomeBannersUseCase = getHomeBannersUseCase,
       _getCategoriesUseCase = getCategoriesUseCase,
       _getCartUseCase = getCartUseCase,
       _addCartItemUseCase = addCartItemUseCase,
       _removeCartItemUseCase = removeCartItemUseCase,
       _reduceCartItemQuantityUseCase = reduceCartItemQuantityUseCase,
       _confirmCartOrderUseCase = confirmCartOrderUseCase,
       _createStripeCheckoutUseCase = createStripeCheckoutUseCase,
       _getCheckoutStatusUseCase = getCheckoutStatusUseCase,
       _uploadOrderImageUseCase = uploadOrderImageUseCase,
       _uploadOrderVideoUseCase = uploadOrderVideoUseCase,
       _uploadOrderDocumentUseCase = uploadOrderDocumentUseCase,
       _createOrderUseCase = createOrderUseCase,
       _getMyOrdersUseCase = getMyOrdersUseCase,
       _getMyOffersUseCase = getMyOffersUseCase,
       _getOrderByIdUseCase = getOrderByIdUseCase,
       _updateOrderStatusUseCase = updateOrderStatusUseCase,
       _requestOrderReturnUseCase = requestOrderReturnUseCase,
       _getGeoPortsByCountryUseCase = getGeoPortsByCountryUseCase,
       _getClientAddressesUseCase = getClientAddressesUseCase,
       super(ClintInitialState());

  final GetHomeBannersUseCase _getHomeBannersUseCase;
  final GetCategoriesUseCase _getCategoriesUseCase;
  final GetCartUseCase _getCartUseCase;
  final AddCartItemUseCase _addCartItemUseCase;
  final RemoveCartItemUseCase _removeCartItemUseCase;
  final ReduceCartItemQuantityUseCase _reduceCartItemQuantityUseCase;
  final ConfirmCartOrderUseCase _confirmCartOrderUseCase;
  final CreateStripeCheckoutUseCase _createStripeCheckoutUseCase;
  final GetCheckoutStatusUseCase _getCheckoutStatusUseCase;
  final UploadOrderImageUseCase _uploadOrderImageUseCase;
  final UploadOrderVideoUseCase _uploadOrderVideoUseCase;
  final UploadOrderDocumentUseCase _uploadOrderDocumentUseCase;
  final CreateOrderUseCase _createOrderUseCase;
  final GetMyOrdersUseCase _getMyOrdersUseCase;
  final GetMyOffersUseCase _getMyOffersUseCase;
  final GetOrderByIdUseCase _getOrderByIdUseCase;
  final UpdateOrderStatusUseCase _updateOrderStatusUseCase;
  final RequestOrderReturnUseCase _requestOrderReturnUseCase;
  final GetGeoPortsByCountryUseCase _getGeoPortsByCountryUseCase;
  final GetClientAddressesUseCase _getClientAddressesUseCase;

  Timer? _paymentPollTimer;
  int _paymentPollAttempts = 0;
  static const int _maxPaymentPollAttempts = 40;

  static ClintCubit get(BuildContext context) =>
      BlocProvider.of<ClintCubit>(context);

  int currentIndex = 0;

  List<BannerAdds> homeBanners = [];
  bool isLoadingHomeBanners = true;
  String? homeBannersError;

  List<CategoryModel> categories = [];
  bool isLoadingCategories = false;
  String? categoriesError;

  static const int homeFeedPageSize = 20;
  static const int homeFeedLoadMoreThreshold = 10;

  List<MyListingProductModel> homeProducts = [];
  bool isLoadingHomeProducts = false;
  bool isLoadingMoreHomeProducts = false;
  String? homeProductsError;
  int homeProductsPage = 1;
  int homeProductsTotalPages = 1;

  bool get hasMoreHomeProducts => homeProductsPage < homeProductsTotalPages;

  List<MyListingProductModel> featuredProducts = [];
  bool isLoadingFeaturedProducts = false;
  String? featuredProductsError;

  final Map<String, _ProductsByTypeBucket> _productsByType = {
    for (final type in ServiceProductType.all) type: _ProductsByTypeBucket(),
  };

  List<MyListingProductModel> productsForType(String productType) =>
      _productsByType[productType]?.items ?? const [];

  bool isLoadingProductsForType(String productType) =>
      _productsByType[productType]?.isLoading ?? false;

  String? productsErrorForType(String productType) =>
      _productsByType[productType]?.error;

  List<MyListingProductModel> get requestsProducts =>
      productsForType(ServiceProductType.requests);

  List<MyListingProductModel> get bookingProducts =>
      productsForType(ServiceProductType.booking);

  List<MyListingProductModel> get offersProducts =>
      productsForType(ServiceProductType.offers);

  List<MyListingProductModel> get retailProducts =>
      productsForType(ServiceProductType.retail)
          .where((item) => item.isRetailFeedProduct)
          .toList(growable: false);

  bool isLoadingMoreProductsForType(String productType) =>
      _productsByType[productType]?.isLoadingMore ?? false;

  bool hasMoreProductsForType(String productType) {
    final bucket = _productsByType[productType];
    if (bucket == null) return false;
    return bucket.page < bucket.totalPages;
  }

  bool get isLoadingMoreRetailProducts =>
      isLoadingMoreProductsForType(ServiceProductType.retail);

  bool get hasMoreRetailProducts =>
      hasMoreProductsForType(ServiceProductType.retail);

  bool get isLoadingRequestsProducts =>
      isLoadingProductsForType(ServiceProductType.requests);

  bool get isLoadingBookingProducts =>
      isLoadingProductsForType(ServiceProductType.booking);

  bool get isLoadingOffersProducts =>
      isLoadingProductsForType(ServiceProductType.offers);

  bool get isLoadingRetailProducts =>
      isLoadingProductsForType(ServiceProductType.retail);

  List<MyOrderModel> myOrders = [];
  bool isLoadingMyOrders = false;
  String? myOrdersError;
  int myOrdersTotalCount = 0;
  int myOrdersTotalPages = 0;

  List<MyOrderModel> myOffers = [];
  bool isLoadingMyOffers = false;
  String? myOffersError;
  int myOffersTotalCount = 0;
  int myOffersTotalPages = 0;

  List<MyListingProductModel> categoryProducts = [];
  bool isLoadingCategoryProducts = false;
  String? categoryProductsError;
  int? activeCategoryId;

  List<InternationalShippingPostModel> shippingPosts = [];
  bool isLoadingShippingPosts = false;
  String? shippingPostsError;

  List<MyListingProductModel> productSearchResults = [];
  String? searchQuery;
  List<String> searchSuggestedNames = [];
  Map<String, dynamic>? searchAiAssist;
  bool isLoadingSearch = false;
  String? searchError;
  bool isImageSearch = false;

  List<DomesticEmirateModel> domesticEmirates = [];
  int excessKgRateAed = 0;
  int freeWeightKg = 10;
  bool isLoadingDomesticEmirates = false;
  List<ClientAddressModel> cartSavedAddresses = [];
  bool isLoadingCartAddresses = false;

  int _homeProductsFetchGeneration = 0;
  int _featuredProductsFetchGeneration = 0;
  int _shippingPostsFetchGeneration = 0;
  int _productSearchFetchGeneration = 0;

  void _emitHomeProductsStateIfLoaded() {
    if (homeProducts.isNotEmpty) {
      emit(FetchHomeProductsSuccessState(List<MyListingProductModel>.from(homeProducts)));
    }
  }

  void _emitFeaturedProductsStateIfLoaded() {
    if (featuredProducts.isNotEmpty) {
      emit(
        FetchFeaturedProductsSuccessState(
          List<MyListingProductModel>.from(featuredProducts),
        ),
      );
    }
  }

  List<MyListingProductModel> _parseHomeProductsResponse(dynamic data) {
    final List<dynamic> items;
    if (data is List<dynamic>) {
      items = data;
    } else if (data is Map<String, dynamic>) {
      items = data['items'] as List<dynamic>? ?? const [];
    } else {
      return const [];
    }

    return items
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .map(_mapPublicProductToListingJson)
        .map(MyListingProductModel.fromJson)
        .toList();
  }

  Map<String, dynamic>? _parseSearchAiAssist(dynamic data) {
    if (data is! Map) return null;
    final raw = data['aiAssist'];
    if (raw is! Map) return null;
    return Map<String, dynamic>.from(raw);
  }

  List<MyListingProductModel> _filterProductsForServiceType(
    List<MyListingProductModel> products,
    String productType,
  ) {
    switch (productType) {
      case ServiceProductType.retail:
        return products
            .where((item) => item.isRetailFeedProduct)
            .toList(growable: false);
      case ServiceProductType.booking:
      case ServiceProductType.offers:
      case ServiceProductType.requests:
        return products
            .where((item) => item.isPureServiceTypeListing)
            .toList(growable: false);
      default:
        return products;
    }
  }

  int _parseTotalPages(
    dynamic data, {
    required int page,
    required int pageSize,
    required int itemsCount,
  }) {
    if (data is Map<String, dynamic>) {
      final totalPages = int.tryParse(data['totalPages']?.toString() ?? '');
      if (totalPages != null && totalPages > 0) return totalPages;

      final totalCount = int.tryParse(data['totalCount']?.toString() ?? '');
      if (totalCount != null && pageSize > 0) {
        final pages = (totalCount / pageSize).ceil();
        return pages < 1 ? 1 : pages;
      }
    }

    if (itemsCount < pageSize) return page;
    return page + 1;
  }

  List<MyListingProductModel> _mergeProducts(
    List<MyListingProductModel> existing,
    List<MyListingProductModel> incoming,
  ) {
    if (existing.isEmpty) return incoming;
    if (incoming.isEmpty) return existing;
    final ids = existing.map((e) => e.productId).toSet();
    return [
      ...existing,
      ...incoming.where((p) => !ids.contains(p.productId)),
    ];
  }

  bool get _isPersonalCustomerAccount =>
      AuthService.instance.isPersonalCustomerAccount;

  /// Guest / company home: CategoryId catalog (wholesale/base).
  /// Personal customer home: retail feed only (Add to cart).
  bool _isCategoryIdHomeProduct(MyListingProductModel item) {
    if (item.categoryId == null || item.categoryId! <= 0) return false;
    // Keep hybrids (category + retail) on home as catalog items.
    if (item.isRetailProduct) return true;
    // Exclude Booking / Offers / Requests.
    return !item.isServiceTypeProduct;
  }

  List<MyListingProductModel> _filterHomeProductsForAccount(
    List<MyListingProductModel> products,
  ) {
    if (_isPersonalCustomerAccount) {
      return products
          .where((item) => item.isRetailFeedProduct)
          .toList(growable: false);
    }
    return products
        .where(_isCategoryIdHomeProduct)
        .toList(growable: false);
  }

  void _applyHomeProductsAccountFilter() {
    homeProducts = _filterHomeProductsForAccount(homeProducts);
  }

  /// Copies the retail by-type bucket into [homeProducts] so HomeView (which
  /// listens to FetchHomeProducts*) shows person retail with Add to cart.
  void _syncHomeProductsFromRetailBucket() {
    final bucket = _productsByType[ServiceProductType.retail];
    if (bucket == null) return;
    homeProducts = _filterHomeProductsForAccount(
      List<MyListingProductModel>.from(bucket.items),
    );
    homeProductsPage = bucket.page;
    homeProductsTotalPages = bucket.totalPages;
    homeProductsError = bucket.error;
    isLoadingHomeProducts = bucket.isLoading;
    isLoadingMoreHomeProducts = bucket.isLoadingMore;
    if (bucket.error != null && homeProducts.isEmpty) {
      emit(FetchHomeProductsErrorState(bucket.error!));
      return;
    }
    emit(FetchHomeProductsSuccessState(List.from(homeProducts)));
  }

  /// Clears in-memory home/retail feed so guest/company never keep a personal
  /// retail list after logout or "continue as guest".
  void clearHomeCatalogMemory() {
    homeProducts = [];
    homeProductsError = null;
    homeProductsPage = 1;
    homeProductsTotalPages = 1;
    isLoadingHomeProducts = false;
    isLoadingMoreHomeProducts = false;
    _lastHomeFeedCompletedAt = null;
    final retailBucket = _productsByType[ServiceProductType.retail];
    if (retailBucket != null) {
      retailBucket.items = [];
      retailBucket.error = null;
      retailBucket.page = 1;
      retailBucket.totalPages = 1;
      retailBucket.isLoading = false;
      retailBucket.isLoadingMore = false;
    }
    emit(ClintInitialState());
  }

  /// Loads the next home-feed page when the user is near the end of the list.
  Future<void> loadMoreHomeFeed({required bool isPerson}) async {
    if (isPerson || _isPersonalCustomerAccount) {
      if (homeProducts.isNotEmpty) {
        isLoadingMoreHomeProducts = true;
        emit(FetchHomeProductsLoadingMoreState());
      }
      await fetchProductsByType(
        ServiceProductType.retail,
        loadMore: true,
      );
      _syncHomeProductsFromRetailBucket();
      return;
    }
    await fetchHomeProducts(loadMore: true);
  }

  void maybeLoadMoreHomeFeed({
    required bool isPerson,
    required int visibleIndex,
    required int totalItems,
  }) {
    if (totalItems == 0) return;
    if (totalItems - visibleIndex > homeFeedLoadMoreThreshold) return;
    unawaited(loadMoreHomeFeed(isPerson: isPerson));
  }

  /// GET /api/Products/search?q=
  Future<void> searchProducts({
    required String query,
    int page = 1,
    int pageSize = 20,
  }) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      searchError = S.current.thisFieldIsRequired;
      emit(ProductSearchErrorState(searchError!));
      return;
    }

    final requestGeneration = ++_productSearchFetchGeneration;
    isLoadingSearch = true;
    searchError = null;
    searchQuery = trimmed;
    isImageSearch = false;
    searchSuggestedNames = [];
    searchAiAssist = null;
    emit(ProductSearchLoadingState(query: trimmed));

    try {
      final response = await DioHelper.getData(
        url: ApiConstants.productsSearchEndPoint,
        query: {'q': trimmed, 'page': page, 'pageSize': pageSize},
      );

      if (requestGeneration != _productSearchFetchGeneration) return;

      final status = response?.statusCode ?? 0;
      if (status < 200 || status >= 300) {
        final message = (response?.data is Map<String, dynamic>)
            ? (response?.data['message']?.toString() ??
                  'Search failed ($status)')
            : 'Search failed ($status)';
        productSearchResults = [];
        searchError = message;
        isLoadingSearch = false;
        emit(ProductSearchErrorState(message));
        return;
      }

      final data = response?.data;
      final products = _parseHomeProductsResponse(data);
      searchAiAssist = _parseSearchAiAssist(data);
      productSearchResults = products;
      isLoadingSearch = false;
      emit(
        ProductSearchSuccessState(
          products: products,
          query: trimmed,
          aiAssist: searchAiAssist,
        ),
      );
      unawaited(_persistTextSearchHistory(trimmed, products));
    } catch (e) {
      if (requestGeneration != _productSearchFetchGeneration) return;
      productSearchResults = [];
      searchAiAssist = null;
      searchError = 'Network error while searching products. ($e)';
      isLoadingSearch = false;
      emit(ProductSearchErrorState(searchError!));
    }
  }

  /// POST /api/Products/detect-by-image
  Future<void> searchProductsByImage(String filePath) async {
    final requestGeneration = ++_productSearchFetchGeneration;
    isLoadingSearch = true;
    searchError = null;
    searchQuery = null;
    isImageSearch = true;
    searchSuggestedNames = [];
    searchAiAssist = null;
    emit(const ProductSearchLoadingState(fromImage: true));

    try {
      final uploadPath = await ImageCompressor.compressToMaxBytes(
            filePath,
            maxBytes: ImageCompressor.searchImageMaxBytes,
          ) ??
          filePath;
      final file = File(uploadPath);
      final formData = FormData.fromMap({
        'File': await MultipartFile.fromFile(
          file.path,
          filename: file.uri.pathSegments.last,
        ),
      });

      final response = await DioHelper.uploadFile(
        url: ApiConstants.productsDetectByImageEndPoint,
        formData: formData,
      );

      if (requestGeneration != _productSearchFetchGeneration) return;

      final status = response?.statusCode ?? 0;
      if (status < 200 || status >= 300) {
        final message = (response?.data is Map<String, dynamic>)
            ? (response?.data['message']?.toString() ??
                  'Image search failed ($status)')
            : 'Image search failed ($status)';
        productSearchResults = [];
        searchError = message;
        isLoadingSearch = false;
        emit(ProductSearchErrorState(message));
        return;
      }

      final data = response?.data;
      List<dynamic> rawItems = const [];
      List<String> apiSuggestedNames = const [];
      if (data is Map<String, dynamic>) {
        apiSuggestedNames = (data['suggestedNames'] as List<dynamic>? ?? [])
            .map((item) => item.toString().trim())
            .where((item) => item.isNotEmpty)
            .toList();

        // Prefer root `items` (flattened detect-by-image), then nested products.items / list.
        final rootItems = data['items'];
        if (rootItems is List<dynamic> && rootItems.isNotEmpty) {
          rawItems = rootItems;
        } else {
          final productsPayload = data['products'];
          if (productsPayload is Map<String, dynamic>) {
            rawItems = productsPayload['items'] as List<dynamic>? ?? const [];
          } else if (productsPayload is List<dynamic>) {
            rawItems = productsPayload;
          } else if (rootItems is List<dynamic>) {
            rawItems = rootItems;
          }
        }
      }

      final products = rawItems
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .map(_mapPublicProductToListingJson)
          .map(MyListingProductModel.fromJson)
          .toList();

      // Prefer localized product names for the current UI language.
      final localizedNames = products
          .map((product) => product.productName.trim())
          .where((name) => name.isNotEmpty)
          .toSet()
          .take(8)
          .toList();
      searchSuggestedNames = localizedNames.isNotEmpty
          ? localizedNames
          : [
              LocalizedProductText.pickUiLabel(apiSuggestedNames),
              ...apiSuggestedNames.skip(1),
            ]
              .map((name) => name.trim())
              .where((name) => name.isNotEmpty)
              .toSet()
              .take(8)
              .toList();

      productSearchResults = products;
      isLoadingSearch = false;
      emit(
        ProductSearchSuccessState(
          products: products,
          suggestedNames: searchSuggestedNames,
          fromImage: true,
        ),
      );
      unawaited(
        _persistImageSearchHistory(
          filePath: uploadPath,
          suggestedNames: searchSuggestedNames,
          products: products,
        ),
      );
    } catch (e) {
      if (requestGeneration != _productSearchFetchGeneration) return;
      productSearchResults = [];
      searchError = 'Network error while searching by image. ($e)';
      isLoadingSearch = false;
      emit(ProductSearchErrorState(searchError!));
    }
  }

  Future<void> pickImageAndSearch(BuildContext context) async {
    final source = await showImageSourceSheet(context);
    if (!context.mounted || source == null) return;
    final imagePath = await pickImageForSearch(source: source);
    if (imagePath == null) return;
    await searchProductsByImage(imagePath);
  }

  /// Replay cached image-search results without calling the AI API again.
  Future<void> restoreSearchFromHistory(String historyId) async {
    final requestGeneration = ++_productSearchFetchGeneration;
    isLoadingSearch = true;
    searchError = null;
    emit(const ProductSearchLoadingState(fromImage: true));

    try {
      final entry =
          await UserSearchHistoryService.instance.getEntryById(historyId);
      if (requestGeneration != _productSearchFetchGeneration) return;

      if (entry == null || !entry.canReplayWithoutApi) {
        productSearchResults = [];
        searchError = S.current.searchHistoryNotFound;
        isLoadingSearch = false;
        emit(ProductSearchErrorState(searchError!));
        return;
      }

      final products = entry.toProductModels();
      productSearchResults = products;
      searchSuggestedNames = products.isNotEmpty
          ? products
              .map((product) => product.productName.trim())
              .where((name) => name.isNotEmpty)
              .toSet()
              .take(8)
              .toList()
          : [
              LocalizedProductText.pickUiLabel(entry.suggestedNames),
              ...entry.suggestedNames.skip(1),
            ]
              .map((name) => name.trim())
              .where((name) => name.isNotEmpty)
              .toSet()
              .take(8)
              .toList();
      searchAiAssist = null;
      searchQuery = entry.label;
      isImageSearch = entry.type == SearchHistoryType.image;
      isLoadingSearch = false;
      emit(
        ProductSearchSuccessState(
          products: products,
          query: entry.label,
          suggestedNames: searchSuggestedNames,
          fromImage: entry.type == SearchHistoryType.image,
        ),
      );
    } catch (e) {
      if (requestGeneration != _productSearchFetchGeneration) return;
      productSearchResults = [];
      searchError = 'Failed to restore search history. ($e)';
      isLoadingSearch = false;
      emit(ProductSearchErrorState(searchError!));
    }
  }

  Future<void> _persistTextSearchHistory(
    String query,
    List<MyListingProductModel> products,
  ) async {
    await UserSearchHistoryService.instance.addEntry(
      type: resolveSearchHistoryType(query),
      label: query,
      query: query,
      products: products.map(productModelToHistoryJson).toList(growable: false),
    );
  }

  Future<void> _persistImageSearchHistory({
    required String filePath,
    required List<String> suggestedNames,
    required List<MyListingProductModel> products,
  }) async {
    if (suggestedNames.isEmpty && products.isEmpty) return;

    final label = suggestedNames.isNotEmpty
        ? suggestedNames.take(3).join(', ')
        : S.current.searchByImage;

    await UserSearchHistoryService.instance.addEntry(
      type: SearchHistoryType.image,
      label: label,
      sourceImagePath: filePath,
      suggestedNames: suggestedNames,
      products: products.map(productModelToHistoryJson).toList(growable: false),
    );
  }

  Future<String?> pickImageForSearch({required ImageSource source}) async {
    final image = await _imagePicker.pickImage(
      source: source,
      imageQuality: 70,
      maxWidth: 1280,
      maxHeight: 1280,
    );
    final path = image?.path;
    if (path == null) return null;

    // Keep image-search uploads under 100 KB for faster / cheaper AI requests.
    return await ImageCompressor.compressToMaxBytes(
          path,
          maxBytes: ImageCompressor.searchImageMaxBytes,
        ) ??
        path;
  }

  void setTab(int index) {
    currentIndex = index;
    emit(ClintTabState(index));
    if (index == 0) {
      refreshHomeFeed(
        // Guests are not personal customers — category catalog only.
        isPerson: AuthService.instance.isPersonalCustomerAccount,
        resetCached: false,
      );
    } else if (index == 3) {
      // My Ads — needed for request owners to review admin-approved offers.
      unawaited(sl<CompanyCubit>().reloadMyListings());
    }
  }

  /// Full catalog refresh after ad create/edit/approval (clears stale prices).
  Future<void> refreshCatalogAfterMutation({required bool isPerson}) async {
    _refreshHomeFeedTimer?.cancel();
    _pendingHomeFeedReset = false;
    _pendingHomeFeedIsPerson = null;
    await _refreshHomeFeedNow(isPerson: isPerson, resetCached: true);
  }

  Future<void> fetchHomeBanners({bool forceRefresh = false}) async {
    if (forceRefresh) {
      await ApiCacheStore.instance.remove(ApiCacheKeys.homeBanners);
    }

    final hadBanners = homeBanners.isNotEmpty;
    if (!hadBanners) {
      await _hydrateHomeBannersFromDisk();
    }

    if (!hadBanners && homeBanners.isEmpty) {
      isLoadingHomeBanners = true;
      homeBannersError = null;
      emit(FetchBannersLoadingState());
    }

    final result = await _getHomeBannersUseCase(const NoParams());

    result.fold(
      (failure) {
        homeBannersError = failure.message;
        if (homeBanners.isEmpty) {
          homeBanners = [];
          isLoadingHomeBanners = false;
          emit(FetchBannersErrorState(failure.message));
        } else {
          isLoadingHomeBanners = false;
          emit(FetchBannersSuccessState(homeBanners));
        }
      },
      (banners) {
        homeBanners = banners;
        homeBannersError = null;
        isLoadingHomeBanners = false;
        emit(FetchBannersSuccessState(banners));
      },
    );
  }

  Future<void> _hydrateHomeBannersFromDisk() async {
    final entry = await ApiCacheStore.instance.read(
      ApiCacheKeys.homeBanners,
      allowStale: true,
    );
    if (entry == null) return;
    try {
      final data = entry.data;
      if (data is! Map<String, dynamic>) return;
      final items = data['items'] as List<dynamic>? ?? [];
      if (items.isEmpty) return;
      homeBanners = items.whereType<Map<String, dynamic>>().map((e) {
        final imageUrl = ApiConstants.resolveMediaUrl(
          (e['imagePath'] ?? '').toString(),
        );
        final link = e['linkUrl']?.toString().trim();
        return BannerAdds(
          bannerId: e['id'] as int? ?? 0,
          imageUrl: imageUrl,
          linkUrl: (link != null && link.isNotEmpty && link != '..' && link != '.')
              ? link
              : null,
          isActive: true,
        );
      }).toList();
      if (homeBanners.isNotEmpty) {
        isLoadingHomeBanners = false;
        emit(FetchBannersSuccessState(homeBanners));
      }
    } catch (_) {}
  }

  /// Loads disk cache for instant home paint (call before first network refresh).
  Future<void> preloadHomeFromDisk({required bool isPerson}) async {
    await Future.wait([
      _hydrateHomeBannersFromDisk(),
      _hydrateCategoriesFromDisk(),
      _hydrateHomeProductsFromDisk(),
    ]);
  }

  Future<void> _hydrateCategoriesFromDisk() async {
    if (categories.isNotEmpty) return;
    final entry = await ApiCacheStore.instance.read(
      ApiCacheKeys.categories,
      allowStale: true,
    );
    if (entry == null) return;
    try {
      final data = Map<String, dynamic>.from(entry.data as Map);
      final raw = data['items'] as List<dynamic>? ?? [];
      categories = raw
          .whereType<Map<String, dynamic>>()
          .map(CategoryModel.fromJson)
          .where((c) => c.categoryId > 0 && c.nameEn.isNotEmpty)
          .toList();
      if (categories.isNotEmpty) {
        isLoadingCategories = false;
        emit(FetchCategoriesSuccessState(categories));
      }
    } catch (_) {}
  }

  Future<void> _hydrateHomeProductsFromDisk() async {
    if (homeProducts.isNotEmpty) return;
    if (_isPersonalCustomerAccount) {
      await _hydrateProductsByTypeFromDisk(
        ServiceProductType.retail,
        pageSize: homeFeedPageSize,
      );
      _syncHomeProductsFromRetailBucket();
      return;
    }
    final cacheKey = ApiCacheKeys.homeProducts(1, homeFeedPageSize);
    final entry = await ApiCacheStore.instance.read(cacheKey, allowStale: true);
    if (entry == null) return;
    try {
      final products = _parseHomeProductsResponse(entry.data);
      if (products.isEmpty) return;
      homeProducts = _filterHomeProductsForAccount(products);
      homeProductsError = null;
      homeProductsPage = 1;
      homeProductsTotalPages = _parseTotalPages(
        entry.data,
        page: 1,
        pageSize: homeFeedPageSize,
        itemsCount: products.length,
      );
      isLoadingHomeProducts = false;
      isLoadingMoreHomeProducts = false;
      emit(FetchHomeProductsSuccessState(List.from(homeProducts)));
    } catch (_) {}
  }

  Future<void> _hydrateFeaturedProductsFromDisk() async {
    if (featuredProducts.isNotEmpty) return;
    await ProductListCache.hydrate(
      cacheKey: ApiCacheKeys.featuredProducts(1, 100),
      parse: _parseHomeProductsResponse,
      apply: (products) {
        featuredProducts = products;
        featuredProductsError = null;
        isLoadingFeaturedProducts = false;
        emit(FetchFeaturedProductsSuccessState(products));
      },
    );
  }

  Future<void> _hydrateProductsByTypeFromDisk(
    String productType, {
    int pageSize = 20,
  }) async {
    final normalizedType = productType.toLowerCase();
    final bucket = _productsByType[normalizedType];
    if (bucket == null || bucket.items.isNotEmpty) return;
    await ProductListCache.hydrate(
      cacheKey: ApiCacheKeys.productsByType(normalizedType, 1, pageSize),
      parse: _parseHomeProductsResponse,
      apply: (products) {
        bucket.items = products;
        bucket.error = null;
        bucket.isLoading = false;
        bucket.isLoadingMore = false;
        bucket.page = 1;
        bucket.pageSize = pageSize;
        bucket.totalPages = products.length < pageSize ? 1 : 2;
        emit(
          FetchProductsByTypeSuccessState(
            productType: normalizedType,
            products: products,
          ),
        );
      },
    );
  }

  Future<void> fetchCategories({bool force = false}) async {
    if (force) {
      await ApiCacheStore.instance.remove(ApiCacheKeys.categories);
    } else if (categories.isNotEmpty) {
      return;
    }

    if (categories.isEmpty) {
      await _hydrateCategoriesFromDisk();
    }
    if (categories.isEmpty) {
      isLoadingCategories = true;
      categoriesError = null;
      emit(FetchCategoriesLoadingState());
    }

    final result = await _getCategoriesUseCase(const GetCategoriesParams());

    result.fold(
      (failure) {
        categoriesError = failure.message;
        categories = [];
        isLoadingCategories = false;
        emit(FetchCategoriesErrorState(failure.message));
      },
      (items) {
        categories = items;
        categoriesError = null;
        isLoadingCategories = false;
        emit(FetchCategoriesSuccessState(items));
      },
    );
  }

  CategoryModel? categoryById(int categoryId) {
    for (final item in categories) {
      if (item.categoryId == categoryId) return item;
    }
    return null;
  }

  CategoryModel? categoryByNameEn(String name) {
    final normalized = name.trim().toLowerCase();
    for (final item in categories) {
      if (item.nameEn.trim().toLowerCase() == normalized) return item;
    }
    return null;
  }

  /// GET /api/Products?page=&pageSize= — all public products.
  Future<void> fetchHomeProducts({
    int page = 1,
    int pageSize = homeFeedPageSize,
    bool forceRefresh = false,
    bool loadMore = false,
  }) async {
    if (loadMore) {
      if (isLoadingMoreHomeProducts || isLoadingHomeProducts) return;
      if (!hasMoreHomeProducts && homeProducts.isNotEmpty) return;
      page = homeProductsPage + 1;
    } else if (page <= 1) {
      homeProductsPage = 1;
      isLoadingMoreHomeProducts = false;
    }

    final cacheKey = ApiCacheKeys.homeProducts(page, pageSize);
    if (forceRefresh && page <= 1) {
      await ApiCacheStore.instance.remove(cacheKey);
    }

    final requestGeneration = ++_homeProductsFetchGeneration;
    final hadCachedProducts = homeProducts.isNotEmpty;
    final isAppend = loadMore || page > 1;

    if (!hadCachedProducts && page == 1) {
      await _hydrateHomeProductsFromDisk();
    }

    if (homeProducts.isEmpty) {
      isLoadingHomeProducts = true;
      homeProductsError = null;
      emit(FetchHomeProductsLoadingState());
    } else if (isAppend) {
      isLoadingMoreHomeProducts = true;
      emit(FetchHomeProductsLoadingMoreState());
    }

    try {
      final response = await DioHelper.getData(
        url: ApiConstants.createProductEndPoint,
        query: {'page': page, 'pageSize': pageSize},
      );

      if (requestGeneration != _homeProductsFetchGeneration) return;

      final status = response?.statusCode ?? 0;
      if (status < 200 || status >= 300) {
        final message = (response?.data is Map<String, dynamic>)
            ? (response?.data['message']?.toString() ??
                  'Failed to load products ($status)')
            : 'Failed to load products ($status)';
        homeProductsError = isAppend ? null : message;
        if (!hadCachedProducts) {
          homeProducts = [];
        }
        isLoadingHomeProducts = false;
        isLoadingMoreHomeProducts = false;
        if (homeProducts.isNotEmpty) {
          _emitHomeProductsStateIfLoaded();
        } else {
          emit(FetchHomeProductsErrorState(message));
        }
        return;
      }

      final data = response?.data;
      if (data is! Map<String, dynamic> && data is! List<dynamic>) {
        homeProductsError = isAppend ? null : 'Invalid products response';
        if (!hadCachedProducts) {
          homeProducts = [];
        }
        isLoadingHomeProducts = false;
        isLoadingMoreHomeProducts = false;
        if (homeProducts.isNotEmpty) {
          _emitHomeProductsStateIfLoaded();
        } else {
          emit(const FetchHomeProductsErrorState('Invalid products response'));
        }
        return;
      }

      final products = _parseHomeProductsResponse(data);
      if (isAppend) {
        if (products.isEmpty) {
          homeProductsTotalPages = homeProductsPage;
        } else {
          homeProducts = _mergeProducts(homeProducts, products);
          homeProductsPage = page;
          homeProductsTotalPages = _parseTotalPages(
            data,
            page: page,
            pageSize: pageSize,
            itemsCount: products.length,
          );
        }
      } else {
        homeProducts = products;
        homeProductsPage = page;
        homeProductsTotalPages = _parseTotalPages(
          data,
          page: page,
          pageSize: pageSize,
          itemsCount: products.length,
        );
      }
      _applyHomeProductsAccountFilter();
      homeProductsError = null;
      isLoadingHomeProducts = false;
      isLoadingMoreHomeProducts = false;
      await ProductListCache.save(cacheKey: cacheKey, rawData: data);
      emit(FetchHomeProductsSuccessState(List.from(homeProducts)));
    } catch (e) {
      if (requestGeneration != _homeProductsFetchGeneration) return;

      if (!isAppend) {
        homeProductsError = 'Network error while loading products.';
      }
      if (!hadCachedProducts) {
        homeProducts = [];
      }
      isLoadingHomeProducts = false;
      isLoadingMoreHomeProducts = false;
      if (homeProducts.isNotEmpty) {
        _emitHomeProductsStateIfLoaded();
      } else {
        emit(
          FetchHomeProductsErrorState(
            'Network error while loading products. ($e)',
          ),
        );
      }
    }
  }

  /// GET /api/Products/featured?page=&pageSize=
  Future<void> fetchFeaturedProducts({
    int page = 1,
    int pageSize = 100,
    bool forceRefresh = false,
  }) async {
    final cacheKey = ApiCacheKeys.featuredProducts(page, pageSize);
    if (forceRefresh) {
      await ApiCacheStore.instance.remove(cacheKey);
    }

    final requestGeneration = ++_featuredProductsFetchGeneration;
    final hadCachedProducts = featuredProducts.isNotEmpty;

    if (!hadCachedProducts && page == 1) {
      await _hydrateFeaturedProductsFromDisk();
    }

    final entry = forceRefresh
        ? null
        : await ApiCacheStore.instance.read(cacheKey);
    if (entry != null && entry.isFresh && featuredProducts.isNotEmpty) {
      // Show cached immediately, then always revalidate from network.
      isLoadingFeaturedProducts = false;
      emit(FetchFeaturedProductsSuccessState(featuredProducts));
    }

    if (featuredProducts.isEmpty) {
      isLoadingFeaturedProducts = true;
      featuredProductsError = null;
      emit(FetchFeaturedProductsLoadingState());
    }

    try {
      print('fetchFeaturedProducts');
      final response = await DioHelper.getData(
        url: ApiConstants.productsFeaturedEndPoint,
        query: {'page': page, 'pageSize': pageSize},
      );

      if (requestGeneration != _featuredProductsFetchGeneration) return;

      final status = response?.statusCode ?? 0;
      if (status < 200 || status >= 300) {
        print('fetchFeaturedProducts error');
        final message = (response?.data is Map<String, dynamic>)
            ? (response?.data['message']?.toString() ??
                  'Failed to load featured products ($status)')
            : 'Failed to load featured products ($status)';
        featuredProductsError = message;
        if (!hadCachedProducts) {
          featuredProducts = [];
        }
        isLoadingFeaturedProducts = false;
        if (featuredProducts.isNotEmpty) {
          print('fetchFeaturedProducts success');
          _emitFeaturedProductsStateIfLoaded();
        } else {
          print('fetchFeaturedProducts error');
          emit(FetchFeaturedProductsErrorState(message));
        }
        return;
      }

      final data = response?.data;
      if (data is! Map<String, dynamic> && data is! List<dynamic>) {
        featuredProductsError = 'Invalid featured products response';
        if (!hadCachedProducts) {
          featuredProducts = [];
        }
        isLoadingFeaturedProducts = false;
        if (featuredProducts.isNotEmpty) {
          _emitFeaturedProductsStateIfLoaded();
        } else {
          emit(const FetchFeaturedProductsErrorState(
            'Invalid featured products response',
          ));
        }
        return;
      }

      final products = _parseHomeProductsResponse(data);
      featuredProducts = products;
      featuredProductsError = null;
      isLoadingFeaturedProducts = false;
      await ProductListCache.save(cacheKey: cacheKey, rawData: data);
      emit(FetchFeaturedProductsSuccessState(products));
    } catch (e) {
      if (requestGeneration != _featuredProductsFetchGeneration) return;

      featuredProductsError = 'Network error while loading featured products.';
      if (!hadCachedProducts) {
        featuredProducts = [];
      }
      isLoadingFeaturedProducts = false;
      if (featuredProducts.isNotEmpty) {
        _emitFeaturedProductsStateIfLoaded();
      } else {
        emit(
          FetchFeaturedProductsErrorState(
            'Network error while loading featured products. ($e)',
          ),
        );
      }
    }
  }

  /// Immediate reload after login — bypasses debounce and clears stale guest data.
  Future<void> reloadHomeAfterAuth({required bool isPerson}) async {
    _refreshHomeFeedTimer?.cancel();
    _pendingHomeFeedReset = false;
    _pendingHomeFeedIsPerson = null;
    _authHomeReloadActive = true;
    try {
      await _refreshHomeFeedNow(isPerson: isPerson, resetCached: true);
    } finally {
      _authHomeReloadActive = false;
    }
  }

  bool _authHomeReloadActive = false;
  DateTime? _lastHomeFeedCompletedAt;

  bool get shouldSkipHomeFeedRefresh {
    if (_authHomeReloadActive) return true;
    final completedAt = _lastHomeFeedCompletedAt;
    if (completedAt == null) return false;
    return DateTime.now().difference(completedAt) < const Duration(seconds: 5);
  }

  Timer? _refreshHomeFeedTimer;
  bool _pendingHomeFeedReset = false;
  bool? _pendingHomeFeedIsPerson;

  /// Reload home feed (banners, categories, products). Call after login or when
  /// [HomeView] was already mounted as a guest.
  void refreshHomeFeed({required bool isPerson, bool resetCached = false}) {
    if (!resetCached && shouldSkipHomeFeedRefresh) return;

    _pendingHomeFeedReset = _pendingHomeFeedReset || resetCached;
    _pendingHomeFeedIsPerson = isPerson;
    _refreshHomeFeedTimer?.cancel();
    _refreshHomeFeedTimer = Timer(const Duration(milliseconds: 200), () {
      if (shouldSkipHomeFeedRefresh && !_pendingHomeFeedReset) return;
      final runIsPerson = _pendingHomeFeedIsPerson ?? isPerson;
      final runReset = _pendingHomeFeedReset;
      _pendingHomeFeedReset = false;
      _pendingHomeFeedIsPerson = null;
      unawaited(_refreshHomeFeedNow(isPerson: runIsPerson, resetCached: runReset));
    });
  }

  Future<void> _refreshHomeFeedNow({
    required bool isPerson,
    bool resetCached = false,
  }) async {
    if (resetCached) {
      await ApiCacheStore.instance.invalidateHomeCatalog();
      homeProductsError = null;
      featuredProductsError = null;
      categoriesError = null;
      for (final bucket in _productsByType.values) {
        bucket.error = null;
      }
    }

    await Future.wait([
      fetchHomeBanners(forceRefresh: resetCached),
      fetchCategories(force: resetCached),
      _loadHomeProducts(isPerson: isPerson, forceRefresh: resetCached),
      fetchMyOrders(),
    ]);

    _lastHomeFeedCompletedAt = DateTime.now();
  }

  /// Personal customer: retail-only home (Add to cart).
  /// Company / guest: category catalog (Purchase order / no prices for guest).
  Future<void> _loadHomeProducts({
    required bool isPerson,
    bool forceRefresh = false,
  }) async {
    if (isPerson || _isPersonalCustomerAccount) {
      if (homeProducts.isEmpty) {
        isLoadingHomeProducts = true;
        homeProductsError = null;
        emit(FetchHomeProductsLoadingState());
      }
      try {
        await fetchProductsByType(
          ServiceProductType.retail,
          forceRefresh: forceRefresh,
        );
      } finally {
        _syncHomeProductsFromRetailBucket();
        // Never leave the home feed stuck in loading (iOS splash / blank home).
        if (isLoadingHomeProducts) {
          isLoadingHomeProducts = false;
          if (homeProducts.isNotEmpty) {
            emit(FetchHomeProductsSuccessState(List.from(homeProducts)));
          } else if (homeProductsError != null) {
            emit(FetchHomeProductsErrorState(homeProductsError!));
          } else {
            emit(FetchHomeProductsSuccessState(const []));
          }
        }
      }
      return;
    }
    await fetchHomeProducts(forceRefresh: forceRefresh);
  }

  /// GET /api/Products/by-type/{type}?page=&pageSize=
  Future<void> fetchProductsByType(
    String productType, {
    int page = 1,
    int pageSize = homeFeedPageSize,
    bool forceRefresh = false,
    bool loadMore = false,
  }) async {
    final normalizedType = productType.toLowerCase();
    final bucket = _productsByType[normalizedType];
    if (bucket == null) return;

    if (loadMore) {
      if (bucket.isLoadingMore || bucket.isLoading) return;
      if (bucket.page >= bucket.totalPages && bucket.items.isNotEmpty) return;
      page = bucket.page + 1;
      pageSize = bucket.pageSize > 0 ? bucket.pageSize : pageSize;
    } else if (page <= 1) {
      bucket.page = 1;
      bucket.isLoadingMore = false;
      bucket.pageSize = pageSize;
    }

    final cacheKey = ApiCacheKeys.productsByType(normalizedType, page, pageSize);
    if (forceRefresh && page <= 1) {
      await ApiCacheStore.instance.remove(cacheKey);
    }

    final requestGeneration = ++bucket.fetchGeneration;
    final hadCachedProducts = bucket.items.isNotEmpty;
    final isAppend = loadMore || page > 1;

    if (!hadCachedProducts && page == 1) {
      await _hydrateProductsByTypeFromDisk(normalizedType, pageSize: pageSize);
    }

    // Always revalidate from network so commission/price changes apply quickly.
    // Disk hydrate above still provides instant UI while the request is in flight.

    if (bucket.items.isEmpty) {
      bucket.isLoading = true;
      bucket.error = null;
      emit(FetchProductsByTypeLoadingState(normalizedType));
    } else if (isAppend) {
      bucket.isLoadingMore = true;
      emit(FetchProductsByTypeLoadingMoreState(normalizedType));
    }

    try {
      final response = await DioHelper.getData(
        url: ApiConstants.productsByTypeEndPoint(normalizedType),
        query: {'page': page, 'pageSize': pageSize},
      );

      if (requestGeneration != bucket.fetchGeneration) return;

      final status = response?.statusCode ?? 0;
      if (status < 200 || status >= 300) {
        final message = (response?.data is Map<String, dynamic>)
            ? (response?.data['message']?.toString() ??
                  'Failed to load products ($status)')
            : 'Failed to load products ($status)';
        bucket.error = isAppend ? null : message;
        if (!hadCachedProducts) {
          bucket.items = [];
        }
        bucket.isLoading = false;
        bucket.isLoadingMore = false;
        if (bucket.items.isNotEmpty) {
          emit(
            FetchProductsByTypeSuccessState(
              productType: normalizedType,
              products: List<MyListingProductModel>.from(bucket.items),
            ),
          );
        } else {
          emit(
            FetchProductsByTypeErrorState(
              productType: normalizedType,
              message: message,
            ),
          );
        }
        return;
      }

      final data = response?.data;
      if (data is! Map<String, dynamic> && data is! List<dynamic>) {
        bucket.error = isAppend ? null : 'Invalid products response';
        if (!hadCachedProducts) {
          bucket.items = [];
        }
        bucket.isLoading = false;
        bucket.isLoadingMore = false;
        if (bucket.items.isNotEmpty) {
          emit(
            FetchProductsByTypeSuccessState(
              productType: normalizedType,
              products: List<MyListingProductModel>.from(bucket.items),
            ),
          );
        } else {
          emit(
            FetchProductsByTypeErrorState(
              productType: normalizedType,
              message: 'Invalid products response',
            ),
          );
        }
        return;
      }

      final products = _filterProductsForServiceType(
        _parseHomeProductsResponse(data),
        normalizedType,
      );
      if (isAppend) {
        if (products.isEmpty) {
          bucket.totalPages = bucket.page;
        } else {
          bucket.items = _mergeProducts(bucket.items, products);
          bucket.page = page;
          bucket.pageSize = pageSize;
          bucket.totalPages = _parseTotalPages(
            data,
            page: page,
            pageSize: pageSize,
            itemsCount: products.length,
          );
        }
      } else {
        bucket.items = products;
        bucket.page = page;
        bucket.pageSize = pageSize;
        bucket.totalPages = _parseTotalPages(
          data,
          page: page,
          pageSize: pageSize,
          itemsCount: products.length,
        );
      }
      bucket.error = null;
      bucket.isLoading = false;
      bucket.isLoadingMore = false;
      await ProductListCache.save(cacheKey: cacheKey, rawData: data);
      emit(
        FetchProductsByTypeSuccessState(
          productType: normalizedType,
          products: List<MyListingProductModel>.from(bucket.items),
        ),
      );
    } catch (e) {
      if (requestGeneration != bucket.fetchGeneration) return;

      if (!isAppend) {
        bucket.error = 'Network error while loading products.';
      }
      if (!hadCachedProducts) {
        bucket.items = [];
      }
      bucket.isLoading = false;
      bucket.isLoadingMore = false;
      if (bucket.items.isNotEmpty) {
        emit(
          FetchProductsByTypeSuccessState(
            productType: normalizedType,
            products: List<MyListingProductModel>.from(bucket.items),
          ),
        );
      } else {
        emit(
          FetchProductsByTypeErrorState(
            productType: normalizedType,
            message: 'Network error while loading products. ($e)',
          ),
        );
      }
    }
  }

  /// POST /api/Orders/{orderId}/return — retail return after delivery.
  Future<MyOrderModel?> requestOrderReturn({
    required int orderId,
    required String reason,
    List<String> mediaPaths = const [],
  }) async {
    final token = AuthService.instance.currentToken;
    if (token == null || token.isEmpty) {
      emit(CancelOrderErrorState(S.current.pleaseLoginToViewYourOrders));
      return null;
    }

    emit(CancelOrderLoadingState(orderId));

    final result = await _requestOrderReturnUseCase(
      RequestOrderReturnParams(
        orderId: orderId,
        reason: reason,
        mediaPaths: mediaPaths,
        token: token,
      ),
    );

    return result.fold(
      (failure) {
        emit(CancelOrderErrorState(failure.message));
        return null;
      },
      (order) {
        final index = myOrders.indexWhere((item) => item.id == order.id);
        if (index >= 0) {
          myOrders[index] = order;
        } else {
          myOrders = [order, ...myOrders];
        }
        emit(RefreshOrderSuccessState(order));
        return order;
      },
    );
  }

  /// PATCH /api/Orders/{orderId}/status with statusId=6 (Cancelled).
  /// For online payments the backend initiates a Stripe refund automatically.
  Future<String?> cancelOrReturnOrder({
    required int orderId,
    required bool isReturn,
  }) async {
    final token = AuthService.instance.currentToken;
    if (token == null || token.isEmpty) {
      emit(CancelOrderErrorState(S.current.pleaseLoginToViewYourOrders));
      return null;
    }

    emit(CancelOrderLoadingState(orderId));

    final result = await _updateOrderStatusUseCase(
      UpdateOrderStatusParams(
        orderId: orderId,
        statusId: OrderStatusCodes.cancelled,
        token: token,
      ),
    );

    return result.fold(
      (failure) {
        emit(CancelOrderErrorState(failure.message));
        return null;
      },
      (refundMessage) async {
        await fetchMyOrders();
        emit(
          CancelOrderSuccessState(
            orderId: orderId,
            refundMessage: refundMessage,
          ),
        );
        return refundMessage;
      },
    );
  }

  /// GET /api/Orders/myOrders?page=&pageSize=
  Future<void> fetchMyOrders({int page = 1, int pageSize = 20}) async {
    final token = AuthService.instance.currentToken;
    if (token == null || token.isEmpty) {
      myOrdersError = S.current.pleaseLoginToViewYourOrders;
      myOrders = [];
      isLoadingMyOrders = false;
      emit(FetchMyOrdersErrorState(S.current.pleaseLoginToViewYourOrders));
      return;
    }

    isLoadingMyOrders = true;
    myOrdersError = null;
    emit(FetchMyOrdersLoadingState());

    final result = await _getMyOrdersUseCase(
      GetMyOrdersParams(page: page, pageSize: pageSize, token: token),
    );

    result.fold(
      (failure) {
        myOrdersError = failure.message;
        myOrders = [];
        myOrdersTotalCount = 0;
        myOrdersTotalPages = 0;
        isLoadingMyOrders = false;
        emit(FetchMyOrdersErrorState(failure.message));
      },
      (pageModel) {
        myOrders = pageModel.items;
        myOrdersTotalCount = pageModel.totalCount;
        myOrdersTotalPages = pageModel.totalPages;
        myOrdersError = null;
        isLoadingMyOrders = false;
        emit(FetchMyOrdersSuccessState(pageModel.items));
      },
    );
  }

  /// GET /api/Orders/myOffers?page=&pageSize=
  Future<void> fetchMyOffers({int page = 1, int pageSize = 20}) async {
    final token = AuthService.instance.currentToken;
    if (token == null || token.isEmpty) {
      myOffersError = S.current.pleaseLoginToViewYourOrders;
      myOffers = [];
      isLoadingMyOffers = false;
      emit(FetchMyOffersErrorState(S.current.pleaseLoginToViewYourOrders));
      return;
    }

    isLoadingMyOffers = true;
    myOffersError = null;
    emit(FetchMyOffersLoadingState());

    final result = await _getMyOffersUseCase(
      GetMyOffersParams(page: page, pageSize: pageSize, token: token),
    );

    result.fold(
      (failure) {
        myOffersError = failure.message;
        myOffers = [];
        myOffersTotalCount = 0;
        myOffersTotalPages = 0;
        isLoadingMyOffers = false;
        emit(FetchMyOffersErrorState(failure.message));
      },
      (pageModel) {
        myOffers = pageModel.items;
        myOffersTotalCount = pageModel.totalCount;
        myOffersTotalPages = pageModel.totalPages;
        myOffersError = null;
        isLoadingMyOffers = false;
        emit(FetchMyOffersSuccessState(pageModel.items));
      },
    );
  }

  /// GET /api/Orders/{orderId} — refresh a single order for live tracking.
  Future<MyOrderModel?> refreshOrderById(int orderId) async {
    final token = AuthService.instance.currentToken;
    if (token == null || token.isEmpty || orderId <= 0) {
      return null;
    }

    final result = await _getOrderByIdUseCase(
      GetOrderByIdParams(orderId: orderId, token: token),
    );

    return result.fold(
      (_) => null,
      (order) {
        final index = myOrders.indexWhere((item) => item.id == order.id);
        if (index >= 0) {
          myOrders[index] = order;
        } else {
          myOrders = [order, ...myOrders];
        }
        emit(RefreshOrderSuccessState(order));
        return order;
      },
    );
  }

  MyOrderModel? _latestMyOrder() {
    if (myOrders.isEmpty) return null;
    return myOrders.reduce((a, b) {
      final aDate =
          DateTime.tryParse(a.createdAt) ??
          DateTime.fromMillisecondsSinceEpoch(0);
      final bDate =
          DateTime.tryParse(b.createdAt) ??
          DateTime.fromMillisecondsSinceEpoch(0);
      return bDate.isAfter(aDate) ? b : a;
    });
  }

  Future<void> _emitNavigateToTrackOrder(int orderId) async {
    MyOrderModel? order;
    for (final item in myOrders) {
      if (item.id == orderId) {
        order = item;
        break;
      }
    }
    order ??= await refreshOrderById(orderId);
    order ??= _latestMyOrder();
    if (order != null) {
      emit(NavigateToTrackOrderState(order: order));
    }
  }

  /// GET /api/Products/by-category/{categoryId}?page=&pageSize=
  Future<void> fetchProductsByCategory({
    required int categoryId,
    int page = 1,
    int pageSize = 20,
    bool forceRefresh = false,
  }) async {
    final switchingCategory =
        activeCategoryId != null && activeCategoryId != categoryId;
    activeCategoryId = categoryId;
    final cacheKey = ApiCacheKeys.productsByCategory(categoryId, page, pageSize);
    if (forceRefresh) {
      await ApiCacheStore.instance.remove(cacheKey);
    }

    if (switchingCategory || page == 1) {
      categoryProducts = [];
      categoryProductsError = null;
    }

    if (categoryProducts.isEmpty && page == 1) {
      await ProductListCache.hydrate(
        cacheKey: cacheKey,
        parse: (data) {
          if (data is! Map) return const <MyListingProductModel>[];
          final map = Map<String, dynamic>.from(data);
          final items = map['items'] as List<dynamic>? ?? const [];
          return items
              .whereType<Map>()
              .map((item) => Map<String, dynamic>.from(item))
              .map(_mapPublicProductToListingJson)
              .map(MyListingProductModel.fromJson)
              .toList();
        },
        apply: (products) {
          categoryProducts = products;
          categoryProductsError = null;
          isLoadingCategoryProducts = false;
          emit(
            FetchCategoryProductsSuccessState(
              categoryId: categoryId,
              products: products,
            ),
          );
        },
      );
    }

    final entry = forceRefresh
        ? null
        : await ApiCacheStore.instance.read(cacheKey);
    if (!forceRefresh &&
        entry != null &&
        entry.isFresh &&
        categoryProducts.isNotEmpty &&
        !switchingCategory) {
      // Show cached immediately, then always revalidate from network.
      isLoadingCategoryProducts = false;
      emit(
        FetchCategoryProductsSuccessState(
          categoryId: categoryId,
          products: categoryProducts,
        ),
      );
    }

    if (categoryProducts.isEmpty) {
      isLoadingCategoryProducts = true;
      categoryProductsError = null;
      emit(FetchCategoryProductsLoadingState(categoryId));
    }

    try {
      final response = await DioHelper.getData(
        url: ApiConstants.productsByCategoryEndPoint(categoryId),
        query: {'page': page, 'pageSize': pageSize},
      );

      final status = response?.statusCode ?? 0;
      if (status < 200 || status >= 300) {
        final message = (response?.data is Map<String, dynamic>)
            ? (response?.data['message']?.toString() ??
                  'Failed to load category products ($status)')
            : 'Failed to load category products ($status)';
        categoryProducts = [];
        categoryProductsError = message;
        isLoadingCategoryProducts = false;
        emit(
          FetchCategoryProductsErrorState(
            categoryId: categoryId,
            message: message,
          ),
        );
        return;
      }

      final data = response?.data;
      if (data is! Map<String, dynamic>) {
        categoryProducts = [];
        categoryProductsError = 'Invalid category products response';
        isLoadingCategoryProducts = false;
        emit(
          FetchCategoryProductsErrorState(
            categoryId: categoryId,
            message: 'Invalid category products response',
          ),
        );
        return;
      }

      final items = data['items'] as List<dynamic>? ?? const [];
      final products = items
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .map(_mapPublicProductToListingJson)
          .map(MyListingProductModel.fromJson)
          .toList();

      categoryProducts = products;
      categoryProductsError = null;
      isLoadingCategoryProducts = false;
      await ProductListCache.save(cacheKey: cacheKey, rawData: data);
      emit(
        FetchCategoryProductsSuccessState(
          categoryId: categoryId,
          products: products,
        ),
      );
    } catch (e) {
      categoryProducts = [];
      categoryProductsError = 'Network error while loading category products.';
      isLoadingCategoryProducts = false;
      emit(
        FetchCategoryProductsErrorState(
          categoryId: categoryId,
          message: 'Network error while loading category products. ($e)',
        ),
      );
    }
  }

  /// GET /api/InternationalShipping/search
  Future<void> fetchShippingPosts({
    String? fromCountryName,
    String? fromPortName,
    String? toCountryName,
    String? toPortName,
  }) async {
    final requestGeneration = ++_shippingPostsFetchGeneration;

    isLoadingShippingPosts = true;
    shippingPostsError = null;
    emit(FetchShippingPostsLoadingState());

    try {
      final query = <String, dynamic>{};
      if (fromCountryName != null && fromCountryName.trim().isNotEmpty) {
        query['fromCountryName'] = fromCountryName.trim();
      }
      if (fromPortName != null && fromPortName.trim().isNotEmpty) {
        query['fromPortName'] = fromPortName.trim();
      }
      if (toCountryName != null && toCountryName.trim().isNotEmpty) {
        query['toCountryName'] = toCountryName.trim();
      }
      if (toPortName != null && toPortName.trim().isNotEmpty) {
        query['toPortName'] = toPortName.trim();
      }

      final response = await DioHelper.getData(
        url: ApiConstants.internationalShippingSearchEndPoint,
        query: query.isEmpty ? null : query,
      );

      if (requestGeneration != _shippingPostsFetchGeneration) return;

      final status = response?.statusCode ?? 0;
      if (status < 200 || status >= 300) {
        final message = (response?.data is Map<String, dynamic>)
            ? (response?.data['message']?.toString() ??
                  'Failed to load shipping posts ($status)')
            : 'Failed to load shipping posts ($status)';
        shippingPosts = [];
        shippingPostsError = message;
        isLoadingShippingPosts = false;
        emit(FetchShippingPostsErrorState(message));
        return;
      }

      final data = response?.data;
      if (data is! List<dynamic>) {
        shippingPosts = [];
        shippingPostsError = 'Invalid shipping posts response';
        isLoadingShippingPosts = false;
        emit(const FetchShippingPostsErrorState('Invalid shipping posts response'));
        return;
      }

      final posts = data
          .whereType<Map<String, dynamic>>()
          .map(InternationalShippingPostModel.fromJson)
          .toList();

      shippingPosts = posts;
      shippingPostsError = null;
      isLoadingShippingPosts = false;
      emit(FetchShippingPostsSuccessState(posts));
    } catch (e) {
      if (requestGeneration != _shippingPostsFetchGeneration) return;

      shippingPosts = [];
      shippingPostsError = 'Network error while loading shipping posts.';
      isLoadingShippingPosts = false;
      emit(
        FetchShippingPostsErrorState(
          'Network error while loading shipping posts. ($e)',
        ),
      );
    }
  }

  Map<String, dynamic> _mapPublicProductToListingJson(
    Map<String, dynamic> json,
  ) {
    final price =
        json['price'] ??
        json['priceAed'] ??
        json['usdPrice'] ??
        json['priceUsd'] ??
        json['USDPrice'];
    final currency = (json['currency'] ?? json['Currency'] ?? 'AED')
        .toString()
        .toUpperCase();

    final localizedName = LocalizedProductText.pickName(json);
    final localizedDescription = LocalizedProductText.pickDescription(json);
    final localizedSupplierNotes = LocalizedProductText.pickSupplierNotes(json);
    final localizedShippingDescription =
        LocalizedProductText.pickShippingDescription(json);
    final localizedOriginCountry =
        LocalizedProductText.pickOriginCountry(json);
    final localizedDestinationCountry =
        LocalizedProductText.pickDestinationCountry(json);
    final localizedLoadingPort = LocalizedProductText.pickLoadingPort(json);
    final localizedArrivalPort = LocalizedProductText.pickArrivalPort(json);

    return {
      'productId': json['productId'],
      'productCode': json['productCode'] ?? json['ProductCode'] ?? '',
      'ownerId': json['ownerId'] ?? '',
      'productName': localizedName.isNotEmpty
          ? localizedName
          : (json['productName'] ?? json['nameEn'] ?? ''),
      'categoryName': json['categoryName'] ?? '',
      'categoryImagePath': json['categoryImagePath'] ?? json['CategoryImagePath'] ?? '',
      'categoryId': json['categoryId'] ?? json['CategoryId'],
      'productTypeId':
          json['productTypeId'] ?? json['ProductTypeId'],
      'productTypeName':
          json['productTypeName'] ??
          json['ProductTypeName'] ??
          json['productType'] ??
          '',
      'description': localizedDescription.isNotEmpty
          ? localizedDescription
          : (json['description'] ?? json['descriptionEn'] ?? ''),
      'price': price,
      'displayPrice': price,
      'priceUsd': json['usdPrice'] ??
          json['priceUsd'] ??
          json['USDPrice'] ??
          (currency == 'USD' ? price : ''),
      'currency': currency,
      'quantity': json['quantity'] ?? '',
      'unitName': json['unitName'] ?? '',
      'minimumOrderQuantity': json['minimumOrderQuantity'] ?? '',
      'maximumOrderQuantity': json['maximumOrderQuantity'] ?? '',
      'status': json['status'] ?? json['statusName'] ?? '',
      'approvalStatus': json['approvalStatus'] ?? '',
      'negotiable': _normalizeBooleanToYesNo(json['negotiable']),
      'isFeatured': _normalizeBooleanToYesNo(json['isFeatured']),
      'viewsCount': json['viewsCount'] ?? '',
      'images': json['images'] ?? const [],
      'documents': json['documents'] ?? const [],
      'shipping': {
        'additionalShippingNotes': localizedShippingDescription.isNotEmpty
            ? localizedShippingDescription
            : (json['shippingDescription'] ??
                json['shippingDescriptionEn'] ??
                json['additionalShippingNotes'] ??
                ''),
        'routeFromCountry': localizedOriginCountry.isNotEmpty
            ? localizedOriginCountry
            : (json['originCountryName'] ?? ''),
        'routeToCountry': localizedDestinationCountry.isNotEmpty
            ? localizedDestinationCountry
            : (json['destinationCountryName'] ?? ''),
        'routeFromPort': localizedLoadingPort.isNotEmpty
            ? localizedLoadingPort
            : (json['loadingPortName'] ?? ''),
        'routeToPort': localizedArrivalPort.isNotEmpty
            ? localizedArrivalPort
            : (json['arrivalPortName'] ?? ''),
        'routeFromCountryAr': json['originCountryNameAr'],
        'routeFromCountryEn':
            json['originCountryNameEn'] ?? json['originCountryName'],
        'routeToCountryAr': json['destinationCountryNameAr'],
        'routeToCountryEn':
            json['destinationCountryNameEn'] ?? json['destinationCountryName'],
        'routeFromPortAr': json['loadingPortNameAr'],
        'routeFromPortEn':
            json['loadingPortNameEn'] ?? json['loadingPortName'],
        'routeToPortAr': json['arrivalPortNameAr'],
        'routeToPortEn': json['arrivalPortNameEn'] ?? json['arrivalPortName'],
        'hasRouteInformation':
            (json['originCountryName']?.toString().trim().isNotEmpty == true) ||
            (json['destinationCountryName']?.toString().trim().isNotEmpty == true) ||
            (json['loadingPortName']?.toString().trim().isNotEmpty == true) ||
            (json['arrivalPortName']?.toString().trim().isNotEmpty == true),
        'routeSummary': _buildPublicRouteSummary(json),
      },
      'originCountryName': localizedOriginCountry.isNotEmpty
          ? localizedOriginCountry
          : (json['originCountryName'] ?? ''),
      'destinationCountryName': localizedDestinationCountry.isNotEmpty
          ? localizedDestinationCountry
          : (json['destinationCountryName'] ?? ''),
      'loadingPortName': localizedLoadingPort.isNotEmpty
          ? localizedLoadingPort
          : (json['loadingPortName'] ?? ''),
      'arrivalPortName': localizedArrivalPort.isNotEmpty
          ? localizedArrivalPort
          : (json['arrivalPortName'] ?? ''),
      'originCountryNameAr': json['originCountryNameAr'],
      'originCountryNameEn':
          json['originCountryNameEn'] ?? json['originCountryName'],
      'destinationCountryNameAr': json['destinationCountryNameAr'],
      'destinationCountryNameEn':
          json['destinationCountryNameEn'] ?? json['destinationCountryName'],
      'loadingPortNameAr': json['loadingPortNameAr'],
      'loadingPortNameEn':
          json['loadingPortNameEn'] ?? json['loadingPortName'],
      'arrivalPortNameAr': json['arrivalPortNameAr'],
      'arrivalPortNameEn':
          json['arrivalPortNameEn'] ?? json['arrivalPortName'],
      'discountPercentage': json['discountPercentage'] ?? json['DiscountPercentage'] ?? '',
      'discountDays': json['discountDays'] ?? json['DiscountDays'] ?? '',
      'offerDuration': json['offerDuration'] ?? json['OfferDuration'] ?? '',
      'supplierNotes': localizedSupplierNotes.isNotEmpty
          ? localizedSupplierNotes
          : (json['supplierNotes'] ?? json['supplierNotesEn'] ?? ''),
      'shippingDuration':
          json['shippingDuration'] ?? json['ShippingDuration'] ?? '',
      'videoPath': json['videoPath'] ?? '',
      'videoPaths': json['videoPaths'] ?? json['VideoPaths'] ?? const [],
      'videos': json['videos'] ?? json['Videos'] ?? const [],
      'videoDurationSeconds': json['videoDurationSeconds'] ?? '',
      'createdAt': json['createdAt'] ?? '',
      'updatedAt': json['updatedAt'] ?? '',
      'hasRetailPricing': json['hasRetailPricing'] ?? json['HasRetailPricing'],
      'searchListingChannel':
          json['searchListingChannel'] ?? json['SearchListingChannel'],
      'retailPrice': json['retailPrice'] ?? json['RetailPrice'],
      'retailUnitName': json['retailUnitName'] ?? json['RetailUnitName'],
      'retailQuantity': json['retailQuantity'] ?? json['RetailQuantity'],
      // Price Type (Local / Rexport) — must pass through for Offers/Requests/Categories.
      'requestTypeId': json['requestTypeId'] ?? json['RequestTypeId'],
      'requestTypeName': json['requestTypeName'] ?? json['RequestTypeName'],
      'requestType': json['requestType'] ?? json['RequestType'],
      // Booking incoterms (FOB / CNF / CIF).
      'bookingPriceTypeId':
          json['bookingPriceTypeId'] ?? json['BookingPriceTypeId'],
      'bookingPriceTypeName': json['bookingPriceTypeName'] ??
          json['BookingPriceTypeName'] ??
          json['bookingPriceType'] ??
          json['BookingPriceType'],
      'shippingDescriptionEn': localizedShippingDescription.isNotEmpty
          ? localizedShippingDescription
          : (json['shippingDescriptionEn'] ??
              json['ShippingDescriptionEn'] ??
              json['shippingDescription'] ??
              ''),
      // Keep bilingual raw fields for locale-aware remapping.
      'nameAr': json['nameAr'],
      'nameEn': json['nameEn'] ?? json['NameEn'],
      'descriptionAr': json['descriptionAr'],
      'descriptionEn': json['descriptionEn'] ?? json['DescriptionEn'],
      'supplierNotesAr': json['supplierNotesAr'],
      'supplierNotesEn': json['supplierNotesEn'] ?? json['SupplierNotesEn'],
      'shippingDescriptionAr': json['shippingDescriptionAr'],
      'packaging': json['packaging'] ?? json['Packaging'],
      'packagingDetails':
          json['packagingDetails'] ?? json['PackagingDetails'] ?? '',
    };
  }

  String _normalizeBooleanToYesNo(dynamic value) {
    if (value is bool) return value ? 'Yes' : 'No';
    final asString = value?.toString().toLowerCase();
    if (asString == 'true') return 'Yes';
    if (asString == 'false') return 'No';
    return 'No';
  }

  String _buildPublicRouteSummary(Map<String, dynamic> json) {
    final fromCountry = LocalizedProductText.pickOriginCountry(json);
    final fromPort = LocalizedProductText.pickLoadingPort(json);
    final toCountry = LocalizedProductText.pickDestinationCountry(json);
    final toPort = LocalizedProductText.pickArrivalPort(json);
    if (fromCountry.isEmpty && toCountry.isEmpty) return '';

    final from = fromPort.isEmpty ? fromCountry : '$fromCountry ($fromPort)';
    final to = toPort.isEmpty ? toCountry : '$toCountry ($toPort)';
    if (from.isEmpty) return to;
    if (to.isEmpty) return from;
    return LocalizedProductText.isArabic
        ? 'من $from → إلى $to'
        : 'From $from → to $to';
  }

  // =========================================================================
  // Submit offer
  // =========================================================================

  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  final TextEditingController quantityController = TextEditingController();
  final TextEditingController priceController = TextEditingController();
  final TextEditingController notesController = TextEditingController();

  MyListingProductModel? currentProduct;
  String offerToUserId = '';
  /// Reliable unit for request offers (DropdownFormField initialValue can desync from Cubit).
  String _offerSelectedUnit = 'Kg';

  final ImagePicker _imagePicker = ImagePicker();

  SubmitOfferFormState? get _submitFormState {
    final current = state;
    return current is SubmitOfferFormState ? current : null;
  }

  void initProduct(MyListingProductModel product, {String toUserId = ''}) {
    currentProduct = product;
    offerToUserId = toUserId.isNotEmpty ? toUserId : product.ownerId;
    quantityController.clear();
    priceController.clear();
    notesController.clear();
    final unit = _mapOfferUnit(product.unitName);
    _offerSelectedUnit = unit;
    emit(
      SubmitOfferFormState(
        product: product,
        selectedCurrency: _normalizeOfferCurrency(product.currency),
        selectedUnit: unit,
      ),
    );
  }

  String _normalizeOfferCurrency(String? currency) {
    final normalized = (currency ?? 'AED').trim().toUpperCase();
    return normalized == 'USD' ? 'USD' : 'AED';
  }

  String _mapOfferUnit(String unitName) {
    final normalized = unitName.trim();
    if (normalized.isEmpty) return 'Kg';

    switch (normalized.toLowerCase()) {
      case 'kilogram':
      case 'kg':
        return 'Kg';
      case 'ton':
        return 'Ton';
      case 'gram':
        return 'Gram';
      case 'piece':
        return 'Piece';
      case 'carton':
        return 'Carton';
      case 'bag':
        return 'Bag';
      case 'dozen':
        return 'Dozen';
      case 'box':
        return 'Box';
      default:
        return normalized;
    }
  }

  void setSelectedUnit(String? unit) {
    if (unit == null || unit.trim().isEmpty) return;
    _offerSelectedUnit = unit.trim();
    final form = _submitFormState;
    if (form == null) return;
    emit(form.copyWith(selectedUnit: _offerSelectedUnit));
  }

  void setSelectedCurrency(String? currency) {
    final form = _submitFormState;
    if (form == null || currency == null) return;
    emit(form.copyWith(selectedCurrency: _normalizeOfferCurrency(currency)));
  }

  Future<void> pickProductImages(BuildContext context) async {
    final form = _submitFormState;
    if (form == null) return;

    final choice = await _showOfferPickSourceSheet(context, includeVideo: true);
    if (!context.mounted || choice == null) return;

    final pickedPaths = await _pickOfferAssetPaths(
      context: context,
      choice: choice,
    );
    if (pickedPaths.isEmpty) return;

    final currentImages =
        form.productImages.where((path) => !_isVideoPath(path)).length;
    final incomingImages =
        pickedPaths.where((path) => !_isVideoPath(path)).length;
    if (currentImages + incomingImages > CreateAdFormMapper.maxProductImages) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(S.current.maxProductImagesExceeded)),
        );
      }
    }

    _appendUniquePaths(
      current: form.productImages,
      picked: pickedPaths,
      onUpdate: (paths) => emit(form.copyWith(productImages: paths)),
    );
  }

  void removeProductImage(int index) {
    final form = _submitFormState;
    if (form == null) return;
    final images = List<String>.from(form.productImages)..removeAt(index);
    emit(form.copyWith(productImages: images));
  }

  void _emitSubmitOfferValidationError(
    String message,
    SubmitOfferFormState form,
  ) {
    // Toast listener needs SubmitOfferErrorState, then restore the form so
    // image pick / submit keep working (ErrorState alone blanks the form).
    emit(SubmitOfferErrorState(message));
    emit(form.copyWith(isSubmitting: false));
  }

  Future<void> submitOfferForm() async {
    if (!formKey.currentState!.validate()) return;

    final form = _submitFormState;
    final product = currentProduct;
    if (form == null || product == null) return;

    if (ProductOwnershipHelper.isOwnedByCurrentUser(product)) {
      _emitSubmitOfferValidationError(
        S.current.cannotOrderOwnProduct,
        form,
      );
      return;
    }

    // Fields use ThousandsSeparatorInputFormatter (e.g. 1000 → "1,000").
    final quantity =
        ThousandsNumberInput.parseDouble(quantityController.text) ?? 0;
    final price = ThousandsNumberInput.parseDouble(priceController.text) ?? 0;
    final quantityError = ProductQuantityValidator.validateOfferAgainstRequiredQuantity(
      rawValue: quantityController.text,
      s: S.current,
      requestProduct: product,
      offerUnit: form.selectedUnit,
    );
    if (quantityError != null) {
      _emitSubmitOfferValidationError(quantityError, form);
      return;
    }
    if (quantity <= 0 || price <= 0) {
      _emitSubmitOfferValidationError(
        S.current.enterValidQuantityAndPrice,
        form,
      );
      return;
    }

    if (offerToUserId.trim().isEmpty) {
      _emitSubmitOfferValidationError(
        S.current.requestOwnerMissingCannotSubmitOffer,
        form,
      );
      return;
    }

    emit(form.copyWith(isSubmitting: true));

    final localImages = <String>[];
    final localVideos = <String>[];
    for (final path in form.productImages) {
      if (_isVideoPath(path)) {
        localVideos.add(path);
      } else {
        localImages.add(path);
      }
    }

    final unitName = CreateAdFormMapper.mapUnitName(
      form.selectedUnit.trim().isNotEmpty
          ? form.selectedUnit
          : _offerSelectedUnit,
    );
    debugPrint(
      'Submit offer unit: ui=${form.selectedUnit} backup=$_offerSelectedUnit mapped=$unitName',
    );

    final result = await _createOrderWithLocalAssetsInternal(
      request: CreateOrderRequest(
        toUserId: offerToUserId,
        productId: product.productId,
        supplierEmail: AuthService.instance.currentUserEmail ?? '',
        unitName: unitName,
        quantity: quantity,
        // UI field is "price per unit" — total = unit × quantity.
        unitPrice: price,
        totalPrice: price * quantity,
        paymentMethodName: CartPaymentMethod.cash.apiValue,
        notes: notesController.text.trim(),
      ),
      localImagePaths: localImages,
      localVideoPaths: localVideos,
      localDocumentPaths: const [],
    );

    if (result.orderId != null) {
      unawaited(fetchMyOffers());
      emit(
        const SubmitOfferSuccessState(
          'Your offer has been submitted successfully!',
        ),
      );
      return;
    }

    _emitSubmitOfferValidationError(
      result.error ?? 'Failed to submit offer. Please try again.',
      form,
    );
  }

  Future<String?> _showOfferPickSourceSheet(
    BuildContext context, {
    required bool includeVideo,
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
              if (includeVideo)
                ListTile(
                  leading: const Icon(Icons.videocam_outlined),
                  title: const Text('Video'),
                  onTap: () => Navigator.pop(context, 'video'),
                ),
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

  Future<List<String>> _pickOfferAssetPaths({
    required BuildContext context,
    required String choice,
    bool documentMode = false,
  }) async {
    final pickedPaths = <String>[];

    if (choice == 'gallery') {
      final images = await _imagePicker.pickMultiImage(imageQuality: 85);
      pickedPaths.addAll(images.map((image) => image.path).whereType<String>());
    } else if (choice == 'camera') {
      final image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );
      if (image?.path != null) pickedPaths.add(image!.path);
    } else if (choice == 'video') {
      final video = await _imagePicker.pickVideo(source: ImageSource.gallery);
      if (video?.path != null) pickedPaths.add(video!.path);
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

  void _appendUniquePaths({
    required List<String> current,
    required List<String> picked,
    required void Function(List<String> paths) onUpdate,
  }) {
    final updated = List<String>.from(current);
    for (final path in picked) {
      if (!updated.contains(path)) updated.add(path);
    }

    final imagePaths =
        updated.where((path) => !_isVideoPath(path)).toList(growable: false);
    final videoPaths = updated.where(_isVideoPath).toList(growable: false);
    if (imagePaths.length > CreateAdFormMapper.maxProductImages) {
      final keptImages =
          imagePaths.take(CreateAdFormMapper.maxProductImages).toList();
      updated
        ..clear()
        ..addAll(keptImages)
        ..addAll(videoPaths);
    }

    onUpdate(updated);
  }

  bool _isVideoPath(String path) {
    final lower = path.toLowerCase();
    return lower.endsWith('.mp4') ||
        lower.endsWith('.mov') ||
        lower.endsWith('.avi') ||
        lower.endsWith('.mkv') ||
        lower.endsWith('.webm');
  }

  Future<({String? orderId, String? error})>
  _createOrderWithLocalAssetsInternal({
    required CreateOrderRequest request,
    List<String> localImagePaths = const [],
    List<String> localVideoPaths = const [],
    List<String> localDocumentPaths = const [],
  }) async {
    final token = AuthService.instance.currentToken;
    if (token == null || token.isEmpty) {
      return (orderId: null, error: S.current.pleaseLoginToCreateAnOrder);
    }

    final uploadedImages = <String>[...request.imagePaths];
    for (final filePath in localImagePaths) {
      final uploadResult = await _uploadOrderImageUseCase(
        UploadOrderFileParams(
          productId: request.productId,
          filePath: filePath,
          token: token,
        ),
      );
      final failure = uploadResult.fold<String?>((f) => f.message, (path) {
        uploadedImages.add(path);
        return null;
      });
      if (failure != null) return (orderId: null, error: failure);
    }
    final uploadedVideos = <String>[...request.videoPaths];
    for (final filePath in localVideoPaths) {
      final uploadResult = await _uploadOrderVideoUseCase(
        UploadOrderFileParams(
          productId: request.productId,
          filePath: filePath,
          token: token,
        ),
      );
      final failure = uploadResult.fold<String?>((f) => f.message, (path) {
        uploadedVideos.add(path);
        return null;
      });
      if (failure != null) return (orderId: null, error: failure);
    }
    final uploadedDocuments = <String>[...request.documentPaths];
    for (final filePath in localDocumentPaths) {
      final uploadResult = await _uploadOrderDocumentUseCase(
        UploadOrderFileParams(
          productId: request.productId,
          filePath: filePath,
          token: token,
        ),
      );
      final failure = uploadResult.fold<String?>((f) => f.message, (path) {
        uploadedDocuments.add(path);
        return null;
      });
      if (failure != null) return (orderId: null, error: failure);
    }

    print('🔵 [Create Order] Uploaded Images: ${uploadedImages.length}');
    final createResult = await _createOrderUseCase(
      CreateOrderParams(
        request: CreateOrderRequest(
          toUserId: request.toUserId,
          productId: request.productId,
          supplierEmail: request.supplierEmail,
          unitName: CreateAdFormMapper.mapUnitName(request.unitName),
          quantity: request.quantity,
          unitPrice: request.unitPrice,
          totalPrice: request.totalPrice,
          paymentMethodName: request.paymentMethodName,
          notes: request.notes,
          imagePaths: uploadedImages,
          videoPaths: uploadedVideos,
          documentPaths: uploadedDocuments,
          addressLine: request.addressLine,
          cityName: request.cityName,
          shippingCostAed: request.shippingCostAed,
          portName: request.portName,
        ),
        token: token,
      ),
    );

    return createResult.fold(
      (failure) => (orderId: null, error: failure.message),
      (orderId) => (orderId: orderId, error: null),
    );
  }

  // =========================================================================
  // Booking purchase order
  // =========================================================================

  final TextEditingController bookingOfferController = TextEditingController();
  final TextEditingController bookingOrderQuantityController =
      TextEditingController();
  final TextEditingController bookingOrderPortController =
      TextEditingController();
  final TextEditingController bookingOrderNotesController =
      TextEditingController();

  MyListingProductModel? currentBookingProduct;
  String bookingToUserId = '';
  final Map<String, ({String country, List<String> ports})> _bookingPortsCache =
      {};

  BookingOrderFormState? get _bookingOrderFormState {
    final current = state;
    return current is BookingOrderFormState ? current : null;
  }

  void initSendBookingOrder(MyListingProductModel product) {
    currentBookingProduct = product;
    bookingToUserId = product.ownerId;

    final unit = product.unitName.trim().isEmpty
        ? 'Ton'
        : product.unitName.trim();
    bookingOrderQuantityController.text = '1';
    bookingOrderPortController.clear();
    bookingOrderNotesController.clear();

    final defaultCountry = product.destinationCountryName.trim();
    emit(
      BookingOrderFormState(
        product: product,
        selectedUnit: unit,
        selectedCountry:
            defaultCountry.isNotEmpty ? defaultCountry : null,
      ),
    );

    if (defaultCountry.isNotEmpty) {
      _loadBookingOrderPorts(
        defaultCountry,
        preselectPort: product.arrivalPortName,
      );
    }
  }

  Future<void> setBookingOrderCountry(String? country) async {
    final form = _bookingOrderFormState;
    if (form == null || country == null || country.isEmpty) return;

    bookingOrderPortController.clear();
    emit(
      form.copyWith(
        selectedCountry: country,
        clearSelectedPort: true,
        clearPorts: true,
        isPortsLoading: true,
      ),
    );
    await _loadBookingOrderPorts(country);
  }

  void setBookingOrderPort(String? port) {
    final form = _bookingOrderFormState;
    if (form == null || port == null) return;
    bookingOrderPortController.text = port;
    emit(form.copyWith(selectedPort: port));
  }

  Future<void> _loadBookingOrderPorts(
    String country, {
    String? preselectPort,
  }) async {
    final form = _bookingOrderFormState;
    if (form == null) return;

    final cacheKey = country.trim().toLowerCase();
    if (_bookingPortsCache.containsKey(cacheKey)) {
      final cached = _bookingPortsCache[cacheKey]!;
      final selectedPort = _resolveBookingPortSelection(
        cached.ports,
        preselectPort,
      );
      if (selectedPort != null) {
        bookingOrderPortController.text = selectedPort;
      }
      emit(
        form.copyWith(
          selectedCountry: cached.country,
          ports: cached.ports,
          selectedPort: selectedPort,
          isPortsLoading: false,
        ),
      );
      return;
    }

    final result = await _getGeoPortsByCountryUseCase(country);
    result.fold(
      (_) {
        final latest = _bookingOrderFormState ?? form;
        emit(latest.copyWith(isPortsLoading: false));
      },
      (response) {
        final portNames =
            response.ports.map((port) => port.displayName).toList();
        final normalizedCountry = response.country.isNotEmpty
            ? response.country
            : country;
        _bookingPortsCache[cacheKey] = (
          country: normalizedCountry,
          ports: portNames,
        );

        final latest = _bookingOrderFormState ?? form;
        final selectedPort = _resolveBookingPortSelection(
          portNames,
          preselectPort,
        );
        if (selectedPort != null) {
          bookingOrderPortController.text = selectedPort;
        }
        emit(
          latest.copyWith(
            selectedCountry: normalizedCountry,
            ports: portNames,
            selectedPort: selectedPort,
            isPortsLoading: false,
          ),
        );
      },
    );
  }

  String? _resolveBookingPortSelection(
    List<String> ports,
    String? preferredPort,
  ) {
    final trimmed = preferredPort?.trim() ?? '';
    if (trimmed.isEmpty || ports.isEmpty) return null;
    for (final port in ports) {
      if (port.toLowerCase() == trimmed.toLowerCase()) return port;
    }
    return null;
  }

  void setBookingOrderUnit(String? unit) {
    final form = _bookingOrderFormState;
    if (form == null || unit == null) return;
    emit(form.copyWith(selectedUnit: unit));
  }

  void notifyBookingOrderQuantityChanged() {
    final form = _bookingOrderFormState;
    if (form == null) return;
    emit(form.copyWith(quantityRevision: form.quantityRevision + 1));
  }

  String? get bookingYourOffer {
    final value = bookingOfferController.text.trim();
    return value.isEmpty ? null : value;
  }

  void clearBookingYourOffer() {
    bookingOfferController.clear();
    currentBookingProduct = null;
  }

  double bookingOrderUnitPrice(MyListingProductModel product) {
    // Category / booking Purchase Order is always wholesale (never hybrid retail).
    final listPrice = ProductPriceFormatter.amount(product, preferRetail: false);
    final offer = bookingYourOffer;
    if (offer != null) {
      return double.tryParse(offer) ?? (double.tryParse(listPrice) ?? 0);
    }
    return double.tryParse(listPrice) ?? 0;
  }

  double get bookingOrderQuantity =>
      double.tryParse(bookingOrderQuantityController.text.trim()) ?? 0;

  // =========================================================================
  // Offer purchase order (product details)
  // =========================================================================

  final TextEditingController offerOrderQuantityController =
      TextEditingController();

  MyListingProductModel? currentOfferOrderProduct;
  String offerOrderToUserId = '';

  OfferOrderFormState? get _offerOrderFormState {
    final current = state;
    return current is OfferOrderFormState ? current : null;
  }

  void initOfferOrder(MyListingProductModel product) {
    currentOfferOrderProduct = product;
    offerOrderToUserId = product.ownerId;

    final unit = product.unitName.trim().isEmpty
        ? 'Ton'
        : product.unitName.trim();
    final defaultQty = product.minimumOrderQuantity.trim().isNotEmpty
        ? product.minimumOrderQuantity.trim()
        : '1';

    offerOrderQuantityController.text = defaultQty;
    emit(OfferOrderFormState(product: product, selectedUnit: unit));
  }

  void notifyOfferOrderQuantityChanged() {
    final form = _offerOrderFormState;
    if (form == null) return;
    emit(form.copyWith());
  }

  double offerOrderUnitPrice(MyListingProductModel product) =>
      double.tryParse(ProductPriceFormatter.amount(product)) ?? 0;

  double get offerOrderQuantity =>
      double.tryParse(offerOrderQuantityController.text.trim()) ?? 0;

  Future<void> submitOfferOrder() async {
    final form = _offerOrderFormState;
    final product = currentOfferOrderProduct;
    if (form == null || product == null) return;

    if (ProductOwnershipHelper.isOwnedByCurrentUser(product)) {
      emit(OfferOrderErrorState(S.current.cannotOrderOwnProduct));
      return;
    }

    final quantity = offerOrderQuantity;
    final unitPrice = offerOrderUnitPrice(product);
    final totalPrice = unitPrice * quantity;

    final quantityError = ProductQuantityValidator.validateRetailOrderQuantity(
      rawValue: offerOrderQuantityController.text,
      s: S.current,
      product: product,
    );
    if (quantityError != null) {
      emit(OfferOrderErrorState(quantityError));
      return;
    }
    if (quantity <= 0 || unitPrice <= 0) {
      emit(
        OfferOrderErrorState(S.current.enterValidQuantityAndPrice),
      );
      return;
    }

    final toUserId = offerOrderToUserId.trim().isNotEmpty
        ? offerOrderToUserId
        : product.ownerId;
    if (toUserId.trim().isEmpty) {
      emit(
        OfferOrderErrorState(S.current.productOwnerMissingCannotSubmitOrder),
      );
      return;
    }

    emit(form.copyWith(isSubmitting: true));

    final unitName = CreateAdFormMapper.mapUnitName(
      product.unitName.trim().isEmpty ? 'Ton' : product.unitName.trim(),
    );

    final result = await _createOrderWithLocalAssetsInternal(
      request: CreateOrderRequest(
        toUserId: toUserId,
        productId: product.productId,
        supplierEmail: AuthService.instance.currentUserEmail ?? '',
        unitName: unitName,
        quantity: quantity,
        unitPrice: unitPrice,
        totalPrice: totalPrice,

        paymentMethodName: CartPaymentMethod.cash.apiValue,
      ),
    );

    if (result.orderId != null) {
      emit(OfferOrderSuccessState(result.orderId!));
      return;
    }

    emit(
      OfferOrderErrorState(
        result.error ?? 'Failed to submit offer order. Please try again.',
      ),
    );
    final latest = _offerOrderFormState ?? form;
    emit(latest.copyWith(isSubmitting: false));
  }

  // =========================================================================

  // Cart

  // =========================================================================

  CartLoadedState? get _cartLoadedState =>
      state is CartLoadedState ? state as CartLoadedState : null;

  CartLoadedState _cartWithoutPendingPayment(CartLoadedState state) {
    if (!state.isAwaitingOnlinePayment && !state.isCheckingPayment) {
      return state;
    }
    _stopPaymentPolling();
    return state.copyWith(clearPaymentInfo: true, isCheckingPayment: false);
  }

  Future<void> loadCart() async {
    final token = AuthService.instance.currentToken;
    if (token == null || token.isEmpty) {
      emit(CartErrorState(S.current.pleaseLoginToViewYourCart));
      return;
    }

    final current = _cartLoadedState;
    if (current != null) {
      emit(current.copyWith(isLoading: true, clearErrorMessage: true));
    }

    await _ensureDomesticEmiratesLoaded();
    await _reloadCartSavedAddresses(token);

    final result = await _getCartUseCase(GetCartParams(token: token));
    result.fold((failure) {
      final localized = UserFacingErrorLocalizer.localizeCartError(failure.message);
      if (current != null) {
        emit(current.copyWith(isLoading: false, errorMessage: localized));
      } else {
        emit(CartErrorState(localized));
      }
    }, (cart) async {
      final preserved = _cartLoadedState;
      emit(
        CartLoadedState(
          cart: cart,
          isLoading: false,
          selectedPaymentMethod:
              preserved?.selectedPaymentMethod ?? CartPaymentMethod.online,
          selectedAddressId: preserved?.selectedAddressId,
          selectedEmirateName: preserved?.selectedEmirateName,
          deliveryAddressLine: preserved?.deliveryAddressLine,
          isSelfPickup: preserved?.isSelfPickup ?? false,
          paymentSessionId: preserved?.paymentSessionId,
          paymentCheckoutUrl: preserved?.paymentCheckoutUrl,
          isCheckingPayment: preserved?.isCheckingPayment ?? false,
        ),
      );
      if (preserved?.isSelfPickup == true) {
        final loaded = _cartLoadedState;
        if (loaded != null) {
          emit(
            loaded.copyWith(
              cart: loaded.cart.copyWith(deliveryFeeAed: 0),
            ),
          );
        }
      } else {
        await _autoSelectSavedAddressIfNeeded();
        await _refreshCartShipping(
          emirateOverride: _cartLoadedState?.selectedEmirateName,
        );
      }
    });
  }

  Future<void> _autoSelectSavedAddressIfNeeded() async {
    final current = _cartLoadedState;
    if (current == null || current.isSelfPickup) return;

    final selectedId = current.selectedAddressId;
    if (selectedId != null &&
        cartSavedAddresses.any((address) => address.addressId == selectedId)) {
      return;
    }

    if (cartSavedAddresses.isEmpty) return;
    await selectCartSavedAddress(cartSavedAddresses.first);
  }

  Future<void> _ensureDomesticEmiratesLoaded() async {
    if (domesticEmirates.isNotEmpty || isLoadingDomesticEmirates) return;

    final cacheKey = ApiCacheKeys.domesticEmirates;
    final cached = await ApiCacheStore.instance.read(cacheKey, allowStale: true);
    if (cached != null) {
      try {
        final data = cached.data;
        final items = data is Map<String, dynamic>
            ? data['items'] as List<dynamic>? ?? const []
            : const [];
        domesticEmirates = _dedupeDomesticEmirates(
          items
              .whereType<Map<String, dynamic>>()
              .map(DomesticEmirateModel.fromJson)
              .toList(),
        );
        if (data is Map<String, dynamic>) {
          _applyShippingWeightConfig(data);
        }
        if (domesticEmirates.isNotEmpty && cached.isFresh) return;
      } catch (_) {}
    }

    isLoadingDomesticEmirates = true;
    try {
      final response = await DioHelper.getData(
        url: ApiConstants.internalDomesticShippingEmiratesEndPoint,
      );
      final status = response?.statusCode ?? 0;
      if (status >= 200 && status < 300) {
        final data = response?.data;
        if (data is Map<String, dynamic>) {
          await ApiCacheStore.instance.write(
            cacheKey,
            data,
            ApiCacheTtl.geo,
          );
        }
        final items = data is Map<String, dynamic>
            ? data['items'] as List<dynamic>? ?? const []
            : const [];
        domesticEmirates = _dedupeDomesticEmirates(
          items
              .whereType<Map<String, dynamic>>()
              .map(DomesticEmirateModel.fromJson)
              .toList(),
        );
        if (data is Map<String, dynamic>) {
          _applyShippingWeightConfig(data);
        }
      }
    } catch (_) {
      // Keep empty; shipping UI will show fallback message.
    } finally {
      isLoadingDomesticEmirates = false;
    }
  }

  void _applyShippingWeightConfig(Map<String, dynamic> data) {
    final excess = data['excessKgRateAed'] ?? data['ExcessKgRateAed'];
    final free = data['freeWeightKg'] ?? data['FreeWeightKg'];
    if (excess is num) {
      excessKgRateAed = excess.round().clamp(0, 255);
    } else {
      final parsed = int.tryParse(excess?.toString() ?? '');
      if (parsed != null) excessKgRateAed = parsed.clamp(0, 255);
    }
    if (free is num) {
      freeWeightKg = free.round().clamp(0, 255);
    } else {
      final parsed = int.tryParse(free?.toString() ?? '');
      if (parsed != null) freeWeightKg = parsed.clamp(0, 255);
    }
  }

  List<DomesticEmirateModel> _dedupeDomesticEmirates(
    List<DomesticEmirateModel> items,
  ) {
    final seen = <String>{};
    final unique = <DomesticEmirateModel>[];
    for (final item in items) {
      final key = item.nameEn.trim().toLowerCase();
      if (key.isEmpty || !seen.add(key)) continue;
      unique.add(item);
    }
    unique.sort(
      (a, b) => UaeRetailEmirates.sortIndex(a.nameEn)
          .compareTo(UaeRetailEmirates.sortIndex(b.nameEn)),
    );
    return unique;
  }

  Future<void> _reloadCartSavedAddresses(String token) async {
    isLoadingCartAddresses = true;
    final result = await _getClientAddressesUseCase(token: token);
    cartSavedAddresses = result.fold((_) => <ClientAddressModel>[], (items) => items);
    isLoadingCartAddresses = false;
  }

  Future<void> reloadCartSavedAddresses() async {
    final token = AuthService.instance.currentToken;
    if (token == null || token.isEmpty) return;

    final current = _cartLoadedState;
    if (current != null) {
      emit(current.copyWith(clearErrorMessage: true));
    }

    await _reloadCartSavedAddresses(token);

    final loaded = _cartLoadedState;
    if (loaded != null) {
      emit(loaded);
      await _autoSelectSavedAddressIfNeeded();
    }
  }

  Future<void> selectCartSavedAddress(ClientAddressModel address) async {
    final current = _cartLoadedState;
    if (current == null) return;

    await _ensureDomesticEmiratesLoaded();
    final matchedEmirate = _matchEmirateName(address.cityName);

    emit(
      current.copyWith(
        selectedAddressId: address.addressId,
        deliveryAddressLine: address.formattedAddressLine,
        selectedEmirateName: matchedEmirate,
        clearErrorMessage: true,
        isLoadingShipping: matchedEmirate != null,
      ),
    );

    if (matchedEmirate != null) {
      await _refreshCartShipping(emirateOverride: matchedEmirate);
    } else {
      emit(
        (_cartLoadedState ?? current).copyWith(
          isLoadingShipping: false,
          errorMessage: S.current.selectDeliveryEmirate,
        ),
      );
    }
  }

  String? _validateCartDelivery(CartLoadedState current) {
    if (current.isSelfPickup) return null;
    if (current.selectedAddressId == null ||
        current.selectedAddressId!.trim().isEmpty) {
      return S.current.selectDeliveryAddress;
    }
    if (current.selectedEmirateName == null ||
        current.selectedEmirateName!.trim().isEmpty) {
      return S.current.selectDeliveryEmirate;
    }
    return null;
  }

  Future<String?> _resolveDefaultEmirateName() async {
    final token = AuthService.instance.currentToken;
    if (token != null && token.isNotEmpty) {
      final result = await _getClientAddressesUseCase(token: token);
      final addresses = result.fold((_) => <ClientAddressModel>[], (items) => items);
      for (final address in addresses) {
        final city = address.cityName.trim();
        if (city.isNotEmpty) {
          final matched = _matchEmirateName(city);
          if (matched != null) return matched;
        }
      }
    }

    return _defaultEmirateName();
  }

  Future<double?> _fetchDomesticShippingPrice(String emirateName) async {
    try {
      final response = await DioHelper.getData(
        url: ApiConstants.internalDomesticShippingPriceEndPoint,
        query: {'emirate': emirateName},
      );
      final status = response?.statusCode ?? 0;
      if (status < 200 || status >= 300) return null;

      final data = response?.data;
      if (data is! Map<String, dynamic>) return null;

      _applyShippingWeightConfig(data);

      final price = data['priceAed'];
      double? base;
      if (price is num) {
        base = price.toDouble();
      } else {
        base = double.tryParse(price?.toString() ?? '');
      }
      return base;
    } catch (_) {
      return null;
    }
  }

  String? _matchEmirateName(String candidate) {
    final trimmed = candidate.trim();
    if (trimmed.isEmpty) return null;

    final canonical = UaeRetailEmirates.canonicalEmirateNameEn(trimmed);
    if (canonical == null) return null;

    for (final emirate in domesticEmirates) {
      if (emirate.nameEn.toLowerCase() == canonical.toLowerCase()) {
        return emirate.nameEn;
      }
    }

    return canonical;
  }

  String _defaultEmirateName() {
    for (final emirate in domesticEmirates) {
      if (emirate.nameEn.toLowerCase() == 'dubai') {
        return emirate.nameEn;
      }
    }
    if (domesticEmirates.isNotEmpty) {
      return domesticEmirates.first.nameEn;
    }
    return 'Dubai';
  }

  String _resolveValidEmirateName(String? candidate) {
    final matched = candidate == null ? null : _matchEmirateName(candidate);
    return matched ?? _defaultEmirateName();
  }

  Future<void> _refreshCartShipping({String? emirateOverride}) async {
    final current = _cartLoadedState;
    if (current == null || current.cart.isEmpty) return;

    if (current.isSelfPickup) {
      emit(
        current.copyWith(
          cart: current.cart.copyWith(deliveryFeeAed: 0),
          isLoadingShipping: false,
        ),
      );
      return;
    }

    emit(current.copyWith(isLoadingShipping: true, clearErrorMessage: true));

    await _ensureDomesticEmiratesLoaded();

    var emirateName = emirateOverride ?? current.selectedEmirateName;
    emirateName ??= await _resolveDefaultEmirateName();
    final resolvedEmirate =
        _matchEmirateName(emirateName!) ?? _resolveValidEmirateName(emirateName);

    final price = await _fetchDomesticShippingPrice(resolvedEmirate);
    final base = price ?? 0;
    final fee = current.cart.shippingFeeWithExcess(
      emirateBaseAed: base,
      excessKgRateAed: excessKgRateAed,
      freeWeightKg: freeWeightKg.toDouble(),
    );
    final updatedCart = current.cart.copyWith(deliveryFeeAed: fee);

    emit(
      current.copyWith(
        cart: updatedCart,
        selectedEmirateName: resolvedEmirate,
        isLoadingShipping: false,
      ),
    );
  }

  Future<void> selectCartEmirate(String emirateName) async {
    final current = _cartLoadedState;
    if (current == null || current.isSelfPickup) return;

    final matched = _matchEmirateName(emirateName) ?? _defaultEmirateName();
    if (matched.isEmpty) return;

    final cleared = _cartWithoutPendingPayment(current);
    emit(
      cleared.copyWith(
        selectedEmirateName: matched,
        isLoadingShipping: true,
        clearErrorMessage: true,
      ),
    );

    await _ensureDomesticEmiratesLoaded();
    final price = await _fetchDomesticShippingPrice(matched);
    final fee = cleared.cart.shippingFeeWithExcess(
      emirateBaseAed: price ?? 0,
      excessKgRateAed: excessKgRateAed,
      freeWeightKg: freeWeightKg.toDouble(),
    );
    emit(
      cleared.copyWith(
        cart: cleared.cart.copyWith(deliveryFeeAed: fee),
        selectedEmirateName: matched,
        isLoadingShipping: false,
      ),
    );
  }

  Future<void> setCartSelfPickup(bool value) async {
    final current = _cartLoadedState;
    if (current == null || current.isSelfPickup == value) return;

    final cleared = _cartWithoutPendingPayment(current);

    if (value) {
      emit(
        cleared.copyWith(
          isSelfPickup: true,
          cart: cleared.cart.copyWith(deliveryFeeAed: 0),
          clearSelectedAddressId: true,
          clearSelectedEmirateName: true,
          clearDeliveryAddressLine: true,
          isLoadingShipping: false,
        ),
      );
      return;
    }

    emit(cleared.copyWith(isSelfPickup: false));
    await _autoSelectSavedAddressIfNeeded();
    await _refreshCartShipping();
  }

  void selectPaymentMethod(CartPaymentMethod method) {
    final current = _cartLoadedState;
    if (current == null) return;
    emit(
      current.copyWith(selectedPaymentMethod: method, clearErrorMessage: true),
    );
  }

  Future<void> incrementItem({
    required int cartItemId,
    required String productId,
    required String unitName,
  }) async {
    final current = _cartLoadedState;
    if (current == null) return;

    final item = _findCartItem(current.cart, cartItemId);
    if (item == null || !item.canIncrement) return;

    await _updateCartQuantity(
      cartItemId: cartItemId,
      productId: productId,
      unitName: unitName,
      quantity: 1,
      optimisticCart: _applyOptimisticQuantityChange(current.cart, cartItemId, 1),
    );
  }

  Future<void> decrementItem({required int cartItemId}) async {
    final current = _cartLoadedState;
    if (current == null) return;

    await _mutateCartItem(
      cartItemId: cartItemId,
      optimisticCart: _applyOptimisticQuantityChange(current.cart, cartItemId, -1),
      action: () {
        final token = AuthService.instance.currentToken!;
        return _reduceCartItemQuantityUseCase(
          ReduceCartItemQuantityParams(
            token: token,
            cartItemId: cartItemId,
            quantity: 1,
          ),
        );
      },
    );
  }

  Future<void> removeCartItem({required int cartItemId}) async {
    final current = _cartLoadedState;
    if (current == null) return;

    await _mutateCartItem(
      cartItemId: cartItemId,
      optimisticCart: current.cart.copyWith(
        items: current.cart.items
            .where((item) => item.id != cartItemId)
            .toList(),
      ),
      action: () {
        final token = AuthService.instance.currentToken!;
        return _removeCartItemUseCase(
          RemoveCartItemParams(token: token, cartItemId: cartItemId),
        );
      },
    );
  }

  Future<void> addProductToCart({
    required String productId,
    required double quantity,
    required String unitName,
  }) async {
    final knownProducts = <MyListingProductModel?>[
      currentOfferOrderProduct,
      currentBookingProduct,
      currentProduct,
    ];
    for (final known in knownProducts) {
      if (known != null &&
          known.productId == productId &&
          ProductOwnershipHelper.isOwnedByCurrentUser(known)) {
        emit(CartErrorState(S.current.cannotOrderOwnProduct));
        return;
      }
    }

    await _updateCartQuantity(
      productId: productId,
      unitName: unitName,
      quantity: quantity,
      successMessage: S.current.productAddedToCart,
    );
  }

  Future<void> _updateCartQuantity({
    int? cartItemId,
    required String productId,
    required String unitName,
    required double quantity,
    String? successMessage,
    CartEntity? optimisticCart,
  }) async {
    final token = AuthService.instance.currentToken;
    if (token == null || token.isEmpty) {
      emit(CartErrorState(S.current.pleaseLoginToManageYourCart));
      return;
    }

    await _mutateCartItem(
      cartItemId: cartItemId,
      successMessage: successMessage,
      optimisticCart: optimisticCart,
      action: () => _addCartItemUseCase(
        AddCartItemParams(
          token: token,
          productId: productId,
          quantity: quantity,
          unitName: unitName,
        ),
      ),
    );
  }

  CartItemEntity? _findCartItem(CartEntity cart, int cartItemId) {
    for (final item in cart.items) {
      if (item.id == cartItemId) return item;
    }
    return null;
  }

  CartEntity _applyOptimisticQuantityChange(
    CartEntity cart,
    int cartItemId,
    double delta,
  ) {
    final items = <CartItemEntity>[];
    for (final item in cart.items) {
      if (item.id != cartItemId) {
        items.add(item);
        continue;
      }

      if (delta <= -item.quantity) {
        continue;
      }

      final newQuantity = item.quantity + delta;
      if (newQuantity <= 0) {
        continue;
      }

      items.add(
        item.copyWith(
          quantity: newQuantity,
          totalPriceAed: item.unitPriceAed * newQuantity,
        ),
      );
    }

    return cart.copyWith(items: items);
  }

  Future<void> _mutateCartItem({
    int? cartItemId,
    required Future<Either<Failure, CartEntity>> Function() action,
    String? successMessage,
    CartEntity? optimisticCart,
  }) async {
    final token = AuthService.instance.currentToken;
    if (token == null || token.isEmpty) {
      emit(CartErrorState(S.current.pleaseLoginToManageYourCart));
      return;
    }

    final current = _cartLoadedState;
    final clearedCurrent =
        current == null ? null : _cartWithoutPendingPayment(current);
    final revertState = clearedCurrent;

    if (clearedCurrent != null && optimisticCart != null) {
      emit(
        clearedCurrent.copyWith(
          cart: optimisticCart,
          clearErrorMessage: true,
          clearSuccessMessage: true,
        ),
      );
    } else if (clearedCurrent != null) {
      emit(
        clearedCurrent.copyWith(
          isUpdatingItem: true,
          updatingCartItemId: cartItemId,
          clearUpdatingCartItemId: cartItemId == null,
          clearErrorMessage: true,
          clearSuccessMessage: true,
        ),
      );
    }

    final result = await action();

    result.fold(
      (failure) {
        final localized = UserFacingErrorLocalizer.localizeCartError(
          failure.message,
          cart: revertState?.cart,
          cartItemId: cartItemId,
        );
        if (revertState != null) {
          emit(
            revertState.copyWith(
              isUpdatingItem: false,
              clearUpdatingCartItemId: true,
              errorMessage: localized,
            ),
          );
        } else {
          emit(CartErrorState(localized));
        }
      },
      (cart) {
        final emirate = clearedCurrent?.selectedEmirateName;
        final isSelfPickup = clearedCurrent?.isSelfPickup ?? false;
        final shippingFee = isSelfPickup
            ? 0.0
            : clearedCurrent?.cart.deliveryFeeAed ?? cart.deliveryFeeAed;
        emit(
          CartLoadedState(
            cart: cart.copyWith(deliveryFeeAed: shippingFee),
            selectedPaymentMethod:
                clearedCurrent?.selectedPaymentMethod ??
                    CartPaymentMethod.online,
            selectedEmirateName: emirate,
            isSelfPickup: isSelfPickup,
            isCheckingPayment: false,
            successMessage: successMessage,
          ),
        );
        if (!isSelfPickup) {
          unawaited(_refreshCartShipping(emirateOverride: emirate));
        }
      },
    );
  }

  Future<void> confirmOrder() async {
    final token = AuthService.instance.currentToken;
    if (token == null || token.isEmpty) {
      emit(CartErrorState(S.current.pleaseLoginToConfirmYourOrder));
      return;
    }

    final current = _cartLoadedState;
    if (current == null || current.cart.isEmpty) return;

    final deliveryError = _validateCartDelivery(current);
    if (deliveryError != null) {
      emit(current.copyWith(errorMessage: deliveryError));
      return;
    }

    if (current.selectedPaymentMethod == CartPaymentMethod.online) {
      await _initiateOnlinePayment(current, token);
      return;
    }

    await _confirmCashOrder(current, token);
  }

  Future<void> _confirmCashOrder(CartLoadedState current, String token) async {
    emit(
      current.copyWith(
        isConfirming: true,
        clearErrorMessage: true,
        clearSuccessMessage: true,
        clearInfoMessage: true,
      ),
    );

    final result = await _confirmCartOrderUseCase(
      ConfirmCartOrderParams(
        token: token,
        paymentMethod: CartPaymentMethod.cash,
        shippingCostAed:
            current.isSelfPickup ? 0 : current.cart.deliveryFeeAed,
        isSelfPickup: current.isSelfPickup,
        addressId: current.isSelfPickup ? null : current.selectedAddressId,
        cityName:
            current.isSelfPickup ? null : current.selectedEmirateName,
      ),
    );

    result.fold(
      (failure) => emit(
        current.copyWith(isConfirming: false, errorMessage: failure.message),
      ),
      (orderResult) async {
        emit(
          current.copyWith(
            isConfirming: false,
            cart: const CartEntity(items: []),
            clearPaymentInfo: true,
          ),
        );
        await loadCart();
        final orderId = orderResult.firstCreatedOrderId;
        if (orderId != null) {
          await fetchMyOrders();
          await _emitNavigateToTrackOrder(orderId);
        }
      },
    );
  }

  Future<void> _initiateOnlinePayment(
    CartLoadedState current,
    String token,
  ) async {
    emit(
      current.copyWith(
        isConfirming: true,
        clearErrorMessage: true,
        clearSuccessMessage: true,
        clearInfoMessage: true,
      ),
    );

    // Step 1: reserve checkout (PendingOrder) — NOT the final split order.
    final result = await _confirmCartOrderUseCase(
      ConfirmCartOrderParams(
        token: token,
        paymentMethod: CartPaymentMethod.online,
        shippingCostAed:
            current.isSelfPickup ? 0 : current.cart.deliveryFeeAed,
        isSelfPickup: current.isSelfPickup,
        addressId: current.isSelfPickup ? null : current.selectedAddressId,
        cityName:
            current.isSelfPickup ? null : current.selectedEmirateName,
      ),
    );

    await result.fold(
      (failure) async {
        emit(
          current.copyWith(isConfirming: false, errorMessage: failure.message),
        );
      },
      (orderResult) async {
        if (orderResult.orderGroupId != null &&
            orderResult.orderGroupId!.isNotEmpty) {
          emit(
            current.copyWith(
              isConfirming: false,
              errorMessage:
                  'Order was created before payment. Please contact support.',
            ),
          );
          return;
        }

        if (!orderResult.isOnlinePending) {
          emit(
            current.copyWith(
              isConfirming: false,
              errorMessage:
                  'Could not start online payment. No order was created.',
            ),
          );
          return;
        }

        // Step 2: Stripe checkout session for the pending order.
        final checkoutResult = await _createStripeCheckoutUseCase(
          CreateStripeCheckoutParams(
            token: token,
            pendingOrderId: orderResult.pendingOrderId!,
          ),
        );

        await checkoutResult.fold(
          (failure) async {
            emit(
              current.copyWith(
                isConfirming: false,
                errorMessage: failure.message,
              ),
            );
          },
          (checkout) async {
            emit(
              current.copyWith(
                isConfirming: false,
                isCheckingPayment: true,
                paymentSessionId: checkout.sessionId,
                paymentCheckoutUrl: checkout.checkoutUrl,
                infoMessage:
                    'Complete payment in Stripe. Split orders are created only after Stripe confirms payment.',
              ),
            );
            _startPaymentPolling();
            await _openInAppStripeCheckout(checkout.checkoutUrl);
          },
        );
      },
    );
  }

  Future<void> _openInAppStripeCheckout(String checkoutUrl) async {
    final opened = await StripeCheckoutLauncher.open(checkoutUrl);
    if (!opened) {
      final current = _cartLoadedState;
      if (current != null) {
        emit(
          current.copyWith(
            errorMessage:
                'Could not open payment page. Install a browser or tap "Open Stripe" to retry.',
          ),
        );
      }
    }
  }

  Future<void> openPaymentCheckout() async {
    final current = _cartLoadedState;
    final url = current?.paymentCheckoutUrl;
    if (url == null || url.isEmpty) return;

    _startPaymentPolling();
    await _openInAppStripeCheckout(url);
  }

  Future<void> checkPaymentStatus({bool silent = false}) async {
    final token = AuthService.instance.currentToken;
    final current = _cartLoadedState;
    final sessionId = current?.paymentSessionId;
    if (token == null || current == null || sessionId == null) return;

    if (!silent) {
      emit(current.copyWith(isCheckingPayment: true, clearErrorMessage: true));
    }

    final result = await _getCheckoutStatusUseCase(
      GetCheckoutStatusParams(token: token, sessionId: sessionId),
    );

    result.fold(
      (failure) {
        if (!silent) {
          emit(
            current.copyWith(
              isCheckingPayment: false,
              errorMessage: failure.message,
            ),
          );
        }
      },
      (status) async {
        if (status.isCompleted) {
          _stopPaymentPolling();
          emit(
            current.copyWith(
              isCheckingPayment: false,
              clearPaymentInfo: true,
            ),
          );
          await Future.wait([
            loadCart(),
            fetchMyOrders(),
          ]);
          final latest = _latestMyOrder();
          if (latest != null) {
            await _emitNavigateToTrackOrder(latest.id);
          }
          return;
        }

        if (status.isProcessing) {
          if (!silent) {
            emit(
              current.copyWith(
                isCheckingPayment: true,
                infoMessage:
                    'Payment received. Waiting for Stripe webhook to create your orders...',
              ),
            );
          }
          _startPaymentPolling();
          return;
        }

        if (!silent) {
          emit(
            current.copyWith(
              isCheckingPayment: false,
              errorMessage:
                  'Payment not confirmed yet. Complete payment in Stripe first.',
            ),
          );
        }
      },
    );
  }

  void _startPaymentPolling() {
    _paymentPollTimer?.cancel();
    _paymentPollAttempts = 0;
    _paymentPollTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      unawaited(_pollPaymentStatusOnce());
    });
  }

  void _stopPaymentPolling() {
    _paymentPollTimer?.cancel();
    _paymentPollTimer = null;
    _paymentPollAttempts = 0;
  }

  Future<void> _pollPaymentStatusOnce() async {
    final current = _cartLoadedState;
    if (current == null || !current.isAwaitingOnlinePayment) {
      _stopPaymentPolling();
      return;
    }

    _paymentPollAttempts++;
    if (_paymentPollAttempts > _maxPaymentPollAttempts) {
      _stopPaymentPolling();
      return;
    }

    await checkPaymentStatus(silent: true);
  }

  void clearCartFeedback() {
    final current = _cartLoadedState;
    if (current == null) return;
    emit(
      current.copyWith(
        clearErrorMessage: true,
        clearSuccessMessage: true,
        clearInfoMessage: true,
      ),
    );
  }

  // =========================================================================
  // Order — upload assets & create
  // =========================================================================

  Future<String?> uploadOrderImage({
    required String productId,
    required String filePath,
    required BuildContext context,
  }) async {
    final token = AuthService.instance.currentToken;
    if (token == null || token.isEmpty) {
      emit(
         UploadOrderFileErrorState(
          S.of(context).pleaseLoginToUploadImages,
          'orderImage',
        ),
      );
      return null;
    }

    emit(const UploadOrderFileLoadingState('orderImage'));
    final result = await _uploadOrderImageUseCase(
      UploadOrderFileParams(
        productId: productId,
        filePath: filePath,
        token: token,
      ),
    );

    return result.fold(
      (failure) {
        emit(UploadOrderFileErrorState(failure.message, 'orderImage'));
        return null;
      },
      (path) {
        emit(UploadOrderFileSuccessState(path, 'orderImage'));
        return path;
      },
    );
  }

  Future<String?> uploadOrderVideo({
    required String productId,
    required String filePath,
  }) async {
    final token = AuthService.instance.currentToken;
    if (token == null || token.isEmpty) {
      emit(
        UploadOrderFileErrorState(
          S.current.pleaseLoginToUploadVideos,
          'orderVideo',
        ),
      );
      return null;
    }

    emit(const UploadOrderFileLoadingState('orderVideo'));
    final result = await _uploadOrderVideoUseCase(
      UploadOrderFileParams(
        productId: productId,
        filePath: filePath,
        token: token,
      ),
    );

    return result.fold(
      (failure) {
        emit(UploadOrderFileErrorState(failure.message, 'orderVideo'));
        return null;
      },
      (path) {
        emit(UploadOrderFileSuccessState(path, 'orderVideo'));
        return path;
      },
    );
  }

  Future<String?> createOrder({required CreateOrderRequest request, required BuildContext context}) async {
    final token = AuthService.instance.currentToken;
    if (token == null || token.isEmpty) {
      emit(CreateOrderErrorState(S.of(context).pleaseLoginToCreateAnOrder));
      return null;
    }

    emit(CreateOrderLoadingState());
    final result = await _createOrderUseCase(
      CreateOrderParams(request: request, token: token),
    );

    return result.fold(
      (failure) {
        emit(CreateOrderErrorState(failure.message));
        return null;
      },
      (orderId) {
        emit(CreateOrderSuccessState(orderId));
        return orderId;
      },
    );
  }

  Future<String?> createOrderWithLocalAssets({
    required CreateOrderRequest request,
    List<String> localImagePaths = const [],
    List<String> localVideoPaths = const [],
  }) async {
    emit(CreateOrderLoadingState());

    final result = await _createOrderWithLocalAssetsInternal(
      request: request,
      localImagePaths: localImagePaths,
      localVideoPaths: localVideoPaths,
    );

    if (result.orderId != null) {
      emit(CreateOrderSuccessState(result.orderId!));
      return result.orderId;
    }

    emit(CreateOrderErrorState(result.error ?? 'Failed to create order.'));
    return null;
  }

  Future<void> submitBookingOrder() async {
    final form = _bookingOrderFormState;
    final product = currentBookingProduct;
    if (form == null || product == null) return;

    if (ProductOwnershipHelper.isOwnedByCurrentUser(product)) {
      emit(BookingOrderErrorState(S.current.cannotOrderOwnProduct));
      return;
    }

    final quantity = bookingOrderQuantity;
    final unitPrice = bookingOrderUnitPrice(product);
    final totalPrice = unitPrice * quantity;

    if (quantity <= 0 || unitPrice <= 0) {
      emit(
        BookingOrderErrorState(S.current.enterValidQuantityAndPrice),
      );
      return;
    }

    final toUserId = bookingToUserId.trim().isNotEmpty
        ? bookingToUserId
        : product.ownerId;
    if (toUserId.trim().isEmpty) {
      emit(
        BookingOrderErrorState(S.current.productOwnerMissingCannotSubmitOrder),
      );
      return;
    }

    final portName =
        form.selectedPort ?? bookingOrderPortController.text.trim();
    final requiresPort = !product.isCategoryCatalogProduct;
    if (requiresPort && portName.isEmpty) {
      emit(
        const BookingOrderErrorState('Please select a port of arrival.'),
      );
      return;
    }

    emit(form.copyWith(isSubmitting: true));

    final unitName = CreateAdFormMapper.mapUnitName(
      product.unitName.trim().isEmpty ? 'Ton' : product.unitName.trim(),
    );

    final result = await _createOrderWithLocalAssetsInternal(
      request: CreateOrderRequest(
        toUserId: toUserId,
        productId: product.productId,
        supplierEmail: AuthService.instance.currentUserEmail ?? '',
        unitName: unitName,
        quantity: quantity,
        unitPrice: unitPrice,
        totalPrice: totalPrice,
        paymentMethodName: CartPaymentMethod.cash.apiValue,
        notes: bookingOrderNotesController.text.trim(),
        addressLine: requiresPort ? portName : '',
        cityName: form.selectedCountry ?? '',
        portName: requiresPort && portName.isNotEmpty ? portName : null,
      ),
    );

    if (result.orderId != null) {
      emit(BookingOrderSuccessState(result.orderId!));
      return;
    }

    emit(
      BookingOrderErrorState(
        result.error ?? 'Failed to submit booking order. Please try again.',
      ),
    );
    final latest = _bookingOrderFormState ?? form;
    emit(latest.copyWith(isSubmitting: false));
  }

  @override
  Future<void> close() {
    _stopPaymentPolling();
    quantityController.dispose();
    priceController.dispose();
    notesController.dispose();
    bookingOfferController.dispose();
    bookingOrderQuantityController.dispose();
    bookingOrderPortController.dispose();
    bookingOrderNotesController.dispose();
    offerOrderQuantityController.dispose();
    return super.close();
  }
}

class _ProductsByTypeBucket {
  List<MyListingProductModel> items = [];
  bool isLoading = false;
  bool isLoadingMore = false;
  String? error;
  int fetchGeneration = 0;
  int page = 1;
  int totalPages = 1;
  int pageSize = ClintCubit.homeFeedPageSize;
}
