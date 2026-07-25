import 'package:alrasmarket/generated/l10n.dart';
import 'package:flutter/widgets.dart';

/// Resolves a category label for the current app locale.
/// Prefers API [nameAr] when the UI is Arabic; otherwise [nameEn].
String localizedCategoryName(
  BuildContext context,
  String nameEn, {
  String? nameAr,
}) {
  final locale = Localizations.localeOf(context);
  final trimmedAr = nameAr?.trim() ?? '';
  if (locale.languageCode == 'ar' && trimmedAr.isNotEmpty) {
    return trimmedAr;
  }

  switch (nameEn.trim().toLowerCase()) {
    case 'herbs':
      return S.of(context).herbs;
    case 'pulses':
      return S.of(context).pulses;
    case 'spices':
      return S.of(context).spices;
    case 'nuts':
      return S.of(context).nuts;
    case 'coffee':
      return S.of(context).coffee;
    case 'cardamom':
      return S.of(context).cardamom;
    case 'cocoa':
      return S.of(context).cocoa;
    case 'acids':
      return S.of(context).acids;
    case 'milk':
      return S.of(context).milk;
    case 'dates':
      return S.of(context).dates;
    case 'sugar':
      return S.of(context).sugar;
    case 'rice':
      return S.of(context).rice;
    case 'sweets':
      return S.of(context).sweets;
    case 'canned':
      return S.of(context).canned;
    case 'flour':
      return S.of(context).flour;
    case 'beauty':
      return S.of(context).beauty;
    case 'poultry':
      return S.of(context).poultry;
    case 'frozen foods':
      return S.of(context).frozenFoods;
    default:
      return nameEn;
  }
}
