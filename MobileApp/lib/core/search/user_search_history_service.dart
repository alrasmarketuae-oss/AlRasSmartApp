import 'dart:convert';
import 'dart:io';

import 'package:alrasmarket/core/platform/app_paths.dart';
import 'package:alrasmarket/core/search/search_history_entry.dart';
import 'package:alrasmarket/core/serveses/auth_service.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';

/// Per-user product search history (text, product code, image + cached AI results).
class UserSearchHistoryService {
  UserSearchHistoryService._();

  static final UserSearchHistoryService instance = UserSearchHistoryService._();

  static const _maxEntries = 30;
  static const _dirName = 'search_history';

  Directory? _rootDir;

  Future<Directory?> _ensureRootDir() async {
    if (kIsWeb) return null;
    if (_rootDir != null) return _rootDir;
    final docsPath = await appDocumentsPath();
    if (docsPath == null) return null;
    _rootDir = Directory(p.join(docsPath, _dirName));
    if (!await _rootDir!.exists()) {
      await _rootDir!.create(recursive: true);
    }
    return _rootDir;
  }

  String _prefsKey() => 'search_history_${_userKey()}';

  Future<List<SearchHistoryEntry>> _loadEntriesFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefsKey());
      if (raw == null || raw.isEmpty) return const [];
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      return decoded
          .whereType<Map>()
          .map((item) => SearchHistoryEntry.fromJson(Map<String, dynamic>.from(item)))
          .where((entry) => entry.id.isNotEmpty)
          .toList(growable: false);
    } catch (e) {
      debugPrint('UserSearchHistoryService prefs load failed: $e');
      return const [];
    }
  }

  Future<void> _writeEntriesToPrefs(List<SearchHistoryEntry> entries) async {
    final prefs = await SharedPreferences.getInstance();
    final payload = jsonEncode(entries.map((item) => item.toJson()).toList());
    await prefs.setString(_prefsKey(), payload);
  }

  String _userKey() {
    final userId = AuthService.instance.currentUserID?.trim();
    if (userId != null && userId.isNotEmpty) return userId;
    return 'guest';
  }

  Future<File?> _historyFile() async {
    final root = await _ensureRootDir();
    if (root == null) return null;
    return File(p.join(root.path, '${_userKey()}.json'));
  }

  Future<List<SearchHistoryEntry>> loadEntries() async {
    if (kIsWeb) return _loadEntriesFromPrefs();

    final file = await _historyFile();
    if (file == null || !await file.exists()) return const [];

    try {
      final decoded = jsonDecode(await file.readAsString());
      if (decoded is! List) return const [];

      final entries = decoded
          .whereType<Map>()
          .map((item) => SearchHistoryEntry.fromJson(Map<String, dynamic>.from(item)))
          .where((entry) => entry.id.isNotEmpty)
          .toList(growable: false);

      return _pruneMissingImages(entries);
    } catch (e) {
      debugPrint('UserSearchHistoryService load failed: $e');
      return const [];
    }
  }

  Future<SearchHistoryEntry?> getEntryById(String id) async {
    final entries = await loadEntries();
    for (final entry in entries) {
      if (entry.id == id) return entry;
    }
    return null;
  }

  /// Finds a persisted image-search entry by its stored image file path.
  Future<SearchHistoryEntry?> getEntryByImagePath(String imagePath) async {
    final normalized = imagePath.trim();
    if (normalized.isEmpty) return null;

    final entries = await loadEntries();
    for (final entry in entries) {
      if (entry.type != SearchHistoryType.image) continue;
      final stored = entry.imagePath?.trim() ?? '';
      if (stored.isNotEmpty && stored == normalized) return entry;
    }
    return null;
  }

  Future<void> addEntry({
    required SearchHistoryType type,
    required String label,
    String? query,
    String? sourceImagePath,
    List<String> suggestedNames = const [],
    List<Map<String, dynamic>> products = const [],
  }) async {
    final normalizedQuery = query?.trim();
    final now = DateTime.now().millisecondsSinceEpoch;
    final id = now.toString();

    String? persistedImagePath;
    if (type == SearchHistoryType.image &&
        sourceImagePath != null &&
        sourceImagePath.trim().isNotEmpty) {
      persistedImagePath = await _persistImageCopy(
        sourceImagePath,
        entryId: id,
      );
    }

    final entry = SearchHistoryEntry(
      id: id,
      type: type,
      label: label,
      createdAtMs: now,
      query: normalizedQuery,
      imagePath: persistedImagePath,
      suggestedNames: suggestedNames,
      products: products,
    );

    var entries = await loadEntries();
    entries = entries.where((item) => !_isDuplicate(item, entry)).toList();
    entries = [entry, ...entries];
    if (entries.length > _maxEntries) {
      final removed = entries.sublist(_maxEntries);
      entries = entries.sublist(0, _maxEntries);
      await _deleteImagesForEntries(removed);
    }

    await _writeEntries(entries);
  }

  Future<void> removeEntry(String id) async {
    final entries = await loadEntries();
    final target = entries.where((item) => item.id == id).toList();
    final remaining = entries.where((item) => item.id != id).toList();
    await _deleteImagesForEntries(target);
    await _writeEntries(remaining);
  }

  Future<void> clearAll() async {
    final entries = await loadEntries();
    if (!kIsWeb) {
      await _deleteImagesForEntries(entries);
    }
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_prefsKey());
      return;
    }
    final file = await _historyFile();
    if (file != null && await file.exists()) {
      await file.delete();
    }
  }

  bool _isDuplicate(SearchHistoryEntry existing, SearchHistoryEntry incoming) {
    if (incoming.type == SearchHistoryType.image) {
      if (existing.type != SearchHistoryType.image) return false;
      if (existing.suggestedNames.join('|').toLowerCase() ==
          incoming.suggestedNames.join('|').toLowerCase()) {
        return true;
      }
      return false;
    }

    final existingQuery = existing.query?.trim().toLowerCase() ?? '';
    final incomingQuery = incoming.query?.trim().toLowerCase() ?? '';
    return existingQuery.isNotEmpty && existingQuery == incomingQuery;
  }

  Future<void> _writeEntries(List<SearchHistoryEntry> entries) async {
    if (kIsWeb) {
      await _writeEntriesToPrefs(entries);
      return;
    }
    final file = await _historyFile();
    if (file == null) return;
    final payload = jsonEncode(entries.map((item) => item.toJson()).toList());
    await file.writeAsString(payload);
  }

  Future<String?> _persistImageCopy(
    String sourcePath, {
    required String entryId,
  }) async {
    if (kIsWeb) return sourcePath;
    try {
      final source = File(sourcePath);
      if (!await source.exists()) return null;

      final root = await _ensureRootDir();
      if (root == null) return sourcePath;
      final imagesDir = Directory(p.join(root.path, _userKey(), 'images'));
      if (!await imagesDir.exists()) {
        await imagesDir.create(recursive: true);
      }

      final ext = p.extension(sourcePath).isEmpty ? '.jpg' : p.extension(sourcePath);
      final dest = File(p.join(imagesDir.path, '$entryId$ext'));
      await source.copy(dest.path);
      return dest.path;
    } catch (e) {
      debugPrint('UserSearchHistoryService image copy failed: $e');
      return null;
    }
  }

  Future<void> _deleteImagesForEntries(List<SearchHistoryEntry> entries) async {
    for (final entry in entries) {
      final imagePath = entry.imagePath;
      if (imagePath == null || imagePath.trim().isEmpty) continue;
      try {
        final file = File(imagePath);
        if (await file.exists()) {
          await file.delete();
        }
      } catch (_) {}
    }
  }

  List<SearchHistoryEntry> _pruneMissingImages(List<SearchHistoryEntry> entries) {
    if (kIsWeb) return entries;
    return entries
        .map((entry) {
          if (entry.type != SearchHistoryType.image) return entry;
          final imagePath = entry.imagePath;
          if (imagePath == null || imagePath.isEmpty) return entry;
          if (File(imagePath).existsSync()) return entry;
          return SearchHistoryEntry(
            id: entry.id,
            type: entry.type,
            label: entry.label,
            createdAtMs: entry.createdAtMs,
            query: entry.query,
            suggestedNames: entry.suggestedNames,
            products: entry.products,
          );
        })
        .toList(growable: false);
  }
}
