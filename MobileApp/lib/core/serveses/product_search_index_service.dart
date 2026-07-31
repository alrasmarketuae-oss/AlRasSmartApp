import 'dart:async';

import 'package:alrasmarket/core/services/api_constants.dart';
import 'package:alrasmarket/core/services/dio_helper.dart';
import 'package:flutter/foundation.dart';

/// Server-backed product search autocomplete (Meilisearch via API).
///
/// No longer downloads the full product-name catalog to the device.
class ProductSearchIndexService {
  ProductSearchIndexService._();

  static final ProductSearchIndexService instance = ProductSearchIndexService._();

  static const _debounce = Duration(milliseconds: 120);

  Timer? _debounceTimer;
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
    final normalized = query.trim().toLowerCase();
    if (normalized.isEmpty) return const [];
    if (normalized == _lastQuery) {
      return _lastSuggestions.take(limit);
    }
    return const [];
  }

  /// Debounced remote suggestions for the search field.
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

    final completer = Completer<List<String>>();
    final seq = ++_requestSeq;
    _debounceTimer?.cancel();
    _debounceTimer = Timer(_debounce, () async {
      try {
        final response = await DioHelper.getData(
          url: ApiConstants.productsSearchSuggestEndPoint,
          query: {
            'q': normalized,
            'limit': limit,
          },
        );

        if (seq != _requestSeq) {
          if (!completer.isCompleted) {
            completer.complete(_lastSuggestions.take(limit).toList());
          }
          return;
        }

        if (response?.statusCode != 200) {
          debugPrint(
            'ProductSearchIndexService suggest HTTP ${response?.statusCode}',
          );
          if (!completer.isCompleted) completer.complete(const []);
          return;
        }

        final suggestions = _parseSuggestions(response?.data);
        _lastQuery = lower;
        _lastSuggestions = suggestions;
        if (!completer.isCompleted) {
          completer.complete(suggestions.take(limit).toList());
        }
      } catch (e) {
        debugPrint('ProductSearchIndexService suggest error: $e');
        if (!completer.isCompleted) completer.complete(const []);
      }
    });

    return completer.future;
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
