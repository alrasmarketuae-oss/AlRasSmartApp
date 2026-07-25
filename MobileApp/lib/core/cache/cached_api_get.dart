import 'dart:async';

import 'package:alrasmarket/core/cache/api_cache_store.dart';

typedef CachedApiParser<T> = T Function(dynamic json);
typedef CachedApiSerializer = dynamic Function();

/// Cache-first GET helper with optional background refresh (stale-while-revalidate).
class CachedApiGet {
  CachedApiGet._();

  /// Returns cached value immediately when fresh; refreshes in background when stale.
  /// On network failure returns stale cache when [allowStaleOnError] is true.
  static Future<T?> load<T>({
    required String cacheKey,
    required Duration ttl,
    required Future<T> Function() fetch,
    required CachedApiParser<T> parse,
    required dynamic Function(T value) serialize,
    bool forceRefresh = false,
    bool allowStaleOnError = true,
    void Function(T value)? onBackgroundUpdated,
  }) async {
    final store = ApiCacheStore.instance;

    if (!forceRefresh) {
      final cached = await store.read(cacheKey);
      if (cached != null) {
        try {
          final parsed = parse(cached.data);
          if (!cached.isFresh) {
            unawaited(
              _refresh(
                cacheKey: cacheKey,
                ttl: ttl,
                fetch: fetch,
                serialize: serialize,
                onUpdated: onBackgroundUpdated,
              ),
            );
          }
          return parsed;
        } catch (_) {
          await store.remove(cacheKey);
        }
      }
    }

    try {
      final fresh = await fetch();
      await store.write(cacheKey, serialize(fresh), ttl);
      return fresh;
    } catch (_) {
      if (!allowStaleOnError) rethrow;
      final stale = await store.read(cacheKey, allowStale: true);
      if (stale == null) rethrow;
      return parse(stale.data);
    }
  }

  static Future<void> _refresh<T>({
    required String cacheKey,
    required Duration ttl,
    required Future<T> Function() fetch,
    required dynamic Function(T value) serialize,
    void Function(T value)? onUpdated,
  }) async {
    try {
      final fresh = await fetch();
      await ApiCacheStore.instance.write(cacheKey, serialize(fresh), ttl);
      onUpdated?.call(fresh);
    } catch (_) {
      // Keep stale cache on background refresh failure.
    }
  }
}
