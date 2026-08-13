import 'package:alrasmarket/generated/l10n.dart';
import 'package:flutter/widgets.dart';

final _arabicScript = RegExp(r'[\u0600-\u06FF]');

bool _hasArabicScript(String value) => _arabicScript.hasMatch(value);

/// Resolves a category label for the current app locale.
/// Prefers API [nameAr] when it is real Arabic; otherwise falls back to l10n
/// mapped from [nameEn] (avoids English leaking when NameAr was seeded as NameEn).
String localizedCategoryName(
  BuildContext context,
  String nameEn, {
  String? nameAr,
}) {
  final locale = Localizations.localeOf(context);
  final trimmedEn = nameEn.trim();
  final trimmedAr = nameAr?.trim() ?? '';
  final isArabicUi = locale.languageCode.toLowerCase() == 'ar';

  if (isArabicUi) {
    if (trimmedAr.isNotEmpty && _hasArabicScript(trimmedAr)) {
      return trimmedAr;
    }

    final fromL10n = _localizedFromEnglishKey(context, trimmedEn);
    if (fromL10n != null) return fromL10n;

    if (trimmedAr.isNotEmpty) return trimmedAr;
    return trimmedEn;
  }

  if (trimmedEn.isNotEmpty) return trimmedEn;
  return trimmedAr;
}

String? _localizedFromEnglishKey(BuildContext context, String nameEn) {
  final s = S.of(context);
  switch (nameEn.trim().toLowerCase()) {
    case 'herbs':
      return s.herbs;
    case 'pulses':
      return s.pulses;
    case 'spices':
      return s.spices;
    case 'nuts':
      return s.nuts;
    case 'coffee':
      return s.coffee;
    case 'cardamom':
      return s.cardamom;
    case 'cocoa':
      return s.cocoa;
    case 'acids':
      return s.acids;
    case 'milk':
      return s.milk;
    case 'dates':
      return s.dates;
    case 'sugar':
      return s.sugar;
    case 'rice':
      return s.rice;
    case 'sweets':
      return s.sweets;
    case 'canned':
    case 'canned foods':
      return s.canned;
    case 'flour':
      return s.flour;
    case 'beauty':
      return s.beauty;
    case 'poultry':
      return s.poultry;
    case 'frozen foods':
      return s.frozenFoods;
    default:
      return null;
  }
}
