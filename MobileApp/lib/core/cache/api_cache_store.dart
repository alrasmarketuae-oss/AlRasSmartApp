import 'dart:convert';
import 'dart:io';

import 'package:alrasmarket/core/platform/app_paths.dart';
import 'package:flutter/foundation.dart';

import 'api_cache_keys.dart';

class ApiCacheEntry {
  const ApiCacheEntry({
    required this.data,
    required this.fetchedAt,
    required this.ttl,
  });

  final dynamic data;
  final DateTime fetchedAt;
  final Duration ttl;

  bool get isFresh =>
      DateTime.now().difference(fetchedAt) <= ttl;

  bool get isStaleButUsable =>
      !isFresh &&
      DateTime.now().difference(fetchedAt) <= ApiCacheTtl.maxStale;
}

/// Disk-backed JSON cache for API GET responses (stale-while-revalidate).
class ApiCacheStore {
  ApiCacheStore._();

  static final ApiCacheStore instance = ApiCacheStore._();

  static const _dirName = 'api_cache';
  Directory? _cacheDir;

  Future<void> init() async {
    if (_cacheDir != null || kIsWeb) return;
    try {
      final docsPath = await appDocumentsPath();
      if (docsPath == null) return;
      _cacheDir = Directory('$docsPath/$_dirName');
      if (!await _cacheDir!.exists()) {
        await _cacheDir!.create(recursive: true);
      }
    } catch (e) {
      debugPrint('ApiCacheStore init skipped: $e');
    }
  }

  Future<ApiCacheEntry?> read(
    String key, {
    bool allowStale = false,
  }) async {
    if (kIsWeb) return null;
    await init();
    if (_cacheDir == null) return null;
    final file = _fileForKey(key);
    if (!await file.exists()) return null;

    try {
      final raw = await file.readAsString();
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return null;

      final fetchedAtRaw = decoded['fetchedAt']?.toString();
      final fetchedAt = DateTime.tryParse(fetchedAtRaw ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0);
      final ttlSeconds = decoded['ttlSeconds'] as int? ?? 0;
      final ttl = Duration(seconds: ttlSeconds);
      final data = decoded['data'];

      final entry = ApiCacheEntry(
        data: data,
        fetchedAt: fetchedAt,
        ttl: ttl,
      );

      if (entry.isFresh || (allowStale && entry.isStaleButUsable)) {
        return entry;
      }
      return null;
    } catch (e) {
      debugPrint('ApiCacheStore read failed ($key): $e');
      return null;
    }
  }

  Future<void> write(
    String key,
    dynamic data,
    Duration ttl,
  ) async {
    if (kIsWeb) return;
    await init();
    if (_cacheDir == null) return;
    final payload = jsonEncode({
      'fetchedAt': DateTime.now().toUtc().toIso8601String(),
      'ttlSeconds': ttl.inSeconds,
      'data': data,
    });
    await _fileForKey(key).writeAsString(payload, flush: true);
  }

  Future<void> remove(String key) async {
    if (kIsWeb) return;
    await init();
    if (_cacheDir == null) return;
    final file = _fileForKey(key);
    if (await file.exists()) {
      await file.delete();
    }
  }

  Future<void> removeByPrefix(String prefix) async {
    if (kIsWeb) return;
    await init();
    if (_cacheDir == null) return;

    await for (final entity in _cacheDir!.list()) {
      if (entity is! File) continue;
      final name = entity.uri.pathSegments.last;
      if (name.startsWith(_safeFileName(prefix))) {
        await entity.delete();
      }
    }
  }

  Future<void> clearAll() async {
    if (kIsWeb) return;
    await init();
    if (_cacheDir == null) return;
    if (await _cacheDir!.exists()) {
      await _cacheDir!.delete(recursive: true);
      await _cacheDir!.create(recursive: true);
    }
  }

  /// Clears product/banner caches (e.g. after login refresh or ad mutation).
  /// Categories are cached separately — use [invalidateCategoriesCache].
  Future<void> invalidateHomeCatalog() async {
    await remove(ApiCacheKeys.homeBanners);
    await removeByPrefix(ApiCacheKeys.homePrefix);
  }

  Future<void> invalidateCategoriesCache() async {
    await remove(ApiCacheKeys.categories);
  }

  /// Clears user-specific caches (orders, profile, addresses).
  Future<void> invalidateUserData() async {
    await removeByPrefix(ApiCacheKeys.userPrefix);
  }

  /// Clears cached order lists so status changes are shown immediately.
  Future<void> invalidateUserOrders() async {
    await removeByPrefix(ApiCacheKeys.userOrdersPrefix);
  }

  File _fileForKey(String key) {
    final safe = _safeFileName(key);
    return File('${_cacheDir!.path}/$safe.json');
  }

  String _safeFileName(String key) =>
      key.replaceAll(RegExp(r'[^\w\-.]'), '_');
}
