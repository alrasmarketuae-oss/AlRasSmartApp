enum BookingPriceType {
  fob('FOB'),
  cnf('CNF'),
  cif('CIF');

  const BookingPriceType(this.apiValue);

  final String apiValue;

  static BookingPriceType? fromApiValue(String? value) {
    if (value == null) return null;
    final normalized = value.trim().toUpperCase();
    if (normalized == 'C&F' ||
        normalized == 'C AND F' ||
        normalized == 'CANDF') {
      return BookingPriceType.cnf;
    }
    for (final type in BookingPriceType.values) {
      if (type.apiValue == normalized) return type;
    }
    return null;
  }

  static BookingPriceType? fromId(int? id) {
    return switch (id) {
      1 => BookingPriceType.fob,
      2 => BookingPriceType.cnf,
      3 => BookingPriceType.cif,
      _ => null,
    };
  }
}
