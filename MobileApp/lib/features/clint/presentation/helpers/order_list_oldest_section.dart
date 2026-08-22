import 'package:alrasmarket/core/utils/utc_date_time.dart';

/// Groups order lists newest-first and inserts an "Oldest" header before
/// entries older than [oldestThreshold].
class OrderListOldestSection {
  OrderListOldestSection._();

  static const Duration oldestThreshold = Duration(days: 14);

  static bool isOlderThanThreshold(String? createdAtRaw) {
    final utc = UtcDateTime.parseAsUtc(createdAtRaw);
    if (utc == null) return false;
    return DateTime.now().toUtc().difference(utc.toUtc()) >= oldestThreshold;
  }

  static int _compareNewestFirst(String? aRaw, String? bRaw) {
    final a = UtcDateTime.parseAsUtc(aRaw);
    final b = UtcDateTime.parseAsUtc(bRaw);
    if (a == null && b == null) return 0;
    if (a == null) return 1;
    if (b == null) return -1;
    return b.compareTo(a);
  }

  static List<T> sortedNewestFirst<T>({
    required List<T> items,
    required String Function(T item) createdAtOf,
  }) {
    final sorted = List<T>.from(items);
    sorted.sort(
      (a, b) => _compareNewestFirst(createdAtOf(a), createdAtOf(b)),
    );
    return sorted;
  }

  static List<OrderListSectionEntry<T>> buildEntries<T>({
    required List<T> items,
    required String Function(T item) createdAtOf,
    required String oldestSectionLabel,
  }) {
    final sorted = sortedNewestFirst(items: items, createdAtOf: createdAtOf);
    final entries = <OrderListSectionEntry<T>>[];
    var headerAdded = false;

    for (final item in sorted) {
      if (!headerAdded && isOlderThanThreshold(createdAtOf(item))) {
        entries.add(OrderListSectionEntry.header(oldestSectionLabel));
        headerAdded = true;
      }
      entries.add(OrderListSectionEntry.item(item));
    }

    return entries;
  }
}

class OrderListSectionEntry<T> {
  const OrderListSectionEntry.header(this.sectionLabel)
      : item = null,
        isHeader = true;

  const OrderListSectionEntry.item(this.item)
      : sectionLabel = null,
        isHeader = false;

  final bool isHeader;
  final String? sectionLabel;
  final T? item;
}
