/// UAE retail checkout: domestic shipping is priced per emirate only.
class UaeRetailEmirates {
  UaeRetailEmirates._();

  static const countryEn = 'United Arab Emirates';
  static const countryAr = 'الإمارات العربية المتحدة';

  static const List<String> namesEn = [
    'Abu Dhabi',
    'Dubai',
    'Sharjah',
    'Ajman',
    'Umm Al Quwain',
    'Ras Al Khaimah',
    'Fujairah',
  ];

  static const List<String> namesAr = [
    'أبو ظبي',
    'دبي',
    'الشارقة',
    'عجمان',
    'أم القيوين',
    'رأس الخيمة',
    'الفجيرة',
  ];

  static String countryLabel(bool isArabic) =>
      isArabic ? countryAr : countryEn;

  static bool matchesCityName(String cityName) {
    final normalized = _normalize(cityName);
    if (normalized.isEmpty) return false;

    for (var i = 0; i < namesEn.length; i++) {
      final en = _normalize(namesEn[i]);
      final ar = _normalize(namesAr[i]);
      if (normalized == en ||
          normalized == ar ||
          normalized.startsWith('$en ') ||
          normalized.startsWith('$ar ')) {
        return true;
      }
    }
    return false;
  }

  static String? canonicalEmirateNameEn(String cityName) {
    if (!matchesCityName(cityName)) return null;
    final index = sortIndex(cityName);
    if (index < 0 || index >= namesEn.length) return null;
    return namesEn[index];
  }

  static int sortIndex(String cityName) {
    final normalized = _normalize(cityName);
    for (var i = 0; i < namesEn.length; i++) {
      if (_normalize(namesEn[i]) == normalized ||
          _normalize(namesAr[i]) == normalized ||
          normalized.startsWith('${_normalize(namesEn[i])} ')) {
        return i;
      }
    }
    return namesEn.length;
  }

  static String displayName(String cityName, bool isArabic) {
    final index = sortIndex(cityName);
    if (index >= 0 && index < namesEn.length) {
      return isArabic ? namesAr[index] : namesEn[index];
    }
    return cityName;
  }

  static String _normalize(String value) =>
      value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');

  /// Keeps one entry per UAE emirate (e.g. Geo API may return many "Dubai" rows).
  static List<T> dedupeByCanonicalEmirate<T>(
    Iterable<T> items,
    String Function(T) cityName,
  ) {
    final byIndex = <int, T>{};
    for (final item in items) {
      final name = cityName(item);
      if (!matchesCityName(name)) continue;
      final index = sortIndex(name);
      if (index < 0 || index >= namesEn.length) continue;
      byIndex.putIfAbsent(index, () => item);
    }

    final sortedKeys = byIndex.keys.toList()..sort();
    return [for (final key in sortedKeys) byIndex[key]!];
  }
}
