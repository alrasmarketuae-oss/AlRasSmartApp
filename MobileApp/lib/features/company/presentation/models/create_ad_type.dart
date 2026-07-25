import 'package:alrasmarket/generated/l10n.dart';

enum CreateAdType {
  requests('Requests'),
  offers('Offers'),
  booking('Booking'),
  retail('Retail'),
  categories('Categories');

  const CreateAdType(this.label);

  final String label;

  static const List<String> labels = [
    'Categories',
    'Requests',
    'Offers',
    'Booking',
    'Retail',
  ];

  /// Non-UAE company accounts may only publish Booking ads.
  static List<String> labelsForCompany({required bool isUaePhone}) {
    if (isUaePhone) return labels;
    return const ['Booking'];
  }

  static CreateAdType? fromLabel(String? label) {
    if (label == null) return null;
    final normalized = label.trim().toLowerCase();
    if (normalized.isEmpty || normalized == '—' || normalized == '-') {
      return null;
    }
    for (final type in CreateAdType.values) {
      if (type.label.toLowerCase() == normalized) return type;
    }
    // Arabic API / UI labels (my-listings productTypeNameAr).
    switch (normalized) {
      case 'عروض':
      case 'عرض':
        return CreateAdType.offers;
      case 'طلبات':
      case 'طلب':
        return CreateAdType.requests;
      case 'حجز':
      case 'بوكينج':
        return CreateAdType.booking;
      case 'تجزئة':
        return CreateAdType.retail;
      case 'فئات':
      case 'اقسام':
      case 'أقسام':
        return CreateAdType.categories;
    }
    return null;
  }

  static String displayLabel(String? label) {
    final type = fromLabel(label);
    return type?.label ?? (label?.trim().isNotEmpty == true ? label!.trim() : '—');
  }

  /// Localized chip / badge text. Keep [label] for English API matching.
  static String localizedLabel(CreateAdType type, S s) {
    switch (type) {
      case CreateAdType.categories:
        return s.categories;
      case CreateAdType.requests:
        return s.requests;
      case CreateAdType.offers:
        return s.offers;
      case CreateAdType.booking:
        return s.booking;
      case CreateAdType.retail:
        return s.retail;
    }
  }

  static String localizedDisplayLabel(String? label, S s) {
    final type = fromLabel(label);
    if (type == null) {
      return label?.trim().isNotEmpty == true ? label!.trim() : '—';
    }
    return localizedLabel(type, s);
  }
}
