import 'dart:async';

import 'package:alrasmarket/core/cache/api_cache_store.dart';
import 'package:alrasmarket/core/serveses/auth_service.dart';
import 'package:alrasmarket/core/serveses/product_search_index_service.dart';
import 'package:alrasmarket/core/services_locator/services_locator.dart';
import 'package:alrasmarket/features/clint/presentation/controller/cubit/clint_cubit.dart';
import 'package:alrasmarket/features/company/presentation/controller/cubit/company_cubit.dart';
import 'package:flutter/foundation.dart';

/// Keeps catalog and seller listings in sync after mutations or server events.
///
/// Pattern: invalidate disk cache → refresh in-memory state from network
/// (same approach as order list invalidation in this app).
class CatalogSyncService {
  CatalogSyncService._();

  static final CatalogSyncService instance = CatalogSyncService._();

  bool _mutationSyncInFlight = false;

  bool get _isPersonAccount =>
      AuthService.instance.isPersonalCustomerAccount;

  /// Call after create/update/delete ad or when admin approves a listing.
  Future<void> afterAdMutation() async {
    if (_mutationSyncInFlight) return;
    _mutationSyncInFlight = true;
    try {
      await _invalidateProductDiskCache();
      unawaited(ProductSearchIndexService.instance.refresh());

      final clintCubit = sl<ClintCubit>();
      if (!clintCubit.isClosed) {
        unawaited(
          clintCubit.refreshCatalogAfterMutation(isPerson: _isPersonAccount),
        );
      }

      final companyCubit = sl<CompanyCubit>();
      if (!companyCubit.isClosed) {
        unawaited(companyCubit.reloadMyListings());
      }
    } catch (e, st) {
      debugPrint('CatalogSyncService.afterAdMutation failed: $e\n$st');
    } finally {
      _mutationSyncInFlight = false;
    }
  }

  /// Lighter refresh when user opens the home tab (revalidate from server).
  void onHomeTabSelected() {
    final clintCubit = sl<ClintCubit>();
    if (clintCubit.isClosed) return;
    // Reset disk cache so commission markup changes appear without waiting for TTL.
    clintCubit.refreshHomeFeed(
      isPerson: _isPersonAccount,
      resetCached: true,
    );
  }

  /// Reload seller listings when user opens My Ads tab.
  void onMyAdsTabSelected() {
    final companyCubit = sl<CompanyCubit>();
    if (companyCubit.isClosed) return;
    unawaited(companyCubit.reloadMyListings());
  }

  /// Push / background events about product approval or listing changes.
  Future<void> onProductNotification() => afterAdMutation();

  Future<void> _invalidateProductDiskCache() async {
    await ApiCacheStore.instance.invalidateHomeCatalog();
  }
}
