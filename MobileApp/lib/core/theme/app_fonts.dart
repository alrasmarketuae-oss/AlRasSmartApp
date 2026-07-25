import 'package:flutter/material.dart';

/// App typography: Cairo for Arabic, Inter for English.
class AppFonts {
  AppFonts._();

  static const String cairo = 'Cairo';
  static const String inter = 'Inter';

  static String familyFor(Locale locale) =>
      locale.languageCode == 'ar' ? cairo : inter;

  static String familyForLanguageCode(String languageCode) =>
      languageCode == 'ar' ? cairo : inter;

  static bool isArabic(Locale locale) => locale.languageCode == 'ar';
}
