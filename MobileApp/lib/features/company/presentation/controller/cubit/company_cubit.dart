import 'dart:async';

import 'package:alrasmarket/core/serveses/catalog_sync_service.dart';
import 'package:alrasmarket/core/serveses/auth_service.dart';
import 'package:alrasmarket/features/company/data/models/my_listing_product_model.dart';
import 'package:alrasmarket/features/company/data/models/my_request_offer_model.dart';
import 'package:alrasmarket/features/company/data/models/request_offer_order_status.dart';
import 'package:alrasmarket/features/company/domain/usecases/ad_offers_usecases.dart';
import 'package:alrasmarket/features/company/domain/usecases/create_ad_usecases.dart';
import 'package:alrasmarket/generated/l10n.dart' show S;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'company_states.dart';

class CompanyCubit extends Cubit<CompanyStates> {
  CompanyCubit({
    required GetMyListingsUseCase getMyListingsUseCase,
    required DeleteProductUseCase deleteProductUseCase,
    required UpdateProductListingStatusUseCase updateProductListingStatusUseCase,
    required MarkProductSoldOutUseCase markProductSoldOutUseCase,
    required GetMyOffersOnMyRequestsUseCase getMyOffersOnMyRequestsUseCase,
    required UpdateOrderStatusUseCase updateOrderStatusUseCase,
  })  : _getMyListingsUseCase = getMyListingsUseCase,
        _deleteProductUseCase = deleteProductUseCase,
        _updateProductListingStatusUseCase = updateProductListingStatusUseCase,
        _markProductSoldOutUseCase = markProductSoldOutUseCase,
        _getMyOffersOnMyRequestsUseCase = getMyOffersOnMyRequestsUseCase,
        _updateOrderStatusUseCase = updateOrderStatusUseCase,
        super(CompanyInitialState());

  final GetMyListingsUseCase _getMyListingsUseCase;
  final DeleteProductUseCase _deleteProductUseCase;
  final UpdateProductListingStatusUseCase _updateProductListingStatusUseCase;
  final MarkProductSoldOutUseCase _markProductSoldOutUseCase;
  final GetMyOffersOnMyRequestsUseCase _getMyOffersOnMyRequestsUseCase;
  final UpdateOrderStatusUseCase _updateOrderStatusUseCase;

  static CompanyCubit get(context) => BlocProvider.of(context);

  int currentIndex = 0;
  CompanyMyListingsState? _cachedListingsState;
  static const int _requestOffersPageSize = 20;

  void setTab(int index) {
    currentIndex = index;
    emit(CompanyTabState(index));
    if (index == 0) {
      CatalogSyncService.instance.onHomeTabSelected();
    } else if (index == 3) {
      unawaited(reloadMyListings());
    }
  }

  String? get _token => AuthService.instance.currentToken;

  Future<void> loadMyListings(BuildContext context) async {
    await reloadMyListings(
      loginErrorMessage: S.of(context).pleaseLoginToViewYourAds,
    );
  }

  Future<void> reloadMyListings({String? loginErrorMessage}) async {
    // Preserve filters before emitting loading (loading used to wipe them).
    final preservedTypeFilter = _currentTypeFilter();
    final preservedStatusFilter = _currentStatusFilter();
    final previousProducts = state is CompanyMyListingsState
        ? (state as CompanyMyListingsState).products
        : (_cachedListingsState?.products ?? const <MyListingProductModel>[]);

    emit(
      CompanyMyListingsState(
        isLoading: true,
        products: previousProducts,
        typeFilter: preservedTypeFilter,
        statusFilter: preservedStatusFilter,
      ),
    );

    final token = _token;
    if (token == null || token.isEmpty) {
      emit(
        CompanyMyListingsState(
          isLoading: false,
          products: const [],
          typeFilter: preservedTypeFilter,
          statusFilter: preservedStatusFilter,
          errorMessage:
              loginErrorMessage ?? 'Please log in to view your ads.',
        ),
      );
      return;
    }

    final result = await _getMyListingsUseCase(token: token);
    result.fold(
      (failure) => emit(
        CompanyMyListingsState(
          isLoading: false,
          products: const [],
          typeFilter: preservedTypeFilter,
          statusFilter: preservedStatusFilter,
          errorMessage: failure.message,
        ),
      ),
      (response) {
        final next = CompanyMyListingsState(
          isLoading: false,
          products: response.products,
          typeFilter: preservedTypeFilter,
          statusFilter: preservedStatusFilter,
        );
        _cachedListingsState = next;
        emit(next);
      },
    );
  }

  MyListingProductModel? findListingProduct(String productId) {
    if (productId.isEmpty) return null;

    Iterable<MyListingProductModel> products = const [];
    final current = state;
    if (current is CompanyMyListingsState) {
      products = current.products;
    } else if (_cachedListingsState != null) {
      products = _cachedListingsState!.products;
    }

    for (final product in products) {
      if (product.productId == productId) return product;
    }
    return null;
  }

  /// GET /api/Orders/getMyOffersOnMyRequests
  Future<void> loadMyRequestOffers({
    required String productId,
    required String productName,
    int page = 1,
    int? statusId,
    bool loadMore = false,
  }) async {
    if (!loadMore) {
      if (state is CompanyMyListingsState) {
        _cachedListingsState = state as CompanyMyListingsState;
      }
      emit(
        CompanyAdRequestOffersState(
          productId: productId,
          productName: productName,
          isLoading: true,
          isLoadingMore: false,
          isUpdatingStatus: false,
          offers: loadMore && state is CompanyAdRequestOffersState
              ? (state as CompanyAdRequestOffersState).offers
              : const [],
          page: page,
          totalPages: 0,
          totalCount: 0,
        ),
      );
    } else {
      final current = state;
      if (current is! CompanyAdRequestOffersState) return;
      emit(current.copyWith(isLoadingMore: true, clearErrorMessage: true));
    }

    final token = _token;
    if (token == null || token.isEmpty) {
      emit(
        CompanyAdRequestOffersState(
          productId: productId,
          productName: productName,
          isLoading: false,
          isLoadingMore: false,
          isUpdatingStatus: false,
          offers: const [],
          page: page,
          totalPages: 0,
          totalCount: 0,
          errorMessage: S.current.pleaseLoginToContinue,
        ),
      );
      return;
    }

    final result = await _getMyOffersOnMyRequestsUseCase(
      GetMyOffersOnMyRequestsParams(
        page: page,
        pageSize: _requestOffersPageSize,
        token: token,
        productId: productId,
        statusId: statusId,
      ),
    );

    result.fold(
      (failure) {
        final current = state;
        if (current is CompanyAdRequestOffersState) {
          emit(
            current.copyWith(
              isLoading: false,
              isLoadingMore: false,
              errorMessage: failure.message,
            ),
          );
          return;
        }
        emit(
          CompanyAdRequestOffersState(
            productId: productId,
            productName: productName,
            isLoading: false,
            isLoadingMore: false,
            isUpdatingStatus: false,
            offers: const [],
            page: page,
            totalPages: 0,
            totalCount: 0,
            errorMessage: failure.message,
          ),
        );
      },
      (response) {
        final current = state;
        final previousOffers = current is CompanyAdRequestOffersState
            ? current.offers
            : <MyRequestOfferModel>[];
        final mergedOffers = loadMore
            ? [...previousOffers, ...response.items]
            : response.items;

        emit(
          CompanyAdRequestOffersState(
            productId: productId,
            productName: productName,
            isLoading: false,
            isLoadingMore: false,
            isUpdatingStatus: false,
            offers: mergedOffers,
            page: response.page,
            totalPages: response.totalPages,
            totalCount: response.totalCount,
          ),
        );
      },
    );
  }

  Future<void> loadMoreMyRequestOffers({int? statusId}) async {
    final current = state;
    if (current is! CompanyAdRequestOffersState) return;
    if (current.isLoadingMore || !current.hasMore) return;

    await loadMyRequestOffers(
      productId: current.productId,
      productName: current.productName,
      page: current.page + 1,
      statusId: statusId,
      loadMore: true,
    );
  }

  /// PATCH /api/Orders/{orderId}/status — statusId 2 Approved
  Future<String?> acceptRequestOffer(int orderId) {
    return _updateRequestOfferStatus(
      orderId: orderId,
      statusId: RequestOfferOrderStatus.approved,
    );
  }

  /// PATCH /api/Orders/{orderId}/status — statusId 6 Cancelled
  Future<String?> rejectRequestOffer(int orderId) {
    return _updateRequestOfferStatus(
      orderId: orderId,
      statusId: RequestOfferOrderStatus.cancelled,
    );
  }

  Future<String?> _updateRequestOfferStatus({
    required int orderId,
    required int statusId,
  }) async {
    final current = state;
    if (current is! CompanyAdRequestOffersState) {
      return 'Invalid state';
    }

    final token = _token;
    if (token == null || token.isEmpty) {
      return S.current.pleaseLoginToContinue;
    }

    emit(
      current.copyWith(
        isUpdatingStatus: true,
        updatingOrderId: orderId,
        clearErrorMessage: true,
      ),
    );

    final result = await _updateOrderStatusUseCase(
      UpdateOrderStatusParams(
        orderId: orderId,
        statusId: statusId,
        token: token,
      ),
    );

    return result.fold(
      (failure) {
        emit(
          current.copyWith(
            isUpdatingStatus: false,
            clearUpdatingOrderId: true,
            errorMessage: failure.message,
          ),
        );
        return failure.message;
      },
      (_) async {
        await loadMyRequestOffers(
          productId: current.productId,
          productName: current.productName,
        );
        unawaited(CatalogSyncService.instance.afterAdMutation());
        return null;
      },
    );
  }

  void restoreListingsState() {
    final cached = _cachedListingsState;
    if (cached != null) {
      emit(cached);
    }
  }

  /// DELETE /api/Products/{productId}
  Future<String?> deleteProduct(String productId, BuildContext context) async {
    final token = _token;
    if (token == null || token.isEmpty) {
      return S.of(context).pleaseLoginToContinue;
    }

    final result = await _deleteProductUseCase(
      productId: productId,
      token: token,
    );

    return result.fold(
      (failure) => failure.message,
      (_) async {
        unawaited(CatalogSyncService.instance.afterAdMutation());
        return null;
      },
    );
  }

  /// PATCH /api/Products/{productId}/listing-status
  Future<String?> updateListingStatus({
    required String productId,
    required bool isActive,
    required BuildContext context,
  }) async {
    final token = _token;
    if (token == null || token.isEmpty) {
      return S.of(context).pleaseLoginToContinue;
    }

    final result = await _updateProductListingStatusUseCase(
      productId: productId,
      isActive: isActive,
      token: token,
    );

    return result.fold(
      (failure) => failure.message,
      (_) async {
        unawaited(CatalogSyncService.instance.afterAdMutation());
        return null;
      },
    );
  }

  /// PATCH /api/Products/{productId}/sold-out
  Future<String?> markSoldOut({
    required String productId,
    required BuildContext context,
  }) async {
    final token = _token;
    if (token == null || token.isEmpty) {
      return S.of(context).pleaseLoginToContinue;
    }

    final result = await _markProductSoldOutUseCase(
      productId: productId,
      token: token,
    );

    return result.fold(
      (failure) => failure.message,
      (_) async {
        unawaited(CatalogSyncService.instance.afterAdMutation());
        unawaited(reloadMyListings());
        return null;
      },
    );
  }

  String? _currentTypeFilter() {
    final current = state;
    if (current is CompanyMyListingsState) return current.typeFilter;
    return _cachedListingsState?.typeFilter;
  }

  String? _currentStatusFilter() {
    final current = state;
    if (current is CompanyMyListingsState) return current.statusFilter;
    return _cachedListingsState?.statusFilter;
  }

  void setMyListingsFilter(String? productTypeName) {
    final current = state;
    if (current is! CompanyMyListingsState) return;

    final next = current.copyWith(
      typeFilter: productTypeName,
      clearTypeFilter: productTypeName == null,
    );
    _cachedListingsState = next;
    emit(next);
  }

  void setMyListingsStatusFilter(String? statusFilter) {
    final current = state;
    if (current is! CompanyMyListingsState) return;

    final next = current.copyWith(
      statusFilter: statusFilter,
      clearStatusFilter: statusFilter == null,
    );
    _cachedListingsState = next;
    emit(next);
  }
}
