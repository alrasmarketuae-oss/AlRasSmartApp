import 'package:shared_preferences/shared_preferences.dart';

/// Local bookmarks for marketplace ads (product ids).
class SavedProductsStore {
  SavedProductsStore._();

  static const prefsKey = 'marketplace.bookmarked.product.ids';

  static Future<List<String>> getIds() async {
    final prefs = await SharedPreferences.getInstance();
    return List<String>.from(prefs.getStringList(prefsKey) ?? const <String>[]);
  }

  static Future<bool> isSaved(String productId) async {
    final id = productId.trim();
    if (id.isEmpty) return false;
    final ids = await getIds();
    return ids.contains(id);
  }

  /// Returns the new saved state after toggle.
  static Future<bool> toggle(String productId) async {
    final id = productId.trim();
    if (id.isEmpty) return false;
    final prefs = await SharedPreferences.getInstance();
    final ids = List<String>.from(prefs.getStringList(prefsKey) ?? const <String>[]);
    final next = !ids.contains(id);
    if (next) {
      ids.add(id);
    } else {
      ids.remove(id);
    }
    await prefs.setStringList(prefsKey, ids);
    return next;
  }

  static Future<void> remove(String productId) async {
    final id = productId.trim();
    if (id.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    final ids = List<String>.from(prefs.getStringList(prefsKey) ?? const <String>[]);
    if (ids.remove(id)) {
      await prefs.setStringList(prefsKey, ids);
    }
  }
}
