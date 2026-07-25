/// Display helpers for product / listing text.
extension StringDisplayFormat on String {
  /// Uppercases the first letter. No-op for empty strings; Arabic letters unchanged.
  String capitalizeFirst() {
    final value = trim();
    if (value.isEmpty) return value;
    return value[0].toUpperCase() + value.substring(1);
  }
}
