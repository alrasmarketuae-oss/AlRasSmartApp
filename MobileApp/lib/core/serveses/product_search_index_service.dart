import 'package:alrasmarket/core/services/api_constants.dart';
import 'package:alrasmarket/core/services/dio_helper.dart';
import 'package:flutter/foundation.dart';

/// Server-backed product search autocomplete (Meilisearch via API).
///
/// No longer downloads the full product-name catalog to the device.
class ProductSearchIndexService {
  ProductSearchIndexService._();

  static final ProductSearchIndexService instance = ProductSearchIndexService._();

  int _requestSeq = 0;
  String _lastQuery = '';
  List<String> _lastSuggestions = const [];

  /// Kept for startup compatibility — no bulk download.
  Future<void> init() async {
    debugPrint('ProductSearchIndexService ready (remote suggest)');
  }

  /// No-op: suggestions are fetched per keystroke from the API.
  Future<void> refresh() async {
    _lastQuery = '';
    _lastSuggestions = const [];
  }

  /// Immediate cache hit for the last query (sync callers).
  Iterable<String> suggest(String query, {int limit = 8}) {
    return preview(query, limit: limit);
  }

  /// Instant prefix filter of the last response so the dropdown can update
  /// on every keystroke before the next API round-trip returns.
  Iterable<String> preview(String query, {int limit = 8}) {
    final normalized = query.trim().toLowerCase();
    if (normalized.isEmpty) return const [];
    if (normalized == _lastQuery) {
      return _lastSuggestions.take(limit);
    }
    return _lastSuggestions
        .where((item) => item.toLowerCase().contains(normalized))
        .take(limit);
  }

  /// Remote suggestions for the current query. Stale responses are ignored.
  Future<List<String>> suggestRemote(
    String query, {
    int limit = 8,
  }) async {
    final normalized = query.trim();
    if (normalized.isEmpty) {
      _lastQuery = '';
      _lastSuggestions = const [];
      return const [];
    }

    final lower = normalized.toLowerCase();
    if (lower == _lastQuery && _lastSuggestions.isNotEmpty) {
      return _lastSuggestions.take(limit).toList();
    }

    final seq = ++_requestSeq;
    try {
      final response = await DioHelper.getData(
        url: ApiConstants.productsSearchSuggestEndPoint,
        query: {
          'q': normalized,
          'limit': limit,
        },
      );

      if (seq != _requestSeq) {
        return preview(query, limit: limit).toList();
      }

      if (response?.statusCode != 200) {
        debugPrint(
          'ProductSearchIndexService suggest HTTP ${response?.statusCode}',
        );
        return const [];
      }

      final suggestions = _parseSuggestions(response?.data);
      _lastQuery = lower;
      _lastSuggestions = suggestions;
      return suggestions.take(limit).toList();
    } catch (e) {
      debugPrint('ProductSearchIndexService suggest error: $e');
      if (seq != _requestSeq) {
        return preview(query, limit: limit).toList();
      }
      return const [];
    }
  }

  List<String> _parseSuggestions(dynamic data) {
    if (data is! Map) return const [];
    final raw = data['suggestions'] ?? data['Suggestions'];
    if (raw is! List) return const [];
    return raw
        .map((item) => item.toString().trim())
        .where((item) => item.isNotEmpty)
        .toList();
  }
}
