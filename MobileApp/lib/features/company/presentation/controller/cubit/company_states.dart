import 'package:alrasmarket/core/utils/product_stock.dart';
import 'package:alrasmarket/features/company/data/models/my_listing_product_model.dart';
import 'package:alrasmarket/features/company/data/models/my_request_offer_model.dart';
import 'package:alrasmarket/features/company/presentation/models/create_ad_type.dart';
import 'package:alrasmarket/features/company/presentation/models/my_ads_filter.dart';
import 'package:equatable/equatable.dart';

abstract class CompanyStates extends Equatable {
  const CompanyStates();

  @override
  List<Object?> get props => [];
}

class CompanyInitialState extends CompanyStates {}

class CompanyTabState extends CompanyStates {
  final int index;

  const CompanyTabState(this.index);

  @override
  List<Object?> get props => [index];
}

class CompanyErrorState extends CompanyStates {
  final String message;

  const CompanyErrorState(this.message);

  @override
  List<Object?> get props => [message];
}

class CompanyMyListingsState extends CompanyStates {
  const CompanyMyListingsState({
    required this.isLoading,
    required this.products,
    this.errorMessage,
    this.typeFilter,
    this.statusFilter,
  });

  final bool isLoading;
  final List<MyListingProductModel> products;
  final String? errorMessage;
  final String? typeFilter;
  final String? statusFilter;

  List<MyListingProductModel> get filteredProducts {
    var list = products;
    if (typeFilter != null && typeFilter!.isNotEmpty) {
      if (typeFilter == MyAdsFilter.categoriesFilterKey) {
        list = list
            .where(
              (product) =>
                  product.categoryId != null && product.categoryId! > 0,
            )
            .toList();
      } else {
        final wantedType = CreateAdType.fromLabel(typeFilter);
        list = list.where((product) {
          if (wantedType == null) return false;
          return switch (wantedType) {
            CreateAdType.requests => product.isRequestProduct,
            CreateAdType.offers => product.isOfferProduct,
            CreateAdType.booking => product.isBookingProduct,
            CreateAdType.retail =>
              product.isPureRetailProduct ||
                  product.hasRetailPricing ||
                  product.isRetailProduct,
            CreateAdType.categories =>
              product.categoryId != null && product.categoryId! > 0,
          };
        }).toList();
      }
    }
    if (statusFilter != null && statusFilter!.isNotEmpty) {
      list = list.where(_matchesStatusFilter).toList();
    }
    // Ads that have pending orders/requests float to the top, keeping the
    // backend order within each group (stable partition).
    final withOrders = <MyListingProductModel>[];
    final withoutOrders = <MyListingProductModel>[];
    for (final product in list) {
      if (product.pendingOffersCount > 0) {
        withOrders.add(product);
      } else {
        withoutOrders.add(product);
      }
    }
    return [...withOrders, ...withoutOrders];
  }

  bool get preferRetailPricing =>
      typeFilter != null &&
      typeFilter!.trim().toLowerCase() == 'retail';

  bool _matchesStatusFilter(MyListingProductModel product) {
    // Always match on English/canonical status — display `status` is localized.
    final status = product.statusCanonical.toLowerCase();
    switch (statusFilter) {
      case 'active':
        return (status == 'active' || status.contains('نشط')) &&
            !ProductStock.isSoldOut(
              product,
              preferRetail: preferRetailPricing,
            );
      case 'paused':
        return status.contains('paused') ||
            status.contains('inactive') ||
            status.contains('متوقف');
      case 'review':
        return status.contains('review') || status.contains('مراجع');
      case 'sold_out':
        return ProductStock.isSoldOut(
              product,
              preferRetail: preferRetailPricing,
            ) ||
            status.contains('sold') ||
            status.contains('out of stock') ||
            status.contains('نفد');
      default:
        return true;
    }
  }

  CompanyMyListingsState copyWith({
    bool? isLoading,
    List<MyListingProductModel>? products,
    String? errorMessage,
    String? typeFilter,
    String? statusFilter,
    bool clearErrorMessage = false,
    bool clearTypeFilter = false,
    bool clearStatusFilter = false,
  }) {
    return CompanyMyListingsState(
      isLoading: isLoading ?? this.isLoading,
      products: products ?? this.products,
      errorMessage:
          clearErrorMessage ? null : (errorMessage ?? this.errorMessage),
      typeFilter: clearTypeFilter ? null : (typeFilter ?? this.typeFilter),
      statusFilter:
          clearStatusFilter ? null : (statusFilter ?? this.statusFilter),
    );
  }

  @override
  List<Object?> get props =>
      [isLoading, products, errorMessage, typeFilter, statusFilter];
}

class CompanyAdRequestOffersState extends CompanyStates {
  const CompanyAdRequestOffersState({
    required this.productId,
    required this.productName,
    required this.isLoading,
    required this.isLoadingMore,
    required this.isUpdatingStatus,
    required this.offers,
    required this.page,
    required this.totalPages,
    required this.totalCount,
    this.errorMessage,
    this.updatingOrderId,
  });

  final String productId;
  final String productName;
  final bool isLoading;
  final bool isLoadingMore;
  final bool isUpdatingStatus;
  final List<MyRequestOfferModel> offers;
  final int page;
  final int totalPages;
  final int totalCount;
  final String? errorMessage;
  final int? updatingOrderId;

  bool get hasMore => page < totalPages;

  CompanyAdRequestOffersState copyWith({
    String? productId,
    String? productName,
    bool? isLoading,
    bool? isLoadingMore,
    bool? isUpdatingStatus,
    List<MyRequestOfferModel>? offers,
    int? page,
    int? totalPages,
    int? totalCount,
    String? errorMessage,
    int? updatingOrderId,
    bool clearErrorMessage = false,
    bool clearUpdatingOrderId = false,
  }) {
    return CompanyAdRequestOffersState(
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      isUpdatingStatus: isUpdatingStatus ?? this.isUpdatingStatus,
      offers: offers ?? this.offers,
      page: page ?? this.page,
      totalPages: totalPages ?? this.totalPages,
      totalCount: totalCount ?? this.totalCount,
      errorMessage:
          clearErrorMessage ? null : (errorMessage ?? this.errorMessage),
      updatingOrderId: clearUpdatingOrderId
          ? null
          : (updatingOrderId ?? this.updatingOrderId),
    );
  }

  @override
  List<Object?> get props => [
    productId,
    productName,
    isLoading,
    isLoadingMore,
    isUpdatingStatus,
    offers,
    page,
    totalPages,
    totalCount,
    errorMessage,
    updatingOrderId,
  ];
}
